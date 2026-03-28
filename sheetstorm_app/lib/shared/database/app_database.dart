import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

// ─── Tabellen ─────────────────────────────────────────────────────────────────

class Noten extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titel => text().withLength(min: 1, max: 255)();
  TextColumn get komponist => text().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get lokalerPfad => text().nullable()();
  BoolColumn get istOfflineVerfuegbar => boolean().withDefault(const Constant(false))();
  DateTimeColumn get erstelltAm => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get aktualisiertAm => dateTime().withDefault(currentDateAndTime)();
}

class Stimmen extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get notenId => integer().references(Noten, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get instrument => text().nullable()();
  IntColumn get seitenAnzahl => integer().withDefault(const Constant(0))();
}

class Annotationen extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get stimmeId => integer().references(Stimmen, #id)();
  TextColumn get ebene => text()(); // 'privat' | 'stimme' | 'orchester'
  RealColumn get xRelativ => real()();
  RealColumn get yRelativ => real()();
  RealColumn get seite => real()();
  TextColumn get svgDaten => text()();
  DateTimeColumn get erstelltAm => dateTime().withDefault(currentDateAndTime)();
}

class KonfigurationEintraege extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ebene => text()(); // 'kapelle' | 'nutzer' | 'gerat'
  TextColumn get schluessel => text()();
  TextColumn get wert => text()();
  BoolColumn get istGesperrt => boolean().withDefault(const Constant(false))();
}

// ─── Datenbank ────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Noten, Stimmen, Annotationen, KonfigurationEintraege])
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
