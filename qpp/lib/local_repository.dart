import 'package:drift/drift.dart';
import 'database.dart';

class LocalRepository {
  final AppDatabase db;

  LocalRepository(this.db);

  // ==========================================
  //               REMINDERS
  // ==========================================

  /// Creates a local reminder. Always starts as unsynced (isSynced = false).
  /// Returns the auto-incremented local primary key.
  Future<int> createReminder({
    required String message,
    required String time,
  }) async {
    return await db.into(db.reminders).insert(
      RemindersCompanion.insert(
        message: message,
        time: time,
        isSynced: const Value(false),
      ),
    );
  }

  /// Updates reminder fields by localId and resets isSynced to false.
  Future<bool> updateReminder(
    int localId, {
    String? message,
    String? time,
    bool? isComplete,
  }) async {
    final rowsAffected = await (db.update(db.reminders)
          ..where((tbl) => tbl.id.equals(localId)))
        .write(
      RemindersCompanion(
        message: message != null ? Value(message) : const Value.absent(),
        time: time != null ? Value(time) : const Value.absent(),
        isComplete: isComplete != null ? Value(isComplete) : const Value.absent(),
        isSynced: const Value(false),
      ),
    );
    return rowsAffected > 0;
  }

  /// Reads reminders.
  /// If [localId] is provided, returns a single-item list containing that record (or empty if not found).
  /// If [localId] is omitted or null, returns all reminders.
  Future<List<Reminder>> getReminder([int? localId]) async {
    if (localId != null) {
      final reminder = await (db.select(db.reminders)
            ..where((tbl) => tbl.id.equals(localId)))
          .getSingleOrNull();
      return reminder != null ? [reminder] : [];
    }
    return await db.select(db.reminders).get();
  }

  // ==========================================
  //               GAME SESSIONS
  // ==========================================

  /// Creates an immutable local game session log (isSynced = false).
  /// Returns the auto-incremented local primary key.
  Future<int> createGameSession({
    required String gameType,
    required String gameData,
  }) async {
    return await db.into(db.games).insert(
      GamesCompanion.insert(
        gameType: gameType,
        gameData: gameData,
        isSynced: const Value(false),
      ),
    );
  }

  

}