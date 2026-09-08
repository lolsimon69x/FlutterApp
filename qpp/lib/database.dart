import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// --- TABLE DEFINITIONS ---

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get globalId => integer().nullable().unique()();
  TextColumn get message => text()();
  TextColumn get time => text()();
  BoolColumn get isComplete => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class Games extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get globalId => integer().nullable().unique()();
  TextColumn get gameType => text()();
  TextColumn get gameData => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

// --- DATABASE INTERFACE ---

@DriftDatabase(tables: [Reminders, Games])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Testing constructor to allow in-memory SQLite execution
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'NER_Chetna');
  }
}