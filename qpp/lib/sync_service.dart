import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'database.dart';

class SyncService {
  final AppDatabase db;
  final String backendBaseUrl;

  SyncService({
    required this.db,
    required this.backendBaseUrl,
  });

  // ==========================================
  //            REMINDERS SYNC (BATCH)
  // ==========================================

  /// Pushes un-synced reminders upstream using PooledUserReminderRequest schema.
  Future<void> syncReminders(String authToken) async {
    final unsynced = await (db.select(db.reminders)
          ..where((tbl) => tbl.isSynced.equals(false) & tbl.globalId.isNull()))
        .get();

    if (unsynced.isEmpty) return;

    final payload = {
      'reminder': unsynced
          .map((r) => {
                'message': r.message,
                'time': r.time,
                'is_completed': r.isComplete,
              })
          .toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/myaccount/reminders'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> resBody = jsonDecode(response.body);

        if (resBody['success'] == true && resBody['data'] != null) {
          final List<dynamic> serverIds = resBody['data']['reminder_ids'] ?? [];

          await db.transaction(() async {
            for (int i = 0; i < unsynced.length && i < serverIds.length; i++) {
              final localReminder = unsynced[i];
              final int assignedGlobalId = serverIds[i];

              await (db.update(db.reminders)
                    ..where((tbl) => tbl.id.equals(localReminder.id)))
                  .write(
                RemindersCompanion(
                  globalId: Value(assignedGlobalId),
                  isSynced: const Value(true),
                ),
              );
            }
          });
        }
      }
    } on SocketException {
      return;
    } on http.ClientException {
      return;
    } catch (e) {
      return;
    }

    // ==============================================================
    // NOTE: Upstream updates for existing records are disabled for now.
    // When the backend implements an update route, uncomment below:
    // ==============================================================
    /*
    final updatedLocally = await (db.select(db.reminders)
          ..where((tbl) => tbl.isSynced.equals(false) & tbl.globalId.isNotNull()))
        .get();

    for (final reminder in updatedLocally) {
      try {
        final response = await http.put(
          Uri.parse('$backendBaseUrl/myaccount/reminders/${reminder.globalId}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'message': reminder.message,
            'time': reminder.time,
            'is_completed': reminder.isComplete,
          }),
        );

        if (response.statusCode == 200) {
          await (db.update(db.reminders)
                ..where((tbl) => tbl.id.equals(reminder.id)))
              .write(
            const RemindersCompanion(isSynced: Value(true)),
          );
        }
      } catch (e) {
        break;
      }
    }
    */
  }

  // ==========================================
  //           GAME SESSIONS SYNC (BATCH)
  // ==========================================

  /// Pushes un-synced game sessions upstream using PooledUserGameSessionRequest schema.
  Future<void> syncGameSessions(String authToken) async {
    final unsynced = await (db.select(db.games)
          ..where((tbl) => tbl.isSynced.equals(false) & tbl.globalId.isNull()))
        .get();

    if (unsynced.isEmpty) return;

    final payload = {
      'game_session': unsynced
          .map((g) => {
                'game_type': g.gameType,
                'game_data': g.gameData,
              })
          .toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/myaccount/games'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> resBody = jsonDecode(response.body);

        if (resBody['success'] == true && resBody['data'] != null) {
          final List<dynamic> serverIds = resBody['data']['game_session_ids'] ?? [];

          await db.transaction(() async {
            for (int i = 0; i < unsynced.length && i < serverIds.length; i++) {
              final localGame = unsynced[i];
              final int assignedGlobalId = serverIds[i];

              await (db.update(db.games)
                    ..where((tbl) => tbl.id.equals(localGame.id)))
                  .write(
                GamesCompanion(
                  globalId: Value(assignedGlobalId),
                  isSynced: const Value(true),
                ),
              );
            }
          });
        }
      }
    } on SocketException {
      return;
    } on http.ClientException {
      return;
    } catch (e) {
      return;
    }
  }

  // ==========================================
  //             DOWNSTREAM SYNC
  // ==========================================

  /// Fetches reminders from FastAPI and reconciles them into the local database.
  Future<void> fetchRemoteReminders(String authToken) async {
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/myaccount/reminders'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        if (body['success'] == true && body['data'] is List) {
          final List<dynamic> remoteList = body['data'];

          for (final item in remoteList) {
            final int remoteGlobalId = item['id'];
            final String message = item['message'];
            final String time = item['time'];
            final bool isCompleted = item['is_completed'] ?? false;

            final existing = await (db.select(db.reminders)
                  ..where((tbl) => tbl.globalId.equals(remoteGlobalId)))
                .getSingleOrNull();

            if (existing == null) {
              await db.into(db.reminders).insert(
                RemindersCompanion.insert(
                  globalId: Value(remoteGlobalId),
                  message: message,
                  time: time,
                  isComplete: Value(isCompleted),
                  isSynced: const Value(true),
                ),
              );
            } else if (existing.isSynced) {
              await (db.update(db.reminders)
                    ..where((tbl) => tbl.id.equals(existing.id)))
                  .write(
                RemindersCompanion(
                  message: Value(message),
                  time: Value(time),
                  isComplete: Value(isCompleted),
                  isSynced: const Value(true),
                ),
              );
            }
          }
        }
      }
    } on SocketException {
      return;
    } on http.ClientException {
      return;
    } catch (e) {
      return;
    }
  }
}