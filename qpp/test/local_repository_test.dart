import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qpp/database.dart';
import 'package:qpp/local_repository.dart';

void main() {
  late AppDatabase db;
  late LocalRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LocalRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('LocalRepository - Reminders', () {
    test('createReminder inserts row with proper defaults', () async {
      final id = await repository.createReminder(
        message: 'Salbutamol dose',
        time: '08:00',
      );

      final results = await repository.getReminder(id);
      expect(results.length, 1);
      expect(results.first.id, id);
      expect(results.first.message, 'Salbutamol dose');
      expect(results.first.time, '08:00');
      expect(results.first.isComplete, false);
      expect(results.first.isSynced, false);
      expect(results.first.globalId, isNull);
    });

    test('getReminder returns empty list when localId does not exist', () async {
      final results = await repository.getReminder(999);
      expect(results, isEmpty);
    });

    test('getReminder without arguments returns all records', () async {
      await repository.createReminder(message: 'Item 1', time: '08:00');
      await repository.createReminder(message: 'Item 2', time: '09:00');

      final results = await repository.getReminder();
      expect(results.length, 2);
    });

    test('updateReminder updates single field and invalidates isSynced', () async {
      final id = await repository.createReminder(message: 'Old Message', time: '10:00');

      await (db.update(db.reminders)..where((tbl) => tbl.id.equals(id))).write(
        const RemindersCompanion(
          globalId: Value(50),
          isSynced: Value(true),
        ),
      );

      final success = await repository.updateReminder(id, message: 'New Message');
      expect(success, true);

      final updated = (await repository.getReminder(id)).first;
      expect(updated.message, 'New Message');
      expect(updated.time, '10:00');
      expect(updated.isSynced, false);
      expect(updated.globalId, 50);
    });

    test('updateReminder returns false when updating non-existent record', () async {
      final success = await repository.updateReminder(999, message: 'Does not exist');
      expect(success, false);
    });
  });

  group('LocalRepository - Games', () {
    test('createGameSession stores valid game session data', () async {
      final id = await repository.createGameSession(
        gameType: 'reaction_test',
        gameData: '{"score": 100}',
      );

      final games = await db.select(db.games).get();
      expect(games.length, 1);
      expect(games.first.id, id);
      expect(games.first.gameType, 'reaction_test');
      expect(games.first.gameData, '{"score": 100}');
      expect(games.first.isSynced, false);
      expect(games.first.globalId, isNull);
    });
  });
}