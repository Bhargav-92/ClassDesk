import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:uuid/uuid.dart';

import 'local_schema.dart';

part 'local_sync_store.dart';

typedef LocalRow = Map<String, Object?>;

/// Keep one open instance for the app. Platform factories are injectable for tests.
class LocalDatabase {
  LocalDatabase._(this._db);

  final Database _db;

  static const filename = 'class_desk.sqlite';
  static const schemaVersion = 3;

  LocalSyncStore get sync => LocalSyncStore._(_db);

  static Future<LocalDatabase> open({
    DatabaseFactory? factory,
    String path = filename,
  }) async {
    final db = await (factory ?? (kIsWeb ? databaseFactoryFfiWeb : databaseFactory))
        .openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: schemaVersion,
            onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
            onUpgrade: (db, oldVersion, _) async {
              if (oldVersion < 2) await db.execute(LocalSyncStore.createSql);
              if (oldVersion < 3) {
                await db.execute(
                  'ALTER TABLE homework ADD COLUMN student_id TEXT REFERENCES students(id)',
                );
              }
            },
            onCreate: (db, _) async {
              final batch = db.batch();
              batch.execute(LocalSyncStore.createSql);
              for (final table in LocalTable.values) {
                batch.execute(table.createSql);
                batch.execute(
                  'CREATE INDEX ${table.sqlName}_sync ON ${table.sqlName}(sync_status, updated_at)',
                );
              }
              for (final index in localIndexes) {
                batch.execute(index);
              }
              await batch.commit(noResult: true);
            },
          ),
        );
    return LocalDatabase._(db);
  }

  LocalRepository repository(LocalTable table) => LocalRepository._(_db, table);

  Future<Set<String>> homeworkRecipientsSent(String homeworkId) async {
    final logs = await repository(
      LocalTable.messageLog,
    ).list(matching: {'homework_id': homeworkId, 'type': 'homework'});
    return logs.map((row) => row['student_id']! as String).toSet();
  }

  Future<void> confirmWhatsAppSent({
    required String studentId,
    String? homeworkId,
  }) => _db.transaction((tx) async {
    final student = await LocalRepository._(
      tx,
      LocalTable.students,
    ).find(studentId);
    if (student == null) {
      throw const FormatException('The student is no longer active.');
    }
    final logs = LocalRepository._(tx, LocalTable.messageLog);
    if (homeworkId != null) {
      final homework = await LocalRepository._(
        tx,
        LocalTable.homework,
      ).find(homeworkId);
      if (homework == null ||
          (homework['student_id'] != null
              ? homework['student_id'] != studentId
              : homework['batch'] != student['batch'])) {
        throw const FormatException(
          'This student is no longer in the homework batch.',
        );
      }
      final sent = await logs.list(
        matching: {
          'student_id': studentId,
          'homework_id': homeworkId,
          'type': 'homework',
        },
      );
      if (sent.isNotEmpty) return;
    }
    await logs.create({
      'student_id': studentId,
      'homework_id': homeworkId,
      'type': homeworkId == null ? 'fee_reminder' : 'homework',
      'sent_at': DateTime.now().microsecondsSinceEpoch,
    });
  });
  Future<void> close() => _db.close();

  Future<void> saveFee({
    String? id,
    required String studentId,
    required String month,
    required int amount,
    required String dueDate,
  }) => _db.transaction((tx) async {
    final students = LocalRepository._(tx, LocalTable.students);
    if (await students.find(studentId) == null) {
      throw const FormatException('This student is no longer active.');
    }
    final fees = LocalRepository._(tx, LocalTable.feeRecords);
    final values = {
      'student_id': studentId,
      'month': month,
      'amount_due_paise': amount,
      'due_date': dueDate,
    };
    if (id == null) {
      await fees.create(values);
      return;
    }
    final original = await fees.find(id);
    if (original == null || original['student_id'] != studentId) {
      throw const FormatException('This fee is no longer available.');
    }
    final paid = await _paid(tx, id);
    if (paid > amount) {
      throw const FormatException(
        'The fee must cover the payments already recorded.',
      );
    }
    await fees.update(id, values);
    await _updatePromise(tx, id, amount - paid);
  });

  Future<void> savePayment({
    String? id,
    required String feeId,
    required int amount,
    required String paidOn,
    required String mode,
    required String note,
    String? promisedDate,
  }) => _db.transaction((tx) async {
    final fee = await _activeFee(tx, feeId);
    final due = fee['amount_due_paise']! as int;
    final payments = LocalRepository._(tx, LocalTable.payments);
    final prior = id == null ? null : await payments.find(id);
    if (id != null &&
        (prior == null ||
            prior['fee_record_id'] != feeId ||
            prior['mode'] == 'razorpay')) {
      throw const FormatException('This payment can no longer be edited.');
    }
    final paid = await _paid(tx, feeId, except: id);
    if (amount <= 0 || amount > due - paid || !['upi', 'cash'].contains(mode)) {
      throw const FormatException(
        'Check the amount and payment method against the current balance.',
      );
    }
    final values = {
      'fee_record_id': feeId,
      'amount_paise': amount,
      'paid_on': paidOn,
      'mode': mode,
      'note': note,
    };
    if (id == null) {
      await payments.create(values);
    } else {
      await payments.update(id, values);
    }
    await _updatePromise(
      tx,
      feeId,
      due - paid - amount,
      promisedDate: promisedDate,
    );
  });

  Future<void> setPaymentRemoved(String id, {required bool removed}) =>
      _db.transaction((tx) async {
        final rows = await tx.query(
          'payments',
          where: 'id = ?',
          whereArgs: [id],
        );
        final payment = rows.firstOrNull;
        if (payment == null || payment['mode'] == 'razorpay') {
          throw const FormatException('This payment can no longer be changed.');
        }
        final feeId = payment['fee_record_id']! as String;
        final fee = await _activeFee(tx, feeId);
        final due = fee['amount_due_paise']! as int;
        final paid = await _paid(tx, feeId, except: id);
        final newTotal = paid + (removed ? 0 : payment['amount_paise']! as int);
        if (newTotal > due) {
          throw const FormatException(
            'Restoring this payment would exceed the fee balance.',
          );
        }
        final payments = LocalRepository._(tx, LocalTable.payments);
        if (removed) {
          await payments.softDelete(id);
        } else {
          await payments.restore(id);
        }
        await _updatePromise(tx, feeId, due - newTotal);
      });

  Future<LocalRow> _activeFee(Transaction tx, String id) async {
    final fee = await LocalRepository._(tx, LocalTable.feeRecords).find(id);
    if (fee == null) {
      throw const FormatException('This fee is no longer available.');
    }
    return fee;
  }

  Future<int> _paid(Transaction tx, String feeId, {String? except}) async {
    final rows = await tx.rawQuery(
      'SELECT COALESCE(SUM(amount_paise), 0) AS paid FROM payments '
      'WHERE fee_record_id = ? AND is_deleted = 0 AND (? IS NULL OR id != ?)',
      [feeId, except, except],
    );
    return rows.single['paid']! as int;
  }

  Future<void> _updatePromise(
    Transaction tx,
    String feeId,
    int balance, {
    String? promisedDate,
  }) async {
    final promises = LocalRepository._(tx, LocalTable.promises);
    final active = await promises.list(matching: {'fee_record_id': feeId});
    final current = active.firstOrNull;
    if (balance == 0) {
      for (final promise in active) {
        await promises.softDelete(promise['id']! as String);
      }
      return;
    }
    if (current == null) {
      if (promisedDate != null) {
        await promises.create({
          'fee_record_id': feeId,
          'remaining_amount_paise': balance,
          'promised_date': promisedDate,
        });
      }
      return;
    }
    final changes = <String, Object?>{'remaining_amount_paise': balance};
    if (promisedDate != null && promisedDate != current['promised_date']) {
      changes.addAll({'promised_date': promisedDate, 'reminder_sent': 0});
    }
    await promises.update(current['id']! as String, changes);
    for (final duplicate in active.skip(1)) {
      await promises.softDelete(duplicate['id']! as String);
    }
  }

  /// Explicit opt-in. Inserts the entire demo dataset once into an empty roster.
  Future<bool> seedDemoData() => _db.transaction((tx) async {
    final existing = await tx.query('students', columns: ['id'], limit: 1);
    if (existing.isNotEmpty) return false;

    final students = LocalRepository._(tx, LocalTable.students);
    final fees = LocalRepository._(tx, LocalTable.feeRecords);
    final plans = LocalRepository._(tx, LocalTable.feePlans);
    final payments = LocalRepository._(tx, LocalTable.payments);
    final promises = LocalRepository._(tx, LocalTable.promises);
    final now = DateTime.now();
    final month = _date(now).substring(0, 7);
    final today = _date(now);

    for (final (name, parent, phone, amount, received) in [
      ('Ananya Rao', 'Kavita Rao', '+919000000001', 250000, 250000),
      ('Rahul Mehta', 'Nisha Mehta', '+919000000002', 300000, 150000),
      ('Ishaan Patel', 'Rina Patel', '+919000000003', 220000, 0),
    ]) {
      final student = await students.create({
        'name': name,
        'batch': 'Class 8 Maths',
        'parent_name': parent,
        'parent_whatsapp': phone,
        'monthly_fee_paise': amount,
        'joining_date': today,
      });
      await plans.create({
        'student_id': student,
        'amount_paise': amount,
        'due_day': 10,
      });
      final fee = await fees.create({
        'student_id': student,
        'month': month,
        'amount_due_paise': amount,
        'due_date': '$month-10',
      });
      if (received > 0) {
        await payments.create({
          'fee_record_id': fee,
          'amount_paise': received,
          'paid_on': today,
          'mode': 'cash',
        });
      }
      if (received > 0 && received < amount) {
        await promises.create({
          'fee_record_id': fee,
          'remaining_amount_paise': amount - received,
          'promised_date': _date(now.add(const Duration(days: 7))),
        });
      }
    }

    await LocalRepository._(tx, LocalTable.homework).create({
      'batch': 'Class 8 Maths',
      'subject': 'Maths',
      'title': 'Fractions practice',
      'description': 'Solve questions 1–10 from page 42.',
      'due_date': _date(now.add(const Duration(days: 2))),
    });
    return true;
  });

  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// All mutations preserve IDs and creation times and queue the row for sync.
class LocalRepository {
  LocalRepository._(this._db, this.table);

  final DatabaseExecutor _db;
  final LocalTable table;

  Future<String> create(LocalRow values) async {
    _validateFields(values);
    final id = const Uuid().v4();
    final now = DateTime.now().microsecondsSinceEpoch;
    await _db.insert(table.sqlName, {
      ...values,
      'id': id,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<LocalRow?> find(String id) async {
    final rows = await _db.query(
      table.sqlName,
      where: 'id = ? AND (${table.visibleWhere})',
      whereArgs: [id],
      limit: 1,
    );
    return rows.firstOrNull;
  }

  Future<List<LocalRow>> list({Map<String, Object> matching = const {}}) {
    _validateFields(matching);
    final filters = [
      table.visibleWhere,
      for (final column in matching.keys) '$column = ?',
    ];
    return _db.query(
      table.sqlName,
      where: filters.join(' AND '),
      whereArgs: matching.values.toList(),
      orderBy: 'created_at DESC, id',
    );
  }

  Future<bool> update(String id, LocalRow changes) async {
    _validateFields(changes);
    if (changes.isEmpty) return false;
    return _change(id, changes, where: table.visibleWhere);
  }

  Future<bool> softDelete(String id) =>
      _change(id, {'is_deleted': 1}, where: 'is_deleted = 0');

  Future<bool> restore(String id) =>
      _change(id, {'is_deleted': 0}, where: 'is_deleted = 1');

  Future<bool> _change(
    String id,
    LocalRow changes, {
    required String where,
  }) async {
    final assignments = changes.keys.map((column) => '$column = ?').join(', ');
    final count = await _db.rawUpdate(
      "UPDATE ${table.sqlName} SET $assignments, sync_status = 'pending', "
      'updated_at = max(updated_at + 1, ?) WHERE id = ? AND ($where)',
      [...changes.values, DateTime.now().microsecondsSinceEpoch, id],
    );
    return count != 0;
  }

  void _validateFields(Map<String, Object?> values) {
    for (final column in values.keys) {
      if (!table.columns.containsKey(column)) {
        throw ArgumentError.value(
          column,
          'column',
          'Unknown or managed column',
        );
      }
    }
  }
}
