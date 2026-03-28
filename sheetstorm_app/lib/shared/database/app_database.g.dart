// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NotenTable extends Noten with TableInfo<$NotenTable, NotenData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titelMeta = const VerificationMeta('titel');
  @override
  late final GeneratedColumn<String> titel = GeneratedColumn<String>(
    'titel',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _komponistMeta = const VerificationMeta(
    'komponist',
  );
  @override
  late final GeneratedColumn<String> komponist = GeneratedColumn<String>(
    'komponist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lokalerPfadMeta = const VerificationMeta(
    'lokalerPfad',
  );
  @override
  late final GeneratedColumn<String> lokalerPfad = GeneratedColumn<String>(
    'lokaler_pfad',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _istOfflineVerfuegbarMeta =
      const VerificationMeta('istOfflineVerfuegbar');
  @override
  late final GeneratedColumn<bool> istOfflineVerfuegbar = GeneratedColumn<bool>(
    'ist_offline_verfuegbar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ist_offline_verfuegbar" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _erstelltAmMeta = const VerificationMeta(
    'erstelltAm',
  );
  @override
  late final GeneratedColumn<DateTime> erstelltAm = GeneratedColumn<DateTime>(
    'erstellt_am',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _aktualisiertAmMeta = const VerificationMeta(
    'aktualisiertAm',
  );
  @override
  late final GeneratedColumn<DateTime> aktualisiertAm =
      GeneratedColumn<DateTime>(
        'aktualisiert_am',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    titel,
    komponist,
    genre,
    lokalerPfad,
    istOfflineVerfuegbar,
    erstelltAm,
    aktualisiertAm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'noten';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotenData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('titel')) {
      context.handle(
        _titelMeta,
        titel.isAcceptableOrUnknown(data['titel']!, _titelMeta),
      );
    } else if (isInserting) {
      context.missing(_titelMeta);
    }
    if (data.containsKey('komponist')) {
      context.handle(
        _komponistMeta,
        komponist.isAcceptableOrUnknown(data['komponist']!, _komponistMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('lokaler_pfad')) {
      context.handle(
        _lokalerPfadMeta,
        lokalerPfad.isAcceptableOrUnknown(
          data['lokaler_pfad']!,
          _lokalerPfadMeta,
        ),
      );
    }
    if (data.containsKey('ist_offline_verfuegbar')) {
      context.handle(
        _istOfflineVerfuegbarMeta,
        istOfflineVerfuegbar.isAcceptableOrUnknown(
          data['ist_offline_verfuegbar']!,
          _istOfflineVerfuegbarMeta,
        ),
      );
    }
    if (data.containsKey('erstellt_am')) {
      context.handle(
        _erstelltAmMeta,
        erstelltAm.isAcceptableOrUnknown(data['erstellt_am']!, _erstelltAmMeta),
      );
    }
    if (data.containsKey('aktualisiert_am')) {
      context.handle(
        _aktualisiertAmMeta,
        aktualisiertAm.isAcceptableOrUnknown(
          data['aktualisiert_am']!,
          _aktualisiertAmMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotenData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotenData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      titel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titel'],
      )!,
      komponist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}komponist'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      lokalerPfad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lokaler_pfad'],
      ),
      istOfflineVerfuegbar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ist_offline_verfuegbar'],
      )!,
      erstelltAm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}erstellt_am'],
      )!,
      aktualisiertAm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}aktualisiert_am'],
      )!,
    );
  }

  @override
  $NotenTable createAlias(String alias) {
    return $NotenTable(attachedDatabase, alias);
  }
}

class NotenData extends DataClass implements Insertable<NotenData> {
  final int id;
  final String titel;
  final String? komponist;
  final String? genre;
  final String? lokalerPfad;
  final bool istOfflineVerfuegbar;
  final DateTime erstelltAm;
  final DateTime aktualisiertAm;
  const NotenData({
    required this.id,
    required this.titel,
    this.komponist,
    this.genre,
    this.lokalerPfad,
    required this.istOfflineVerfuegbar,
    required this.erstelltAm,
    required this.aktualisiertAm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['titel'] = Variable<String>(titel);
    if (!nullToAbsent || komponist != null) {
      map['komponist'] = Variable<String>(komponist);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || lokalerPfad != null) {
      map['lokaler_pfad'] = Variable<String>(lokalerPfad);
    }
    map['ist_offline_verfuegbar'] = Variable<bool>(istOfflineVerfuegbar);
    map['erstellt_am'] = Variable<DateTime>(erstelltAm);
    map['aktualisiert_am'] = Variable<DateTime>(aktualisiertAm);
    return map;
  }

  NotenCompanion toCompanion(bool nullToAbsent) {
    return NotenCompanion(
      id: Value(id),
      titel: Value(titel),
      komponist: komponist == null && nullToAbsent
          ? const Value.absent()
          : Value(komponist),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      lokalerPfad: lokalerPfad == null && nullToAbsent
          ? const Value.absent()
          : Value(lokalerPfad),
      istOfflineVerfuegbar: Value(istOfflineVerfuegbar),
      erstelltAm: Value(erstelltAm),
      aktualisiertAm: Value(aktualisiertAm),
    );
  }

  factory NotenData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotenData(
      id: serializer.fromJson<int>(json['id']),
      titel: serializer.fromJson<String>(json['titel']),
      komponist: serializer.fromJson<String?>(json['komponist']),
      genre: serializer.fromJson<String?>(json['genre']),
      lokalerPfad: serializer.fromJson<String?>(json['lokalerPfad']),
      istOfflineVerfuegbar: serializer.fromJson<bool>(
        json['istOfflineVerfuegbar'],
      ),
      erstelltAm: serializer.fromJson<DateTime>(json['erstelltAm']),
      aktualisiertAm: serializer.fromJson<DateTime>(json['aktualisiertAm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'titel': serializer.toJson<String>(titel),
      'komponist': serializer.toJson<String?>(komponist),
      'genre': serializer.toJson<String?>(genre),
      'lokalerPfad': serializer.toJson<String?>(lokalerPfad),
      'istOfflineVerfuegbar': serializer.toJson<bool>(istOfflineVerfuegbar),
      'erstelltAm': serializer.toJson<DateTime>(erstelltAm),
      'aktualisiertAm': serializer.toJson<DateTime>(aktualisiertAm),
    };
  }

  NotenData copyWith({
    int? id,
    String? titel,
    Value<String?> komponist = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<String?> lokalerPfad = const Value.absent(),
    bool? istOfflineVerfuegbar,
    DateTime? erstelltAm,
    DateTime? aktualisiertAm,
  }) => NotenData(
    id: id ?? this.id,
    titel: titel ?? this.titel,
    komponist: komponist.present ? komponist.value : this.komponist,
    genre: genre.present ? genre.value : this.genre,
    lokalerPfad: lokalerPfad.present ? lokalerPfad.value : this.lokalerPfad,
    istOfflineVerfuegbar: istOfflineVerfuegbar ?? this.istOfflineVerfuegbar,
    erstelltAm: erstelltAm ?? this.erstelltAm,
    aktualisiertAm: aktualisiertAm ?? this.aktualisiertAm,
  );
  NotenData copyWithCompanion(NotenCompanion data) {
    return NotenData(
      id: data.id.present ? data.id.value : this.id,
      titel: data.titel.present ? data.titel.value : this.titel,
      komponist: data.komponist.present ? data.komponist.value : this.komponist,
      genre: data.genre.present ? data.genre.value : this.genre,
      lokalerPfad: data.lokalerPfad.present
          ? data.lokalerPfad.value
          : this.lokalerPfad,
      istOfflineVerfuegbar: data.istOfflineVerfuegbar.present
          ? data.istOfflineVerfuegbar.value
          : this.istOfflineVerfuegbar,
      erstelltAm: data.erstelltAm.present
          ? data.erstelltAm.value
          : this.erstelltAm,
      aktualisiertAm: data.aktualisiertAm.present
          ? data.aktualisiertAm.value
          : this.aktualisiertAm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotenData(')
          ..write('id: $id, ')
          ..write('titel: $titel, ')
          ..write('komponist: $komponist, ')
          ..write('genre: $genre, ')
          ..write('lokalerPfad: $lokalerPfad, ')
          ..write('istOfflineVerfuegbar: $istOfflineVerfuegbar, ')
          ..write('erstelltAm: $erstelltAm, ')
          ..write('aktualisiertAm: $aktualisiertAm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    titel,
    komponist,
    genre,
    lokalerPfad,
    istOfflineVerfuegbar,
    erstelltAm,
    aktualisiertAm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotenData &&
          other.id == this.id &&
          other.titel == this.titel &&
          other.komponist == this.komponist &&
          other.genre == this.genre &&
          other.lokalerPfad == this.lokalerPfad &&
          other.istOfflineVerfuegbar == this.istOfflineVerfuegbar &&
          other.erstelltAm == this.erstelltAm &&
          other.aktualisiertAm == this.aktualisiertAm);
}

class NotenCompanion extends UpdateCompanion<NotenData> {
  final Value<int> id;
  final Value<String> titel;
  final Value<String?> komponist;
  final Value<String?> genre;
  final Value<String?> lokalerPfad;
  final Value<bool> istOfflineVerfuegbar;
  final Value<DateTime> erstelltAm;
  final Value<DateTime> aktualisiertAm;
  const NotenCompanion({
    this.id = const Value.absent(),
    this.titel = const Value.absent(),
    this.komponist = const Value.absent(),
    this.genre = const Value.absent(),
    this.lokalerPfad = const Value.absent(),
    this.istOfflineVerfuegbar = const Value.absent(),
    this.erstelltAm = const Value.absent(),
    this.aktualisiertAm = const Value.absent(),
  });
  NotenCompanion.insert({
    this.id = const Value.absent(),
    required String titel,
    this.komponist = const Value.absent(),
    this.genre = const Value.absent(),
    this.lokalerPfad = const Value.absent(),
    this.istOfflineVerfuegbar = const Value.absent(),
    this.erstelltAm = const Value.absent(),
    this.aktualisiertAm = const Value.absent(),
  }) : titel = Value(titel);
  static Insertable<NotenData> custom({
    Expression<int>? id,
    Expression<String>? titel,
    Expression<String>? komponist,
    Expression<String>? genre,
    Expression<String>? lokalerPfad,
    Expression<bool>? istOfflineVerfuegbar,
    Expression<DateTime>? erstelltAm,
    Expression<DateTime>? aktualisiertAm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (titel != null) 'titel': titel,
      if (komponist != null) 'komponist': komponist,
      if (genre != null) 'genre': genre,
      if (lokalerPfad != null) 'lokaler_pfad': lokalerPfad,
      if (istOfflineVerfuegbar != null)
        'ist_offline_verfuegbar': istOfflineVerfuegbar,
      if (erstelltAm != null) 'erstellt_am': erstelltAm,
      if (aktualisiertAm != null) 'aktualisiert_am': aktualisiertAm,
    });
  }

  NotenCompanion copyWith({
    Value<int>? id,
    Value<String>? titel,
    Value<String?>? komponist,
    Value<String?>? genre,
    Value<String?>? lokalerPfad,
    Value<bool>? istOfflineVerfuegbar,
    Value<DateTime>? erstelltAm,
    Value<DateTime>? aktualisiertAm,
  }) {
    return NotenCompanion(
      id: id ?? this.id,
      titel: titel ?? this.titel,
      komponist: komponist ?? this.komponist,
      genre: genre ?? this.genre,
      lokalerPfad: lokalerPfad ?? this.lokalerPfad,
      istOfflineVerfuegbar: istOfflineVerfuegbar ?? this.istOfflineVerfuegbar,
      erstelltAm: erstelltAm ?? this.erstelltAm,
      aktualisiertAm: aktualisiertAm ?? this.aktualisiertAm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (titel.present) {
      map['titel'] = Variable<String>(titel.value);
    }
    if (komponist.present) {
      map['komponist'] = Variable<String>(komponist.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (lokalerPfad.present) {
      map['lokaler_pfad'] = Variable<String>(lokalerPfad.value);
    }
    if (istOfflineVerfuegbar.present) {
      map['ist_offline_verfuegbar'] = Variable<bool>(
        istOfflineVerfuegbar.value,
      );
    }
    if (erstelltAm.present) {
      map['erstellt_am'] = Variable<DateTime>(erstelltAm.value);
    }
    if (aktualisiertAm.present) {
      map['aktualisiert_am'] = Variable<DateTime>(aktualisiertAm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotenCompanion(')
          ..write('id: $id, ')
          ..write('titel: $titel, ')
          ..write('komponist: $komponist, ')
          ..write('genre: $genre, ')
          ..write('lokalerPfad: $lokalerPfad, ')
          ..write('istOfflineVerfuegbar: $istOfflineVerfuegbar, ')
          ..write('erstelltAm: $erstelltAm, ')
          ..write('aktualisiertAm: $aktualisiertAm')
          ..write(')'))
        .toString();
  }
}

class $StimmenTable extends Stimmen with TableInfo<$StimmenTable, StimmenData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StimmenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _notenIdMeta = const VerificationMeta(
    'notenId',
  );
  @override
  late final GeneratedColumn<int> notenId = GeneratedColumn<int>(
    'noten_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES noten (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instrumentMeta = const VerificationMeta(
    'instrument',
  );
  @override
  late final GeneratedColumn<String> instrument = GeneratedColumn<String>(
    'instrument',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seitenAnzahlMeta = const VerificationMeta(
    'seitenAnzahl',
  );
  @override
  late final GeneratedColumn<int> seitenAnzahl = GeneratedColumn<int>(
    'seiten_anzahl',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    notenId,
    name,
    instrument,
    seitenAnzahl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stimmen';
  @override
  VerificationContext validateIntegrity(
    Insertable<StimmenData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('noten_id')) {
      context.handle(
        _notenIdMeta,
        notenId.isAcceptableOrUnknown(data['noten_id']!, _notenIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notenIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('instrument')) {
      context.handle(
        _instrumentMeta,
        instrument.isAcceptableOrUnknown(data['instrument']!, _instrumentMeta),
      );
    }
    if (data.containsKey('seiten_anzahl')) {
      context.handle(
        _seitenAnzahlMeta,
        seitenAnzahl.isAcceptableOrUnknown(
          data['seiten_anzahl']!,
          _seitenAnzahlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StimmenData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StimmenData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      notenId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}noten_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      instrument: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrument'],
      ),
      seitenAnzahl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seiten_anzahl'],
      )!,
    );
  }

  @override
  $StimmenTable createAlias(String alias) {
    return $StimmenTable(attachedDatabase, alias);
  }
}

class StimmenData extends DataClass implements Insertable<StimmenData> {
  final int id;
  final int notenId;
  final String name;
  final String? instrument;
  final int seitenAnzahl;
  const StimmenData({
    required this.id,
    required this.notenId,
    required this.name,
    this.instrument,
    required this.seitenAnzahl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['noten_id'] = Variable<int>(notenId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || instrument != null) {
      map['instrument'] = Variable<String>(instrument);
    }
    map['seiten_anzahl'] = Variable<int>(seitenAnzahl);
    return map;
  }

  StimmenCompanion toCompanion(bool nullToAbsent) {
    return StimmenCompanion(
      id: Value(id),
      notenId: Value(notenId),
      name: Value(name),
      instrument: instrument == null && nullToAbsent
          ? const Value.absent()
          : Value(instrument),
      seitenAnzahl: Value(seitenAnzahl),
    );
  }

  factory StimmenData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StimmenData(
      id: serializer.fromJson<int>(json['id']),
      notenId: serializer.fromJson<int>(json['notenId']),
      name: serializer.fromJson<String>(json['name']),
      instrument: serializer.fromJson<String?>(json['instrument']),
      seitenAnzahl: serializer.fromJson<int>(json['seitenAnzahl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notenId': serializer.toJson<int>(notenId),
      'name': serializer.toJson<String>(name),
      'instrument': serializer.toJson<String?>(instrument),
      'seitenAnzahl': serializer.toJson<int>(seitenAnzahl),
    };
  }

  StimmenData copyWith({
    int? id,
    int? notenId,
    String? name,
    Value<String?> instrument = const Value.absent(),
    int? seitenAnzahl,
  }) => StimmenData(
    id: id ?? this.id,
    notenId: notenId ?? this.notenId,
    name: name ?? this.name,
    instrument: instrument.present ? instrument.value : this.instrument,
    seitenAnzahl: seitenAnzahl ?? this.seitenAnzahl,
  );
  StimmenData copyWithCompanion(StimmenCompanion data) {
    return StimmenData(
      id: data.id.present ? data.id.value : this.id,
      notenId: data.notenId.present ? data.notenId.value : this.notenId,
      name: data.name.present ? data.name.value : this.name,
      instrument: data.instrument.present
          ? data.instrument.value
          : this.instrument,
      seitenAnzahl: data.seitenAnzahl.present
          ? data.seitenAnzahl.value
          : this.seitenAnzahl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StimmenData(')
          ..write('id: $id, ')
          ..write('notenId: $notenId, ')
          ..write('name: $name, ')
          ..write('instrument: $instrument, ')
          ..write('seitenAnzahl: $seitenAnzahl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, notenId, name, instrument, seitenAnzahl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StimmenData &&
          other.id == this.id &&
          other.notenId == this.notenId &&
          other.name == this.name &&
          other.instrument == this.instrument &&
          other.seitenAnzahl == this.seitenAnzahl);
}

class StimmenCompanion extends UpdateCompanion<StimmenData> {
  final Value<int> id;
  final Value<int> notenId;
  final Value<String> name;
  final Value<String?> instrument;
  final Value<int> seitenAnzahl;
  const StimmenCompanion({
    this.id = const Value.absent(),
    this.notenId = const Value.absent(),
    this.name = const Value.absent(),
    this.instrument = const Value.absent(),
    this.seitenAnzahl = const Value.absent(),
  });
  StimmenCompanion.insert({
    this.id = const Value.absent(),
    required int notenId,
    required String name,
    this.instrument = const Value.absent(),
    this.seitenAnzahl = const Value.absent(),
  }) : notenId = Value(notenId),
       name = Value(name);
  static Insertable<StimmenData> custom({
    Expression<int>? id,
    Expression<int>? notenId,
    Expression<String>? name,
    Expression<String>? instrument,
    Expression<int>? seitenAnzahl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notenId != null) 'noten_id': notenId,
      if (name != null) 'name': name,
      if (instrument != null) 'instrument': instrument,
      if (seitenAnzahl != null) 'seiten_anzahl': seitenAnzahl,
    });
  }

  StimmenCompanion copyWith({
    Value<int>? id,
    Value<int>? notenId,
    Value<String>? name,
    Value<String?>? instrument,
    Value<int>? seitenAnzahl,
  }) {
    return StimmenCompanion(
      id: id ?? this.id,
      notenId: notenId ?? this.notenId,
      name: name ?? this.name,
      instrument: instrument ?? this.instrument,
      seitenAnzahl: seitenAnzahl ?? this.seitenAnzahl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notenId.present) {
      map['noten_id'] = Variable<int>(notenId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (instrument.present) {
      map['instrument'] = Variable<String>(instrument.value);
    }
    if (seitenAnzahl.present) {
      map['seiten_anzahl'] = Variable<int>(seitenAnzahl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StimmenCompanion(')
          ..write('id: $id, ')
          ..write('notenId: $notenId, ')
          ..write('name: $name, ')
          ..write('instrument: $instrument, ')
          ..write('seitenAnzahl: $seitenAnzahl')
          ..write(')'))
        .toString();
  }
}

class $AnnotationenTable extends Annotationen
    with TableInfo<$AnnotationenTable, AnnotationenData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _stimmeIdMeta = const VerificationMeta(
    'stimmeId',
  );
  @override
  late final GeneratedColumn<int> stimmeId = GeneratedColumn<int>(
    'stimme_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stimmen (id)',
    ),
  );
  static const VerificationMeta _ebeneMeta = const VerificationMeta('ebene');
  @override
  late final GeneratedColumn<String> ebene = GeneratedColumn<String>(
    'ebene',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xRelativMeta = const VerificationMeta(
    'xRelativ',
  );
  @override
  late final GeneratedColumn<double> xRelativ = GeneratedColumn<double>(
    'x_relativ',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yRelativMeta = const VerificationMeta(
    'yRelativ',
  );
  @override
  late final GeneratedColumn<double> yRelativ = GeneratedColumn<double>(
    'y_relativ',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seiteMeta = const VerificationMeta('seite');
  @override
  late final GeneratedColumn<double> seite = GeneratedColumn<double>(
    'seite',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _svgDatenMeta = const VerificationMeta(
    'svgDaten',
  );
  @override
  late final GeneratedColumn<String> svgDaten = GeneratedColumn<String>(
    'svg_daten',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _erstelltAmMeta = const VerificationMeta(
    'erstelltAm',
  );
  @override
  late final GeneratedColumn<DateTime> erstelltAm = GeneratedColumn<DateTime>(
    'erstellt_am',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stimmeId,
    ebene,
    xRelativ,
    yRelativ,
    seite,
    svgDaten,
    erstelltAm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotationen';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnnotationenData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stimme_id')) {
      context.handle(
        _stimmeIdMeta,
        stimmeId.isAcceptableOrUnknown(data['stimme_id']!, _stimmeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stimmeIdMeta);
    }
    if (data.containsKey('ebene')) {
      context.handle(
        _ebeneMeta,
        ebene.isAcceptableOrUnknown(data['ebene']!, _ebeneMeta),
      );
    } else if (isInserting) {
      context.missing(_ebeneMeta);
    }
    if (data.containsKey('x_relativ')) {
      context.handle(
        _xRelativMeta,
        xRelativ.isAcceptableOrUnknown(data['x_relativ']!, _xRelativMeta),
      );
    } else if (isInserting) {
      context.missing(_xRelativMeta);
    }
    if (data.containsKey('y_relativ')) {
      context.handle(
        _yRelativMeta,
        yRelativ.isAcceptableOrUnknown(data['y_relativ']!, _yRelativMeta),
      );
    } else if (isInserting) {
      context.missing(_yRelativMeta);
    }
    if (data.containsKey('seite')) {
      context.handle(
        _seiteMeta,
        seite.isAcceptableOrUnknown(data['seite']!, _seiteMeta),
      );
    } else if (isInserting) {
      context.missing(_seiteMeta);
    }
    if (data.containsKey('svg_daten')) {
      context.handle(
        _svgDatenMeta,
        svgDaten.isAcceptableOrUnknown(data['svg_daten']!, _svgDatenMeta),
      );
    } else if (isInserting) {
      context.missing(_svgDatenMeta);
    }
    if (data.containsKey('erstellt_am')) {
      context.handle(
        _erstelltAmMeta,
        erstelltAm.isAcceptableOrUnknown(data['erstellt_am']!, _erstelltAmMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnnotationenData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnotationenData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stimmeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stimme_id'],
      )!,
      ebene: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ebene'],
      )!,
      xRelativ: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x_relativ'],
      )!,
      yRelativ: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y_relativ'],
      )!,
      seite: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}seite'],
      )!,
      svgDaten: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}svg_daten'],
      )!,
      erstelltAm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}erstellt_am'],
      )!,
    );
  }

  @override
  $AnnotationenTable createAlias(String alias) {
    return $AnnotationenTable(attachedDatabase, alias);
  }
}

class AnnotationenData extends DataClass
    implements Insertable<AnnotationenData> {
  final int id;
  final int stimmeId;
  final String ebene;
  final double xRelativ;
  final double yRelativ;
  final double seite;
  final String svgDaten;
  final DateTime erstelltAm;
  const AnnotationenData({
    required this.id,
    required this.stimmeId,
    required this.ebene,
    required this.xRelativ,
    required this.yRelativ,
    required this.seite,
    required this.svgDaten,
    required this.erstelltAm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stimme_id'] = Variable<int>(stimmeId);
    map['ebene'] = Variable<String>(ebene);
    map['x_relativ'] = Variable<double>(xRelativ);
    map['y_relativ'] = Variable<double>(yRelativ);
    map['seite'] = Variable<double>(seite);
    map['svg_daten'] = Variable<String>(svgDaten);
    map['erstellt_am'] = Variable<DateTime>(erstelltAm);
    return map;
  }

  AnnotationenCompanion toCompanion(bool nullToAbsent) {
    return AnnotationenCompanion(
      id: Value(id),
      stimmeId: Value(stimmeId),
      ebene: Value(ebene),
      xRelativ: Value(xRelativ),
      yRelativ: Value(yRelativ),
      seite: Value(seite),
      svgDaten: Value(svgDaten),
      erstelltAm: Value(erstelltAm),
    );
  }

  factory AnnotationenData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnotationenData(
      id: serializer.fromJson<int>(json['id']),
      stimmeId: serializer.fromJson<int>(json['stimmeId']),
      ebene: serializer.fromJson<String>(json['ebene']),
      xRelativ: serializer.fromJson<double>(json['xRelativ']),
      yRelativ: serializer.fromJson<double>(json['yRelativ']),
      seite: serializer.fromJson<double>(json['seite']),
      svgDaten: serializer.fromJson<String>(json['svgDaten']),
      erstelltAm: serializer.fromJson<DateTime>(json['erstelltAm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stimmeId': serializer.toJson<int>(stimmeId),
      'ebene': serializer.toJson<String>(ebene),
      'xRelativ': serializer.toJson<double>(xRelativ),
      'yRelativ': serializer.toJson<double>(yRelativ),
      'seite': serializer.toJson<double>(seite),
      'svgDaten': serializer.toJson<String>(svgDaten),
      'erstelltAm': serializer.toJson<DateTime>(erstelltAm),
    };
  }

  AnnotationenData copyWith({
    int? id,
    int? stimmeId,
    String? ebene,
    double? xRelativ,
    double? yRelativ,
    double? seite,
    String? svgDaten,
    DateTime? erstelltAm,
  }) => AnnotationenData(
    id: id ?? this.id,
    stimmeId: stimmeId ?? this.stimmeId,
    ebene: ebene ?? this.ebene,
    xRelativ: xRelativ ?? this.xRelativ,
    yRelativ: yRelativ ?? this.yRelativ,
    seite: seite ?? this.seite,
    svgDaten: svgDaten ?? this.svgDaten,
    erstelltAm: erstelltAm ?? this.erstelltAm,
  );
  AnnotationenData copyWithCompanion(AnnotationenCompanion data) {
    return AnnotationenData(
      id: data.id.present ? data.id.value : this.id,
      stimmeId: data.stimmeId.present ? data.stimmeId.value : this.stimmeId,
      ebene: data.ebene.present ? data.ebene.value : this.ebene,
      xRelativ: data.xRelativ.present ? data.xRelativ.value : this.xRelativ,
      yRelativ: data.yRelativ.present ? data.yRelativ.value : this.yRelativ,
      seite: data.seite.present ? data.seite.value : this.seite,
      svgDaten: data.svgDaten.present ? data.svgDaten.value : this.svgDaten,
      erstelltAm: data.erstelltAm.present
          ? data.erstelltAm.value
          : this.erstelltAm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationenData(')
          ..write('id: $id, ')
          ..write('stimmeId: $stimmeId, ')
          ..write('ebene: $ebene, ')
          ..write('xRelativ: $xRelativ, ')
          ..write('yRelativ: $yRelativ, ')
          ..write('seite: $seite, ')
          ..write('svgDaten: $svgDaten, ')
          ..write('erstelltAm: $erstelltAm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stimmeId,
    ebene,
    xRelativ,
    yRelativ,
    seite,
    svgDaten,
    erstelltAm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnotationenData &&
          other.id == this.id &&
          other.stimmeId == this.stimmeId &&
          other.ebene == this.ebene &&
          other.xRelativ == this.xRelativ &&
          other.yRelativ == this.yRelativ &&
          other.seite == this.seite &&
          other.svgDaten == this.svgDaten &&
          other.erstelltAm == this.erstelltAm);
}

class AnnotationenCompanion extends UpdateCompanion<AnnotationenData> {
  final Value<int> id;
  final Value<int> stimmeId;
  final Value<String> ebene;
  final Value<double> xRelativ;
  final Value<double> yRelativ;
  final Value<double> seite;
  final Value<String> svgDaten;
  final Value<DateTime> erstelltAm;
  const AnnotationenCompanion({
    this.id = const Value.absent(),
    this.stimmeId = const Value.absent(),
    this.ebene = const Value.absent(),
    this.xRelativ = const Value.absent(),
    this.yRelativ = const Value.absent(),
    this.seite = const Value.absent(),
    this.svgDaten = const Value.absent(),
    this.erstelltAm = const Value.absent(),
  });
  AnnotationenCompanion.insert({
    this.id = const Value.absent(),
    required int stimmeId,
    required String ebene,
    required double xRelativ,
    required double yRelativ,
    required double seite,
    required String svgDaten,
    this.erstelltAm = const Value.absent(),
  }) : stimmeId = Value(stimmeId),
       ebene = Value(ebene),
       xRelativ = Value(xRelativ),
       yRelativ = Value(yRelativ),
       seite = Value(seite),
       svgDaten = Value(svgDaten);
  static Insertable<AnnotationenData> custom({
    Expression<int>? id,
    Expression<int>? stimmeId,
    Expression<String>? ebene,
    Expression<double>? xRelativ,
    Expression<double>? yRelativ,
    Expression<double>? seite,
    Expression<String>? svgDaten,
    Expression<DateTime>? erstelltAm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stimmeId != null) 'stimme_id': stimmeId,
      if (ebene != null) 'ebene': ebene,
      if (xRelativ != null) 'x_relativ': xRelativ,
      if (yRelativ != null) 'y_relativ': yRelativ,
      if (seite != null) 'seite': seite,
      if (svgDaten != null) 'svg_daten': svgDaten,
      if (erstelltAm != null) 'erstellt_am': erstelltAm,
    });
  }

  AnnotationenCompanion copyWith({
    Value<int>? id,
    Value<int>? stimmeId,
    Value<String>? ebene,
    Value<double>? xRelativ,
    Value<double>? yRelativ,
    Value<double>? seite,
    Value<String>? svgDaten,
    Value<DateTime>? erstelltAm,
  }) {
    return AnnotationenCompanion(
      id: id ?? this.id,
      stimmeId: stimmeId ?? this.stimmeId,
      ebene: ebene ?? this.ebene,
      xRelativ: xRelativ ?? this.xRelativ,
      yRelativ: yRelativ ?? this.yRelativ,
      seite: seite ?? this.seite,
      svgDaten: svgDaten ?? this.svgDaten,
      erstelltAm: erstelltAm ?? this.erstelltAm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stimmeId.present) {
      map['stimme_id'] = Variable<int>(stimmeId.value);
    }
    if (ebene.present) {
      map['ebene'] = Variable<String>(ebene.value);
    }
    if (xRelativ.present) {
      map['x_relativ'] = Variable<double>(xRelativ.value);
    }
    if (yRelativ.present) {
      map['y_relativ'] = Variable<double>(yRelativ.value);
    }
    if (seite.present) {
      map['seite'] = Variable<double>(seite.value);
    }
    if (svgDaten.present) {
      map['svg_daten'] = Variable<String>(svgDaten.value);
    }
    if (erstelltAm.present) {
      map['erstellt_am'] = Variable<DateTime>(erstelltAm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationenCompanion(')
          ..write('id: $id, ')
          ..write('stimmeId: $stimmeId, ')
          ..write('ebene: $ebene, ')
          ..write('xRelativ: $xRelativ, ')
          ..write('yRelativ: $yRelativ, ')
          ..write('seite: $seite, ')
          ..write('svgDaten: $svgDaten, ')
          ..write('erstelltAm: $erstelltAm')
          ..write(')'))
        .toString();
  }
}

class $KonfigurationEintraegeTable extends KonfigurationEintraege
    with TableInfo<$KonfigurationEintraegeTable, KonfigurationEintraegeData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KonfigurationEintraegeTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ebeneMeta = const VerificationMeta('ebene');
  @override
  late final GeneratedColumn<String> ebene = GeneratedColumn<String>(
    'ebene',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schluesselMeta = const VerificationMeta(
    'schluessel',
  );
  @override
  late final GeneratedColumn<String> schluessel = GeneratedColumn<String>(
    'schluessel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wertMeta = const VerificationMeta('wert');
  @override
  late final GeneratedColumn<String> wert = GeneratedColumn<String>(
    'wert',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _istGesperrtMeta = const VerificationMeta(
    'istGesperrt',
  );
  @override
  late final GeneratedColumn<bool> istGesperrt = GeneratedColumn<bool>(
    'ist_gesperrt',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ist_gesperrt" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ebene,
    schluessel,
    wert,
    istGesperrt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'konfiguration_eintraege';
  @override
  VerificationContext validateIntegrity(
    Insertable<KonfigurationEintraegeData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ebene')) {
      context.handle(
        _ebeneMeta,
        ebene.isAcceptableOrUnknown(data['ebene']!, _ebeneMeta),
      );
    } else if (isInserting) {
      context.missing(_ebeneMeta);
    }
    if (data.containsKey('schluessel')) {
      context.handle(
        _schluesselMeta,
        schluessel.isAcceptableOrUnknown(data['schluessel']!, _schluesselMeta),
      );
    } else if (isInserting) {
      context.missing(_schluesselMeta);
    }
    if (data.containsKey('wert')) {
      context.handle(
        _wertMeta,
        wert.isAcceptableOrUnknown(data['wert']!, _wertMeta),
      );
    } else if (isInserting) {
      context.missing(_wertMeta);
    }
    if (data.containsKey('ist_gesperrt')) {
      context.handle(
        _istGesperrtMeta,
        istGesperrt.isAcceptableOrUnknown(
          data['ist_gesperrt']!,
          _istGesperrtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KonfigurationEintraegeData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KonfigurationEintraegeData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ebene: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ebene'],
      )!,
      schluessel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schluessel'],
      )!,
      wert: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wert'],
      )!,
      istGesperrt: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ist_gesperrt'],
      )!,
    );
  }

  @override
  $KonfigurationEintraegeTable createAlias(String alias) {
    return $KonfigurationEintraegeTable(attachedDatabase, alias);
  }
}

class KonfigurationEintraegeData extends DataClass
    implements Insertable<KonfigurationEintraegeData> {
  final int id;
  final String ebene;
  final String schluessel;
  final String wert;
  final bool istGesperrt;
  const KonfigurationEintraegeData({
    required this.id,
    required this.ebene,
    required this.schluessel,
    required this.wert,
    required this.istGesperrt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ebene'] = Variable<String>(ebene);
    map['schluessel'] = Variable<String>(schluessel);
    map['wert'] = Variable<String>(wert);
    map['ist_gesperrt'] = Variable<bool>(istGesperrt);
    return map;
  }

  KonfigurationEintraegeCompanion toCompanion(bool nullToAbsent) {
    return KonfigurationEintraegeCompanion(
      id: Value(id),
      ebene: Value(ebene),
      schluessel: Value(schluessel),
      wert: Value(wert),
      istGesperrt: Value(istGesperrt),
    );
  }

  factory KonfigurationEintraegeData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KonfigurationEintraegeData(
      id: serializer.fromJson<int>(json['id']),
      ebene: serializer.fromJson<String>(json['ebene']),
      schluessel: serializer.fromJson<String>(json['schluessel']),
      wert: serializer.fromJson<String>(json['wert']),
      istGesperrt: serializer.fromJson<bool>(json['istGesperrt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ebene': serializer.toJson<String>(ebene),
      'schluessel': serializer.toJson<String>(schluessel),
      'wert': serializer.toJson<String>(wert),
      'istGesperrt': serializer.toJson<bool>(istGesperrt),
    };
  }

  KonfigurationEintraegeData copyWith({
    int? id,
    String? ebene,
    String? schluessel,
    String? wert,
    bool? istGesperrt,
  }) => KonfigurationEintraegeData(
    id: id ?? this.id,
    ebene: ebene ?? this.ebene,
    schluessel: schluessel ?? this.schluessel,
    wert: wert ?? this.wert,
    istGesperrt: istGesperrt ?? this.istGesperrt,
  );
  KonfigurationEintraegeData copyWithCompanion(
    KonfigurationEintraegeCompanion data,
  ) {
    return KonfigurationEintraegeData(
      id: data.id.present ? data.id.value : this.id,
      ebene: data.ebene.present ? data.ebene.value : this.ebene,
      schluessel: data.schluessel.present
          ? data.schluessel.value
          : this.schluessel,
      wert: data.wert.present ? data.wert.value : this.wert,
      istGesperrt: data.istGesperrt.present
          ? data.istGesperrt.value
          : this.istGesperrt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KonfigurationEintraegeData(')
          ..write('id: $id, ')
          ..write('ebene: $ebene, ')
          ..write('schluessel: $schluessel, ')
          ..write('wert: $wert, ')
          ..write('istGesperrt: $istGesperrt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ebene, schluessel, wert, istGesperrt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KonfigurationEintraegeData &&
          other.id == this.id &&
          other.ebene == this.ebene &&
          other.schluessel == this.schluessel &&
          other.wert == this.wert &&
          other.istGesperrt == this.istGesperrt);
}

class KonfigurationEintraegeCompanion
    extends UpdateCompanion<KonfigurationEintraegeData> {
  final Value<int> id;
  final Value<String> ebene;
  final Value<String> schluessel;
  final Value<String> wert;
  final Value<bool> istGesperrt;
  const KonfigurationEintraegeCompanion({
    this.id = const Value.absent(),
    this.ebene = const Value.absent(),
    this.schluessel = const Value.absent(),
    this.wert = const Value.absent(),
    this.istGesperrt = const Value.absent(),
  });
  KonfigurationEintraegeCompanion.insert({
    this.id = const Value.absent(),
    required String ebene,
    required String schluessel,
    required String wert,
    this.istGesperrt = const Value.absent(),
  }) : ebene = Value(ebene),
       schluessel = Value(schluessel),
       wert = Value(wert);
  static Insertable<KonfigurationEintraegeData> custom({
    Expression<int>? id,
    Expression<String>? ebene,
    Expression<String>? schluessel,
    Expression<String>? wert,
    Expression<bool>? istGesperrt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ebene != null) 'ebene': ebene,
      if (schluessel != null) 'schluessel': schluessel,
      if (wert != null) 'wert': wert,
      if (istGesperrt != null) 'ist_gesperrt': istGesperrt,
    });
  }

  KonfigurationEintraegeCompanion copyWith({
    Value<int>? id,
    Value<String>? ebene,
    Value<String>? schluessel,
    Value<String>? wert,
    Value<bool>? istGesperrt,
  }) {
    return KonfigurationEintraegeCompanion(
      id: id ?? this.id,
      ebene: ebene ?? this.ebene,
      schluessel: schluessel ?? this.schluessel,
      wert: wert ?? this.wert,
      istGesperrt: istGesperrt ?? this.istGesperrt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ebene.present) {
      map['ebene'] = Variable<String>(ebene.value);
    }
    if (schluessel.present) {
      map['schluessel'] = Variable<String>(schluessel.value);
    }
    if (wert.present) {
      map['wert'] = Variable<String>(wert.value);
    }
    if (istGesperrt.present) {
      map['ist_gesperrt'] = Variable<bool>(istGesperrt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KonfigurationEintraegeCompanion(')
          ..write('id: $id, ')
          ..write('ebene: $ebene, ')
          ..write('schluessel: $schluessel, ')
          ..write('wert: $wert, ')
          ..write('istGesperrt: $istGesperrt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotenTable noten = $NotenTable(this);
  late final $StimmenTable stimmen = $StimmenTable(this);
  late final $AnnotationenTable annotationen = $AnnotationenTable(this);
  late final $KonfigurationEintraegeTable konfigurationEintraege =
      $KonfigurationEintraegeTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    noten,
    stimmen,
    annotationen,
    konfigurationEintraege,
  ];
}

typedef $$NotenTableCreateCompanionBuilder =
    NotenCompanion Function({
      Value<int> id,
      required String titel,
      Value<String?> komponist,
      Value<String?> genre,
      Value<String?> lokalerPfad,
      Value<bool> istOfflineVerfuegbar,
      Value<DateTime> erstelltAm,
      Value<DateTime> aktualisiertAm,
    });
typedef $$NotenTableUpdateCompanionBuilder =
    NotenCompanion Function({
      Value<int> id,
      Value<String> titel,
      Value<String?> komponist,
      Value<String?> genre,
      Value<String?> lokalerPfad,
      Value<bool> istOfflineVerfuegbar,
      Value<DateTime> erstelltAm,
      Value<DateTime> aktualisiertAm,
    });

final class $$NotenTableReferences
    extends BaseReferences<_$AppDatabase, $NotenTable, NotenData> {
  $$NotenTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StimmenTable, List<StimmenData>>
  _stimmenRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stimmen,
    aliasName: $_aliasNameGenerator(db.noten.id, db.stimmen.notenId),
  );

  $$StimmenTableProcessedTableManager get stimmenRefs {
    final manager = $$StimmenTableTableManager(
      $_db,
      $_db.stimmen,
    ).filter((f) => f.notenId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stimmenRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NotenTableFilterComposer extends Composer<_$AppDatabase, $NotenTable> {
  $$NotenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titel => $composableBuilder(
    column: $table.titel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get komponist => $composableBuilder(
    column: $table.komponist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lokalerPfad => $composableBuilder(
    column: $table.lokalerPfad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get istOfflineVerfuegbar => $composableBuilder(
    column: $table.istOfflineVerfuegbar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get aktualisiertAm => $composableBuilder(
    column: $table.aktualisiertAm,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> stimmenRefs(
    Expression<bool> Function($$StimmenTableFilterComposer f) f,
  ) {
    final $$StimmenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stimmen,
      getReferencedColumn: (t) => t.notenId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StimmenTableFilterComposer(
            $db: $db,
            $table: $db.stimmen,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotenTableOrderingComposer
    extends Composer<_$AppDatabase, $NotenTable> {
  $$NotenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titel => $composableBuilder(
    column: $table.titel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get komponist => $composableBuilder(
    column: $table.komponist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lokalerPfad => $composableBuilder(
    column: $table.lokalerPfad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get istOfflineVerfuegbar => $composableBuilder(
    column: $table.istOfflineVerfuegbar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get aktualisiertAm => $composableBuilder(
    column: $table.aktualisiertAm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotenTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotenTable> {
  $$NotenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get titel =>
      $composableBuilder(column: $table.titel, builder: (column) => column);

  GeneratedColumn<String> get komponist =>
      $composableBuilder(column: $table.komponist, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get lokalerPfad => $composableBuilder(
    column: $table.lokalerPfad,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get istOfflineVerfuegbar => $composableBuilder(
    column: $table.istOfflineVerfuegbar,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get aktualisiertAm => $composableBuilder(
    column: $table.aktualisiertAm,
    builder: (column) => column,
  );

  Expression<T> stimmenRefs<T extends Object>(
    Expression<T> Function($$StimmenTableAnnotationComposer a) f,
  ) {
    final $$StimmenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stimmen,
      getReferencedColumn: (t) => t.notenId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StimmenTableAnnotationComposer(
            $db: $db,
            $table: $db.stimmen,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotenTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotenTable,
          NotenData,
          $$NotenTableFilterComposer,
          $$NotenTableOrderingComposer,
          $$NotenTableAnnotationComposer,
          $$NotenTableCreateCompanionBuilder,
          $$NotenTableUpdateCompanionBuilder,
          (NotenData, $$NotenTableReferences),
          NotenData,
          PrefetchHooks Function({bool stimmenRefs})
        > {
  $$NotenTableTableManager(_$AppDatabase db, $NotenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> titel = const Value.absent(),
                Value<String?> komponist = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> lokalerPfad = const Value.absent(),
                Value<bool> istOfflineVerfuegbar = const Value.absent(),
                Value<DateTime> erstelltAm = const Value.absent(),
                Value<DateTime> aktualisiertAm = const Value.absent(),
              }) => NotenCompanion(
                id: id,
                titel: titel,
                komponist: komponist,
                genre: genre,
                lokalerPfad: lokalerPfad,
                istOfflineVerfuegbar: istOfflineVerfuegbar,
                erstelltAm: erstelltAm,
                aktualisiertAm: aktualisiertAm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String titel,
                Value<String?> komponist = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> lokalerPfad = const Value.absent(),
                Value<bool> istOfflineVerfuegbar = const Value.absent(),
                Value<DateTime> erstelltAm = const Value.absent(),
                Value<DateTime> aktualisiertAm = const Value.absent(),
              }) => NotenCompanion.insert(
                id: id,
                titel: titel,
                komponist: komponist,
                genre: genre,
                lokalerPfad: lokalerPfad,
                istOfflineVerfuegbar: istOfflineVerfuegbar,
                erstelltAm: erstelltAm,
                aktualisiertAm: aktualisiertAm,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$NotenTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({stimmenRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (stimmenRefs) db.stimmen],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stimmenRefs)
                    await $_getPrefetchedData<
                      NotenData,
                      $NotenTable,
                      StimmenData
                    >(
                      currentTable: table,
                      referencedTable: $$NotenTableReferences._stimmenRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$NotenTableReferences(db, table, p0).stimmenRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.notenId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NotenTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotenTable,
      NotenData,
      $$NotenTableFilterComposer,
      $$NotenTableOrderingComposer,
      $$NotenTableAnnotationComposer,
      $$NotenTableCreateCompanionBuilder,
      $$NotenTableUpdateCompanionBuilder,
      (NotenData, $$NotenTableReferences),
      NotenData,
      PrefetchHooks Function({bool stimmenRefs})
    >;
typedef $$StimmenTableCreateCompanionBuilder =
    StimmenCompanion Function({
      Value<int> id,
      required int notenId,
      required String name,
      Value<String?> instrument,
      Value<int> seitenAnzahl,
    });
typedef $$StimmenTableUpdateCompanionBuilder =
    StimmenCompanion Function({
      Value<int> id,
      Value<int> notenId,
      Value<String> name,
      Value<String?> instrument,
      Value<int> seitenAnzahl,
    });

final class $$StimmenTableReferences
    extends BaseReferences<_$AppDatabase, $StimmenTable, StimmenData> {
  $$StimmenTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotenTable _notenIdTable(_$AppDatabase db) => db.noten.createAlias(
    $_aliasNameGenerator(db.stimmen.notenId, db.noten.id),
  );

  $$NotenTableProcessedTableManager get notenId {
    final $_column = $_itemColumn<int>('noten_id')!;

    final manager = $$NotenTableTableManager(
      $_db,
      $_db.noten,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notenIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AnnotationenTable, List<AnnotationenData>>
  _annotationenRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.annotationen,
    aliasName: $_aliasNameGenerator(db.stimmen.id, db.annotationen.stimmeId),
  );

  $$AnnotationenTableProcessedTableManager get annotationenRefs {
    final manager = $$AnnotationenTableTableManager(
      $_db,
      $_db.annotationen,
    ).filter((f) => f.stimmeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_annotationenRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StimmenTableFilterComposer
    extends Composer<_$AppDatabase, $StimmenTable> {
  $$StimmenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instrument => $composableBuilder(
    column: $table.instrument,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seitenAnzahl => $composableBuilder(
    column: $table.seitenAnzahl,
    builder: (column) => ColumnFilters(column),
  );

  $$NotenTableFilterComposer get notenId {
    final $$NotenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notenId,
      referencedTable: $db.noten,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotenTableFilterComposer(
            $db: $db,
            $table: $db.noten,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> annotationenRefs(
    Expression<bool> Function($$AnnotationenTableFilterComposer f) f,
  ) {
    final $$AnnotationenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotationen,
      getReferencedColumn: (t) => t.stimmeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationenTableFilterComposer(
            $db: $db,
            $table: $db.annotationen,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StimmenTableOrderingComposer
    extends Composer<_$AppDatabase, $StimmenTable> {
  $$StimmenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instrument => $composableBuilder(
    column: $table.instrument,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seitenAnzahl => $composableBuilder(
    column: $table.seitenAnzahl,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotenTableOrderingComposer get notenId {
    final $$NotenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notenId,
      referencedTable: $db.noten,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotenTableOrderingComposer(
            $db: $db,
            $table: $db.noten,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StimmenTableAnnotationComposer
    extends Composer<_$AppDatabase, $StimmenTable> {
  $$StimmenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get instrument => $composableBuilder(
    column: $table.instrument,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seitenAnzahl => $composableBuilder(
    column: $table.seitenAnzahl,
    builder: (column) => column,
  );

  $$NotenTableAnnotationComposer get notenId {
    final $$NotenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notenId,
      referencedTable: $db.noten,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotenTableAnnotationComposer(
            $db: $db,
            $table: $db.noten,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> annotationenRefs<T extends Object>(
    Expression<T> Function($$AnnotationenTableAnnotationComposer a) f,
  ) {
    final $$AnnotationenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotationen,
      getReferencedColumn: (t) => t.stimmeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationenTableAnnotationComposer(
            $db: $db,
            $table: $db.annotationen,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StimmenTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StimmenTable,
          StimmenData,
          $$StimmenTableFilterComposer,
          $$StimmenTableOrderingComposer,
          $$StimmenTableAnnotationComposer,
          $$StimmenTableCreateCompanionBuilder,
          $$StimmenTableUpdateCompanionBuilder,
          (StimmenData, $$StimmenTableReferences),
          StimmenData,
          PrefetchHooks Function({bool notenId, bool annotationenRefs})
        > {
  $$StimmenTableTableManager(_$AppDatabase db, $StimmenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StimmenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StimmenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StimmenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> notenId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> instrument = const Value.absent(),
                Value<int> seitenAnzahl = const Value.absent(),
              }) => StimmenCompanion(
                id: id,
                notenId: notenId,
                name: name,
                instrument: instrument,
                seitenAnzahl: seitenAnzahl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int notenId,
                required String name,
                Value<String?> instrument = const Value.absent(),
                Value<int> seitenAnzahl = const Value.absent(),
              }) => StimmenCompanion.insert(
                id: id,
                notenId: notenId,
                name: name,
                instrument: instrument,
                seitenAnzahl: seitenAnzahl,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StimmenTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notenId = false, annotationenRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (annotationenRefs) db.annotationen],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (notenId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.notenId,
                                referencedTable: $$StimmenTableReferences
                                    ._notenIdTable(db),
                                referencedColumn: $$StimmenTableReferences
                                    ._notenIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (annotationenRefs)
                    await $_getPrefetchedData<
                      StimmenData,
                      $StimmenTable,
                      AnnotationenData
                    >(
                      currentTable: table,
                      referencedTable: $$StimmenTableReferences
                          ._annotationenRefsTable(db),
                      managerFromTypedResult: (p0) => $$StimmenTableReferences(
                        db,
                        table,
                        p0,
                      ).annotationenRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.stimmeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StimmenTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StimmenTable,
      StimmenData,
      $$StimmenTableFilterComposer,
      $$StimmenTableOrderingComposer,
      $$StimmenTableAnnotationComposer,
      $$StimmenTableCreateCompanionBuilder,
      $$StimmenTableUpdateCompanionBuilder,
      (StimmenData, $$StimmenTableReferences),
      StimmenData,
      PrefetchHooks Function({bool notenId, bool annotationenRefs})
    >;
typedef $$AnnotationenTableCreateCompanionBuilder =
    AnnotationenCompanion Function({
      Value<int> id,
      required int stimmeId,
      required String ebene,
      required double xRelativ,
      required double yRelativ,
      required double seite,
      required String svgDaten,
      Value<DateTime> erstelltAm,
    });
typedef $$AnnotationenTableUpdateCompanionBuilder =
    AnnotationenCompanion Function({
      Value<int> id,
      Value<int> stimmeId,
      Value<String> ebene,
      Value<double> xRelativ,
      Value<double> yRelativ,
      Value<double> seite,
      Value<String> svgDaten,
      Value<DateTime> erstelltAm,
    });

final class $$AnnotationenTableReferences
    extends
        BaseReferences<_$AppDatabase, $AnnotationenTable, AnnotationenData> {
  $$AnnotationenTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StimmenTable _stimmeIdTable(_$AppDatabase db) =>
      db.stimmen.createAlias(
        $_aliasNameGenerator(db.annotationen.stimmeId, db.stimmen.id),
      );

  $$StimmenTableProcessedTableManager get stimmeId {
    final $_column = $_itemColumn<int>('stimme_id')!;

    final manager = $$StimmenTableTableManager(
      $_db,
      $_db.stimmen,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stimmeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnnotationenTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationenTable> {
  $$AnnotationenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ebene => $composableBuilder(
    column: $table.ebene,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get xRelativ => $composableBuilder(
    column: $table.xRelativ,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get yRelativ => $composableBuilder(
    column: $table.yRelativ,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get seite => $composableBuilder(
    column: $table.seite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get svgDaten => $composableBuilder(
    column: $table.svgDaten,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => ColumnFilters(column),
  );

  $$StimmenTableFilterComposer get stimmeId {
    final $$StimmenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stimmeId,
      referencedTable: $db.stimmen,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StimmenTableFilterComposer(
            $db: $db,
            $table: $db.stimmen,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationenTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationenTable> {
  $$AnnotationenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ebene => $composableBuilder(
    column: $table.ebene,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get xRelativ => $composableBuilder(
    column: $table.xRelativ,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get yRelativ => $composableBuilder(
    column: $table.yRelativ,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get seite => $composableBuilder(
    column: $table.seite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get svgDaten => $composableBuilder(
    column: $table.svgDaten,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => ColumnOrderings(column),
  );

  $$StimmenTableOrderingComposer get stimmeId {
    final $$StimmenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stimmeId,
      referencedTable: $db.stimmen,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StimmenTableOrderingComposer(
            $db: $db,
            $table: $db.stimmen,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationenTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationenTable> {
  $$AnnotationenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ebene =>
      $composableBuilder(column: $table.ebene, builder: (column) => column);

  GeneratedColumn<double> get xRelativ =>
      $composableBuilder(column: $table.xRelativ, builder: (column) => column);

  GeneratedColumn<double> get yRelativ =>
      $composableBuilder(column: $table.yRelativ, builder: (column) => column);

  GeneratedColumn<double> get seite =>
      $composableBuilder(column: $table.seite, builder: (column) => column);

  GeneratedColumn<String> get svgDaten =>
      $composableBuilder(column: $table.svgDaten, builder: (column) => column);

  GeneratedColumn<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => column,
  );

  $$StimmenTableAnnotationComposer get stimmeId {
    final $$StimmenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stimmeId,
      referencedTable: $db.stimmen,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StimmenTableAnnotationComposer(
            $db: $db,
            $table: $db.stimmen,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationenTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationenTable,
          AnnotationenData,
          $$AnnotationenTableFilterComposer,
          $$AnnotationenTableOrderingComposer,
          $$AnnotationenTableAnnotationComposer,
          $$AnnotationenTableCreateCompanionBuilder,
          $$AnnotationenTableUpdateCompanionBuilder,
          (AnnotationenData, $$AnnotationenTableReferences),
          AnnotationenData,
          PrefetchHooks Function({bool stimmeId})
        > {
  $$AnnotationenTableTableManager(_$AppDatabase db, $AnnotationenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> stimmeId = const Value.absent(),
                Value<String> ebene = const Value.absent(),
                Value<double> xRelativ = const Value.absent(),
                Value<double> yRelativ = const Value.absent(),
                Value<double> seite = const Value.absent(),
                Value<String> svgDaten = const Value.absent(),
                Value<DateTime> erstelltAm = const Value.absent(),
              }) => AnnotationenCompanion(
                id: id,
                stimmeId: stimmeId,
                ebene: ebene,
                xRelativ: xRelativ,
                yRelativ: yRelativ,
                seite: seite,
                svgDaten: svgDaten,
                erstelltAm: erstelltAm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int stimmeId,
                required String ebene,
                required double xRelativ,
                required double yRelativ,
                required double seite,
                required String svgDaten,
                Value<DateTime> erstelltAm = const Value.absent(),
              }) => AnnotationenCompanion.insert(
                id: id,
                stimmeId: stimmeId,
                ebene: ebene,
                xRelativ: xRelativ,
                yRelativ: yRelativ,
                seite: seite,
                svgDaten: svgDaten,
                erstelltAm: erstelltAm,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnnotationenTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stimmeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (stimmeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.stimmeId,
                                referencedTable: $$AnnotationenTableReferences
                                    ._stimmeIdTable(db),
                                referencedColumn: $$AnnotationenTableReferences
                                    ._stimmeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AnnotationenTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationenTable,
      AnnotationenData,
      $$AnnotationenTableFilterComposer,
      $$AnnotationenTableOrderingComposer,
      $$AnnotationenTableAnnotationComposer,
      $$AnnotationenTableCreateCompanionBuilder,
      $$AnnotationenTableUpdateCompanionBuilder,
      (AnnotationenData, $$AnnotationenTableReferences),
      AnnotationenData,
      PrefetchHooks Function({bool stimmeId})
    >;
typedef $$KonfigurationEintraegeTableCreateCompanionBuilder =
    KonfigurationEintraegeCompanion Function({
      Value<int> id,
      required String ebene,
      required String schluessel,
      required String wert,
      Value<bool> istGesperrt,
    });
typedef $$KonfigurationEintraegeTableUpdateCompanionBuilder =
    KonfigurationEintraegeCompanion Function({
      Value<int> id,
      Value<String> ebene,
      Value<String> schluessel,
      Value<String> wert,
      Value<bool> istGesperrt,
    });

class $$KonfigurationEintraegeTableFilterComposer
    extends Composer<_$AppDatabase, $KonfigurationEintraegeTable> {
  $$KonfigurationEintraegeTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ebene => $composableBuilder(
    column: $table.ebene,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schluessel => $composableBuilder(
    column: $table.schluessel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wert => $composableBuilder(
    column: $table.wert,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get istGesperrt => $composableBuilder(
    column: $table.istGesperrt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KonfigurationEintraegeTableOrderingComposer
    extends Composer<_$AppDatabase, $KonfigurationEintraegeTable> {
  $$KonfigurationEintraegeTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ebene => $composableBuilder(
    column: $table.ebene,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schluessel => $composableBuilder(
    column: $table.schluessel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wert => $composableBuilder(
    column: $table.wert,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get istGesperrt => $composableBuilder(
    column: $table.istGesperrt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KonfigurationEintraegeTableAnnotationComposer
    extends Composer<_$AppDatabase, $KonfigurationEintraegeTable> {
  $$KonfigurationEintraegeTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ebene =>
      $composableBuilder(column: $table.ebene, builder: (column) => column);

  GeneratedColumn<String> get schluessel => $composableBuilder(
    column: $table.schluessel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wert =>
      $composableBuilder(column: $table.wert, builder: (column) => column);

  GeneratedColumn<bool> get istGesperrt => $composableBuilder(
    column: $table.istGesperrt,
    builder: (column) => column,
  );
}

class $$KonfigurationEintraegeTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KonfigurationEintraegeTable,
          KonfigurationEintraegeData,
          $$KonfigurationEintraegeTableFilterComposer,
          $$KonfigurationEintraegeTableOrderingComposer,
          $$KonfigurationEintraegeTableAnnotationComposer,
          $$KonfigurationEintraegeTableCreateCompanionBuilder,
          $$KonfigurationEintraegeTableUpdateCompanionBuilder,
          (
            KonfigurationEintraegeData,
            BaseReferences<
              _$AppDatabase,
              $KonfigurationEintraegeTable,
              KonfigurationEintraegeData
            >,
          ),
          KonfigurationEintraegeData,
          PrefetchHooks Function()
        > {
  $$KonfigurationEintraegeTableTableManager(
    _$AppDatabase db,
    $KonfigurationEintraegeTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KonfigurationEintraegeTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$KonfigurationEintraegeTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$KonfigurationEintraegeTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> ebene = const Value.absent(),
                Value<String> schluessel = const Value.absent(),
                Value<String> wert = const Value.absent(),
                Value<bool> istGesperrt = const Value.absent(),
              }) => KonfigurationEintraegeCompanion(
                id: id,
                ebene: ebene,
                schluessel: schluessel,
                wert: wert,
                istGesperrt: istGesperrt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String ebene,
                required String schluessel,
                required String wert,
                Value<bool> istGesperrt = const Value.absent(),
              }) => KonfigurationEintraegeCompanion.insert(
                id: id,
                ebene: ebene,
                schluessel: schluessel,
                wert: wert,
                istGesperrt: istGesperrt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KonfigurationEintraegeTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KonfigurationEintraegeTable,
      KonfigurationEintraegeData,
      $$KonfigurationEintraegeTableFilterComposer,
      $$KonfigurationEintraegeTableOrderingComposer,
      $$KonfigurationEintraegeTableAnnotationComposer,
      $$KonfigurationEintraegeTableCreateCompanionBuilder,
      $$KonfigurationEintraegeTableUpdateCompanionBuilder,
      (
        KonfigurationEintraegeData,
        BaseReferences<
          _$AppDatabase,
          $KonfigurationEintraegeTable,
          KonfigurationEintraegeData
        >,
      ),
      KonfigurationEintraegeData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotenTableTableManager get noten =>
      $$NotenTableTableManager(_db, _db.noten);
  $$StimmenTableTableManager get stimmen =>
      $$StimmenTableTableManager(_db, _db.stimmen);
  $$AnnotationenTableTableManager get annotationen =>
      $$AnnotationenTableTableManager(_db, _db.annotationen);
  $$KonfigurationEintraegeTableTableManager get konfigurationEintraege =>
      $$KonfigurationEintraegeTableTableManager(
        _db,
        _db.konfigurationEintraege,
      );
}
