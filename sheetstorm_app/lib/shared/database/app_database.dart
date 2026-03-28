import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

// ─── Tabellen ─────────────────────────────────────────────────────────────────

class SheetMusics extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get composer => text().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get localPath => text().nullable()();
  BoolColumn get isOfflineAvailable => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Voices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sheetId => integer().references(SheetMusics, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get instrument => text().nullable()();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();
}

class Annotations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get voiceId => integer().references(Voices, #id)();
  TextColumn get level => text()(); // 'private' | 'voice' | 'orchestra'
  RealColumn get xRelative => real()();
  RealColumn get yRelative => real()();
  RealColumn get page => real()();
  TextColumn get svgData => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ConfigEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get level => text()(); // 'band' | 'user' | 'device'
  TextColumn get key => text()();
  TextColumn get value => text()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
}

// ─── Datenbank ────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [SheetMusics, Voices, Annotations, ConfigEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Migrationen hier hinzufügen
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'sheetstorm.db'));
    return NativeDatabase.createInBackground(file);
  });
}
