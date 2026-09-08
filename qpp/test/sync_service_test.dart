import 'dart:convert';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:qpp/database.dart';
import 'package:qpp/sync_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncService - syncReminders', () {
    test('pushes unsynced reminders and reconciles assigned global IDs', () async {
      await db.into(db.reminders).insert(
        RemindersCompanion.insert(
          message: 'Take Inhaler',
          time: '08:00',
          isSynced: const Value(false),
        ),
      );

      final rawBefore = await db.select(db.reminders).get();
      expect(rawBefore.first.isSynced, false);
      expect(rawBefore.first.globalId, isNull);

      final client = MockClient((request) async {
        expect(request.url.path, '/myaccount/reminders');
        expect(request.method, 'POST');
        final Map<String, dynamic> body = jsonDecode(request.body);
        expect(body.containsKey('reminder'), true);

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'reminder_ids': [42]
            },
            'message': 'Reminders added successfully',
            'error': null,
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final unsynced = await (db.select(db.reminders)
            ..where((tbl) => tbl.isSynced.equals(false) & tbl.globalId.isNull()))
          .get();

      final payload = {
        'reminder': unsynced
            .map((r) => {'message': r.message, 'time': r.time, 'is_completed': r.isComplete})
            .toList(),
      };

      final response = await client.post(
        Uri.parse('http://localhost:8000/myaccount/reminders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final resBody = jsonDecode(response.body);
      final List<dynamic> serverIds = resBody['data']['reminder_ids'];

      await (db.update(db.reminders)..where((tbl) => tbl.id.equals(unsynced[0].id))).write(
        RemindersCompanion(
          globalId: Value(serverIds[0] as int),
          isSynced: const Value(true),
        ),
      );

      final rawAfter = await db.select(db.reminders).get();
      expect(rawAfter.first.isSynced, true);
      expect(rawAfter.first.globalId, 42);
    });
  });

  group('SyncService - fetchRemoteReminders', () {
    test('inserts new remote records and updates unmodified local records', () async {
      await db.into(db.reminders).insert(
        RemindersCompanion.insert(
          globalId: const Value(10),
          message: 'Old Message',
          time: '07:00',
          isSynced: const Value(true),
        ),
      );

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 10,
                'user_id': 8,
                'message': 'Updated Message',
                'time': '07:30',
                'is_completed': true,
                'last_modified': '2026-09-08T00:00:00',
              },
              {
                'id': 11,
                'user_id': 8,
                'message': 'Brand New Reminder',
                'time': '12:00',
                'is_completed': false,
                'last_modified': '2026-09-08T00:00:00',
              },
            ],
            'message': 'Retrieved',
            'error': null,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final response = await client.get(Uri.parse('http://localhost:8000/myaccount/reminders'));
      final resBody = jsonDecode(response.body);
      final List<dynamic> remoteList = resBody['data'];

      for (final item in remoteList) {
        final int remoteGlobalId = item['id'];
        final existing = await (db.select(db.reminders)
              ..where((tbl) => tbl.globalId.equals(remoteGlobalId)))
            .getSingleOrNull();

        if (existing == null) {
          await db.into(db.reminders).insert(
            RemindersCompanion.insert(
              globalId: Value(remoteGlobalId),
              message: item['message'],
              time: item['time'],
              isComplete: Value(item['is_completed']),
              isSynced: const Value(true),
            ),
          );
        } else if (existing.isSynced) {
          await (db.update(db.reminders)..where((tbl) => tbl.id.equals(existing.id))).write(
            RemindersCompanion(
              message: Value(item['message']),
              time: Value(item['time']),
              isComplete: Value(item['is_completed']),
              isSynced: const Value(true),
            ),
          );
        }
      }

      final rows = await db.select(db.reminders).get();
      expect(rows.length, 2);

      final updatedRow = rows.firstWhere((r) => r.globalId == 10);
      expect(updatedRow.message, 'Updated Message');
      expect(updatedRow.time, '07:30');
      expect(updatedRow.isComplete, true);

      final newRow = rows.firstWhere((r) => r.globalId == 11);
      expect(newRow.message, 'Brand New Reminder');
      expect(newRow.isSynced, true);
    });
  });
}