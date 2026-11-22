@TestOn('vm')
library;

import 'dart:io';

import 'package:class_desk/core/database/local_database.dart';
import 'package:class_desk/core/database/local_schema.dart';
import 'package:class_desk/features/sync/manual_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late LocalDatabase database;

  Future<LocalDatabase> open() => LocalDatabase.open(
    factory: databaseFactoryFfi,
    path: '${directory.path}/class_desk.sqlite',
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('class_desk_test_');
    database = await open();
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('demo seeding is opt-in, idempotent and persists across reopen', () async {
    expect(await database.repository(LocalTable.students).list(), isEmpty);
    expect(await database.seedDemoData(), isTrue);
    expect(await database.seedDemoData(), isFalse);

    await database.close();
    database = await open();
    final students = await database.repository(LocalTable.students).list();
    expect(students, hasLength(3));
    expect(
      students.map((row) => row['id']),
      everyElement(
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      ),
    );
    expect(students.map((row) => row['sync_status']), everyElement('pending'));
    expect(await database.repository(LocalTable.feePlans).list(), hasLength(3));
    expect(
      await database.repository(LocalTable.feeRecords).list(),
      hasLength(3),
    );
    expect(await database.repository(LocalTable.payments).list(), hasLength(2));
    expect(await database.repository(LocalTable.promises).list(), hasLength(1));
    expect(await database.repository(LocalTable.homework).list(), hasLength(1));
  });

  test('soft delete and undo hide and restore connected fee records', () async {
    await database.seedDemoData();
    final students = database.repository(LocalTable.students);
    final fees = database.repository(LocalTable.feeRecords);
    final payments = database.repository(LocalTable.payments);
    final original = (await students.list(
      matching: {'name': 'Rahul Mehta'},
    )).single;
    final id = original['id']! as String;
    final feeId =
        (await fees.list(matching: {'student_id': id})).single['id']! as String;
    expect(await students.softDelete(id), isTrue);
    expect(await students.find(id), isNull);
    expect(await fees.find(feeId), isNull);
    expect(await payments.list(matching: {'fee_record_id': feeId}), isEmpty);
    expect(await students.restore(id), isTrue);
    expect(await students.update(id, {'notes': 'Weekend lessons'}), isTrue);
    final restored = (await students.find(id))!;
    expect(restored['created_at'], original['created_at']);
    expect(restored['updated_at'], greaterThan(original['updated_at']! as int));
    expect(restored['notes'], 'Weekend lessons');
    expect(restored['sync_status'], 'pending');
    expect(
      await payments.list(matching: {'fee_record_id': feeId}),
      hasLength(1),
    );
  });

  test(
    'foreign keys and unique active fees prevent inconsistent records',
    () async {
      await database.seedDemoData();
      final fees = database.repository(LocalTable.feeRecords);
      final sample = (await fees.list()).first;
      final values = {
        for (final column in LocalTable.feeRecords.columns.keys)
          column: sample[column],
      };
      await expectLater(fees.create(values), throwsA(isA<DatabaseException>()));
      await expectLater(
        fees.create({...values, 'student_id': 'missing'}),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        fees.update(sample['id']! as String, {'id': 'changed'}),
        throwsArgumentError,
      );
    },
  );

  test(
    'partial payments update promises and reject overpayment atomically',
    () async {
      await database.seedDemoData();
      final students = database.repository(LocalTable.students);
      final student = (await students.list(
        matching: {'name': 'Ishaan Patel'},
      )).single;
      final fees = database.repository(LocalTable.feeRecords);
      final fee = (await fees.list(
        matching: {'student_id': student['id']!},
      )).single;
      final feeId = fee['id']! as String;
      final payments = database.repository(LocalTable.payments);
      final promises = database.repository(LocalTable.promises);

      Future<void> record(int amount, {String? promisedDate}) =>
          database.savePayment(
            feeId: feeId,
            amount: amount,
            paidOn: '2026-11-22',
            mode: 'upi',
            note: '',
            promisedDate: promisedDate,
          );

      await record(100000, promisedDate: '2026-11-30');
      var promise = (await promises.list(
        matching: {'fee_record_id': feeId},
      )).single;
      expect(promise['remaining_amount_paise'], 120000);
      await expectLater(record(120001), throwsFormatException);
      final payment = (await payments.list(
        matching: {'fee_record_id': feeId},
      )).single;
      await database.setPaymentRemoved(payment['id']! as String, removed: true);
      promise = (await promises.list(
        matching: {'fee_record_id': feeId},
      )).single;
      expect(promise['remaining_amount_paise'], 220000);
      await database.setPaymentRemoved(
        payment['id']! as String,
        removed: false,
      );
      await record(120000);
      expect(await promises.list(matching: {'fee_record_id': feeId}), isEmpty);
      expect(
        await payments.list(matching: {'fee_record_id': feeId}),
        hasLength(2),
      );
    },
  );

  test(
    'homework confirmations persist once per student and assignment',
    () async {
      await database.seedDemoData();
      final student =
          (await database.repository(LocalTable.students).list()).first;
      final homework =
          (await database.repository(LocalTable.homework).list()).single;
      final studentId = student['id']! as String;
      final homeworkId = homework['id']! as String;

      expect(await database.homeworkRecipientsSent(homeworkId), isEmpty);
      await database.confirmWhatsAppSent(
        studentId: studentId,
        homeworkId: homeworkId,
      );
      await database.confirmWhatsAppSent(
        studentId: studentId,
        homeworkId: homeworkId,
      );
      await database.confirmWhatsAppSent(studentId: studentId);
      await database.close();
      database = await open();

      expect(await database.homeworkRecipientsSent(homeworkId), {studentId});
      final logs = await database.repository(LocalTable.messageLog).list();
      expect(
        logs.map((row) => row['type']),
        unorderedEquals(['fee_reminder', 'homework']),
      );
    },
  );

  test(
    'sync retries failed changes and applies newer server tombstones',
    () async {
      await database.seedDemoData();
      final store = database.sync;
      final before = await store.pendingCount();
      const endpoint = 'https://sync.example.test';
      final transport = _TestSyncTransport();
      transport.upload = (_) async =>
          throw const FormatException('temporary outage');
      final sync = ManualSync(store, transport);
      await expectLater(sync.run(endpoint, (_) {}), throwsFormatException);
      expect(await store.pendingCount(), before);
      expect((await store.pendingRows()).first.row['sync_status'], 'failed');
      expect((await store.checkpoint(endpoint)).cursor, '0');

      final student = (await store.pendingRows()).first;
      transport.upload = (rows) async => rows;
      transport.download = (_, _) async => SyncPage(
        [
          SyncRow(student.table, {
            ...student.row,
            'updated_at': student.updatedAt + 1,
            'is_deleted': 1,
          }),
        ],
        '1',
        '1',
        false,
      );
      final result = await sync.run(endpoint, (_) {});
      expect(result.cursor, '1');
      expect(result.lastSuccess, isNotNull);
      expect(await store.pendingCount(), 0);
      expect(
        await database.repository(LocalTable.students).find(student.id),
        isNull,
      );
    },
  );

  test(
    'sync keeps a local edit made while its older version is being uploaded',
    () async {
      await database.seedDemoData();
      final store = database.sync;
      final original = (await store.pendingRows()).first;
      final transport = _TestSyncTransport()
        ..upload = (rows) async {
          await database.repository(LocalTable.students).update(original.id, {
            'notes': 'New offline edit',
          });
          return rows;
        }
        ..download = (_, _) async => SyncPage([original], '1', '1', false);
      final sync = ManualSync(store, transport);
      await sync.run('https://sync.example.test', (_) {});
      final pending = (await store.pendingRows()).single;
      expect(pending.id, original.id);
      expect(pending.row['notes'], 'New offline edit');
      expect(pending.updatedAt, greaterThan(original.updatedAt));
    },
  );

  test(
    'schema version two adds sync metadata without losing version one data',
    () async {
      final legacyPath = '${directory.path}/legacy.sqlite';
      final legacy = await databaseFactoryFfi.openDatabase(
        legacyPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            for (final table in LocalTable.values) {
              await db.execute(
                table == LocalTable.homework
                    ? table.createSql.replaceFirst(
                        'student_id TEXT REFERENCES students(id), ',
                        '',
                      )
                    : table.createSql,
              );
            }
          },
        ),
      );
      await legacy.insert('students', {
        'id': '5f05ec10-c375-4335-a352-782b540a0090',
        'name': 'Legacy Student',
        'batch': 'Class 8',
        'parent_name': 'Legacy Parent',
        'parent_whatsapp': '+919000000000',
        'monthly_fee_paise': 100000,
        'joining_date': '2026-11-22',
        'created_at': 1,
        'updated_at': 1,
      });
      await legacy.close();

      final upgraded = await LocalDatabase.open(
        factory: databaseFactoryFfi,
        path: legacyPath,
      );
      try {
        expect(await upgraded.sync.pendingCount(), 1);
        expect(
          (await upgraded.repository(LocalTable.students).list())
              .single['name'],
          'Legacy Student',
        );
      } finally {
        await upgraded.close();
      }
    },
  );

  test(
    'an individual homework assignment rejects other students in the batch',
    () async {
      await database.seedDemoData();
      final roster = await database.repository(LocalTable.students).list();
      final student = roster[0]['id']! as String;
      final other = roster[1]['id']! as String;
      final assignments = database.repository(LocalTable.homework);
      final sample = (await assignments.list()).single;
      final id = await assignments.create({
        for (final column in LocalTable.homework.columns.keys)
          column: sample[column],
        'student_id': student,
      });
      await expectLater(
        database.confirmWhatsAppSent(studentId: other, homeworkId: id),
        throwsFormatException,
      );
      await database.confirmWhatsAppSent(studentId: student, homeworkId: id);
      expect(await database.homeworkRecipientsSent(id), {student});
    },
  );
}

class _TestSyncTransport implements SyncTransport {
  @override
  Future<void> verify() async {}
  late Future<List<SyncRow>> Function(List<SyncRow>) upload;
  late Future<SyncPage> Function(String, String?) download;

  @override
  Future<List<SyncRow>> push(List<SyncRow> rows) => upload(rows);

  @override
  Future<SyncPage> pull(String cursor, String? through) =>
      download(cursor, through);
}
