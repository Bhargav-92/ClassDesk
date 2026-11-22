part of 'local_database.dart';

class SyncRow {
  SyncRow(this.table, this.row);

  factory SyncRow.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['row'] is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response from the sync server.');
    }
    final table = LocalTable.values
        .where((table) => table.sqlName == value['table'])
        .firstOrNull;
    final row = value['row'] as Map<String, dynamic>;
    if (table == null ||
        row['id'] is! String ||
        row['created_at'] is! int ||
        row['updated_at'] is! int ||
        row['is_deleted'] is! bool ||
        !table.columns.keys.every(
          (key) =>
              row.containsKey(key) ||
              (table == LocalTable.homework && key == 'student_id'),
        )) {
      throw const FormatException('Unexpected row from the sync server.');
    }
    return SyncRow(table, {
      'id': row['id'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
      'is_deleted': row['is_deleted'] == true ? 1 : 0,
      for (final column in table.columns.keys)
        column: column == 'reminder_sent'
            ? (row[column] == true ? 1 : 0)
            : row[column],
    });
  }

  final LocalTable table;
  final LocalRow row;

  String get id => row['id']! as String;
  int get updatedAt => row['updated_at']! as int;

  Map<String, Object?> toJson() => {
    'table': table.sqlName,
    'row': {
      ...row,
      'is_deleted': row['is_deleted'] == 1,
      if (table == LocalTable.promises)
        'reminder_sent': row['reminder_sent'] == 1,
    },
  };
}

class SyncCheckpoint {
  const SyncCheckpoint(this.cursor, this.lastSuccess);

  final String cursor;
  final DateTime? lastSuccess;
}

class LocalSyncStore {
  LocalSyncStore._(this._db);

  final Database _db;
  static const createSql = '''
    CREATE TABLE local_sync_state (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      endpoint TEXT NOT NULL,
      cursor TEXT NOT NULL DEFAULT '0',
      last_success INTEGER
    )
  ''';
  static const _outbox = "sync_status IN ('pending', 'failed')";

  Future<int> pendingCount() async {
    final rows = await _db.rawQuery(
      'SELECT ${LocalTable.values.map((table) => '(SELECT COUNT(*) FROM ${table.sqlName} WHERE $_outbox)').join(' + ')} AS total',
    );
    return rows.single['total']! as int;
  }

  Future<List<SyncRow>> pendingRows() => _db.transaction((tx) async {
    final rows = <SyncRow>[];
    for (final table in LocalTable.values) {
      final records = await tx.query(
        table.sqlName,
        where: _outbox,
        orderBy: 'is_deleted DESC, updated_at, id',
      );
      rows.addAll(records.map((row) => SyncRow(table, row)));
    }
    return rows;
  });

  Future<SyncCheckpoint> checkpoint(String endpoint) async {
    final rows = await _db.query('local_sync_state', where: 'id = 1');
    final current = rows.firstOrNull;
    if (current == null) return const SyncCheckpoint('0', null);
    if (current['endpoint'] != endpoint) {
      throw const FormatException(
        'This local database is already linked to another server. Restore its original URL.',
      );
    }
    final timestamp = current['last_success'] as int?;
    return SyncCheckpoint(
      current['cursor']! as String,
      timestamp == null ? null : DateTime.fromMicrosecondsSinceEpoch(timestamp),
    );
  }

  Future<void> bind(String endpoint) async {
    await _db.insert('local_sync_state', {
      'id': 1,
      'endpoint': endpoint,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await checkpoint(endpoint);
  }

  Future<void> markFailed(List<SyncRow> snapshot) =>
      _db.transaction((tx) async {
        final batch = tx.batch();
        for (final sent in snapshot) {
          batch.update(
            sent.table.sqlName,
            {'sync_status': 'failed'},
            where: 'id = ? AND updated_at = ? AND ($_outbox)',
            whereArgs: [sent.id, sent.updatedAt],
          );
        }
        await batch.commit(noResult: true);
      });

  Future<void> acknowledge(List<SyncRow> snapshot, List<SyncRow> canonical) =>
      _db.transaction((tx) async {
        for (var index = 0; index < snapshot.length; index++) {
          final sent = snapshot[index];
          final winner = canonical[index];
          final current = await _read(tx, sent);
          if (current?['updated_at'] == sent.updatedAt) {
            await _apply(tx, winner, current);
          }
        }
      });

  Future<void> applyPage(
    List<SyncRow> rows, {
    required String endpoint,
    required String cursor,
    required bool done,
  }) => _db.transaction((tx) async {
    for (final row in rows) {
      final current = await _read(tx, row);
      final currentTime = current?['updated_at'] as int?;
      if (currentTime == null ||
          currentTime < row.updatedAt ||
          (currentTime == row.updatedAt &&
              current?['sync_status'] != 'synced')) {
        await _apply(tx, row, current);
      }
    }
    final count = await tx.update(
      'local_sync_state',
      {
        'cursor': cursor,
        if (done) 'last_success': DateTime.now().microsecondsSinceEpoch,
      },
      where: 'id = 1 AND endpoint = ?',
      whereArgs: [endpoint],
    );
    if (count != 1) {
      throw const FormatException('The sync configuration changed. Try again.');
    }
  });

  Future<LocalRow?> _read(Transaction tx, SyncRow row) async {
    final rows = await tx.query(
      row.table.sqlName,
      where: 'id = ?',
      whereArgs: [row.id],
    );
    return rows.firstOrNull;
  }

  Future<void> _apply(Transaction tx, SyncRow row, LocalRow? current) async {
    final values = {...row.row, 'sync_status': 'synced'};
    if (current == null) {
      await tx.insert(row.table.sqlName, values);
    } else {
      await tx.update(
        row.table.sqlName,
        values,
        where: 'id = ?',
        whereArgs: [row.id],
      );
    }
  }
}
