// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

// ignore_for_file: type=lint
part of 'app_database.dart';

// Stub — wird von drift_dev generiert.
// Zum Generieren: flutter pub run build_runner build --delete-conflicting-outputs
mixin _$AppDatabase on GeneratedDatabase {
  late final Noten noten = Noten();
  late final Stimmen stimmen = Stimmen();
  late final Annotationen annotationen = Annotationen();
  late final KonfigurationEintraege konfigurationEintraege = KonfigurationEintraege();

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [noten, stimmen, annotationen, konfigurationEintraege];
}
