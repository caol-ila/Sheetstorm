// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SheetMusicsTable extends SheetMusics with TableInfo<$SheetMusicsTable, SheetMusicsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SheetMusicsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titelMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _composerMeta = const VerificationMeta(
    'composer',
  );
  @override
  late final GeneratedColumn<String> composer = GeneratedColumn<String>(
    'composer',
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
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'lokaler_pfad',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOfflineAvailableMeta =
      const VerificationMeta('isOfflineAvailable');
  @override
  late final GeneratedColumn<bool> isOfflineAvailable = GeneratedColumn<bool>(
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    composer,
    genre,
    localPath,
    isOfflineAvailable,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SheetMusics';
  @override
  VerificationContext validateIntegrity(
    Insertable<SheetMusicsData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titelMeta,
        title.isAcceptableOrUnknown(data['title']!, _titelMeta),
      );
    } else if (isInserting) {
      context.missing(_titelMeta);
    }
    if (data.containsKey('composer')) {
      context.handle(
        _composerMeta,
        composer.isAcceptableOrUnknown(data['composer']!, _composerMeta),
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
        _localPathMeta,
        localPath.isAcceptableOrUnknown(
          data['lokaler_pfad']!,
          _localPathMeta,
        ),
      );
    }
    if (data.containsKey('ist_offline_verfuegbar')) {
      context.handle(
        _isOfflineAvailableMeta,
        isOfflineAvailable.isAcceptableOrUnknown(
          data['ist_offline_verfuegbar']!,
          _isOfflineAvailableMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(
          data['updated_at']!,
          _updatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SheetMusicsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SheetMusicsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      composer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}composer'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lokaler_pfad'],
      ),
      isOfflineAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ist_offline_verfuegbar'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}erstellt_am'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}aktualisiert_am'],
      )!,
    );
  }

  @override
  $SheetMusicsTable createAlias(String alias) {
    return $SheetMusicsTable(attachedDatabase, alias);
  }
}

class SheetMusicsData extends DataClass implements Insertable<SheetMusicsData> {
  final int id;
  final String title;
  final String? composer;
  final String? genre;
  final String? localPath;
  final bool isOfflineAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SheetMusicsData({
    required this.id,
    required this.title,
    this.composer,
    this.genre,
    this.localPath,
    required this.isOfflineAvailable,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || composer != null) {
      map['composer'] = Variable<String>(composer);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || localPath != null) {
      map['lokaler_pfad'] = Variable<String>(localPath);
    }
    map['ist_offline_verfuegbar'] = Variable<bool>(isOfflineAvailable);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SheetMusicsCompanion toCompanion(bool nullToAbsent) {
    return SheetMusicsCompanion(
      id: Value(id),
      title: Value(title),
      composer: composer == null && nullToAbsent
          ? const Value.absent()
          : Value(composer),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      isOfflineAvailable: Value(isOfflineAvailable),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SheetMusicsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SheetMusicsData(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      composer: serializer.fromJson<String?>(json['composer']),
      genre: serializer.fromJson<String?>(json['genre']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      isOfflineAvailable: serializer.fromJson<bool>(
        json['isOfflineAvailable'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'composer': serializer.toJson<String?>(composer),
      'genre': serializer.toJson<String?>(genre),
      'localPath': serializer.toJson<String?>(localPath),
      'isOfflineAvailable': serializer.toJson<bool>(isOfflineAvailable),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SheetMusicsData copyWith({
    int? id,
    String? title,
    Value<String?> composer = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    bool? isOfflineAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SheetMusicsData(
    id: id ?? this.id,
    title: title ?? this.title,
    composer: composer.present ? composer.value : this.composer,
    genre: genre.present ? genre.value : this.genre,
    localPath: localPath.present ? localPath.value : this.localPath,
    isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SheetMusicsData copyWithCompanion(SheetMusicsCompanion data) {
    return SheetMusicsData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      composer: data.composer.present ? data.composer.value : this.composer,
      genre: data.genre.present ? data.genre.value : this.genre,
      localPath: data.localPath.present
          ? data.localPath.value
          : this.localPath,
      isOfflineAvailable: data.isOfflineAvailable.present
          ? data.isOfflineAvailable.value
          : this.isOfflineAvailable,
      createdAt: data.createdAt.present
          ? data.createdAt.value
          : this.createdAt,
      updatedAt: data.updatedAt.present
          ? data.updatedAt.value
          : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SheetMusicsData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('genre: $genre, ')
          ..write('localPath: $localPath, ')
          ..write('isOfflineAvailable: $isOfflineAvailable, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    composer,
    genre,
    localPath,
    isOfflineAvailable,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SheetMusicsData &&
          other.id == this.id &&
          other.title == this.title &&
          other.composer == this.composer &&
          other.genre == this.genre &&
          other.localPath == this.localPath &&
          other.isOfflineAvailable == this.isOfflineAvailable &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SheetMusicsCompanion extends UpdateCompanion<SheetMusicsData> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> composer;
  final Value<String?> genre;
  final Value<String?> localPath;
  final Value<bool> isOfflineAvailable;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SheetMusicsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.composer = const Value.absent(),
    this.genre = const Value.absent(),
    this.localPath = const Value.absent(),
    this.isOfflineAvailable = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SheetMusicsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.composer = const Value.absent(),
    this.genre = const Value.absent(),
    this.localPath = const Value.absent(),
    this.isOfflineAvailable = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<SheetMusicsData> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? composer,
    Expression<String>? genre,
    Expression<String>? localPath,
    Expression<bool>? isOfflineAvailable,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (composer != null) 'composer': composer,
      if (genre != null) 'genre': genre,
      if (localPath != null) 'lokaler_pfad': localPath,
      if (isOfflineAvailable != null)
        'ist_offline_verfuegbar': isOfflineAvailable,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SheetMusicsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? composer,
    Value<String?>? genre,
    Value<String?>? localPath,
    Value<bool>? isOfflineAvailable,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SheetMusicsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      genre: genre ?? this.genre,
      localPath: localPath ?? this.localPath,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (composer.present) {
      map['composer'] = Variable<String>(composer.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (localPath.present) {
      map['lokaler_pfad'] = Variable<String>(localPath.value);
    }
    if (isOfflineAvailable.present) {
      map['ist_offline_verfuegbar'] = Variable<bool>(
        isOfflineAvailable.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SheetMusicsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('genre: $genre, ')
          ..write('localPath: $localPath, ')
          ..write('isOfflineAvailable: $isOfflineAvailable, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $VoicesTable extends Voices with TableInfo<$VoicesTable, VoicesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoicesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sheetIdMeta = const VerificationMeta(
    'sheetId',
  );
  @override
  late final GeneratedColumn<int> sheetId = GeneratedColumn<int>(
    'SheetMusics_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES SheetMusics (id)',
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
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
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
    sheetId,
    name,
    instrument,
    pageCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voices';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoicesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('SheetMusics_id')) {
      context.handle(
        _sheetIdMeta,
        sheetId.isAcceptableOrUnknown(data['SheetMusics_id']!, _sheetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sheetIdMeta);
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
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(
          data['seiten_anzahl']!,
          _pageCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoicesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoicesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sheetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}SheetMusics_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      instrument: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrument'],
      ),
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seiten_anzahl'],
      )!,
    );
  }

  @override
  $VoicesTable createAlias(String alias) {
    return $VoicesTable(attachedDatabase, alias);
  }
}

class VoicesData extends DataClass implements Insertable<VoicesData> {
  final int id;
  final int sheetId;
  final String name;
  final String? instrument;
  final int pageCount;
  const VoicesData({
    required this.id,
    required this.sheetId,
    required this.name,
    this.instrument,
    required this.pageCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['SheetMusics_id'] = Variable<int>(sheetId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || instrument != null) {
      map['instrument'] = Variable<String>(instrument);
    }
    map['seiten_anzahl'] = Variable<int>(pageCount);
    return map;
  }

  VoicesCompanion toCompanion(bool nullToAbsent) {
    return VoicesCompanion(
      id: Value(id),
      sheetId: Value(sheetId),
      name: Value(name),
      instrument: instrument == null && nullToAbsent
          ? const Value.absent()
          : Value(instrument),
      pageCount: Value(pageCount),
    );
  }

  factory VoicesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoicesData(
      id: serializer.fromJson<int>(json['id']),
      sheetId: serializer.fromJson<int>(json['sheetId']),
      name: serializer.fromJson<String>(json['name']),
      instrument: serializer.fromJson<String?>(json['instrument']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sheetId': serializer.toJson<int>(sheetId),
      'name': serializer.toJson<String>(name),
      'instrument': serializer.toJson<String?>(instrument),
      'pageCount': serializer.toJson<int>(pageCount),
    };
  }

  VoicesData copyWith({
    int? id,
    int? sheetId,
    String? name,
    Value<String?> instrument = const Value.absent(),
    int? pageCount,
  }) => VoicesData(
    id: id ?? this.id,
    sheetId: sheetId ?? this.sheetId,
    name: name ?? this.name,
    instrument: instrument.present ? instrument.value : this.instrument,
    pageCount: pageCount ?? this.pageCount,
  );
  VoicesData copyWithCompanion(VoicesCompanion data) {
    return VoicesData(
      id: data.id.present ? data.id.value : this.id,
      sheetId: data.sheetId.present ? data.sheetId.value : this.sheetId,
      name: data.name.present ? data.name.value : this.name,
      instrument: data.instrument.present
          ? data.instrument.value
          : this.instrument,
      pageCount: data.pageCount.present
          ? data.pageCount.value
          : this.pageCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoicesData(')
          ..write('id: $id, ')
          ..write('sheetId: $sheetId, ')
          ..write('name: $name, ')
          ..write('instrument: $instrument, ')
          ..write('pageCount: $pageCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sheetId, name, instrument, pageCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoicesData &&
          other.id == this.id &&
          other.sheetId == this.sheetId &&
          other.name == this.name &&
          other.instrument == this.instrument &&
          other.pageCount == this.pageCount);
}

class VoicesCompanion extends UpdateCompanion<VoicesData> {
  final Value<int> id;
  final Value<int> sheetId;
  final Value<String> name;
  final Value<String?> instrument;
  final Value<int> pageCount;
  const VoicesCompanion({
    this.id = const Value.absent(),
    this.sheetId = const Value.absent(),
    this.name = const Value.absent(),
    this.instrument = const Value.absent(),
    this.pageCount = const Value.absent(),
  });
  VoicesCompanion.insert({
    this.id = const Value.absent(),
    required int sheetId,
    required String name,
    this.instrument = const Value.absent(),
    this.pageCount = const Value.absent(),
  }) : sheetId = Value(sheetId),
       name = Value(name);
  static Insertable<VoicesData> custom({
    Expression<int>? id,
    Expression<int>? sheetId,
    Expression<String>? name,
    Expression<String>? instrument,
    Expression<int>? pageCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sheetId != null) 'SheetMusics_id': sheetId,
      if (name != null) 'name': name,
      if (instrument != null) 'instrument': instrument,
      if (pageCount != null) 'seiten_anzahl': pageCount,
    });
  }

  VoicesCompanion copyWith({
    Value<int>? id,
    Value<int>? sheetId,
    Value<String>? name,
    Value<String?>? instrument,
    Value<int>? pageCount,
  }) {
    return VoicesCompanion(
      id: id ?? this.id,
      sheetId: sheetId ?? this.sheetId,
      name: name ?? this.name,
      instrument: instrument ?? this.instrument,
      pageCount: pageCount ?? this.pageCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sheetId.present) {
      map['SheetMusics_id'] = Variable<int>(sheetId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (instrument.present) {
      map['instrument'] = Variable<String>(instrument.value);
    }
    if (pageCount.present) {
      map['seiten_anzahl'] = Variable<int>(pageCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoicesCompanion(')
          ..write('id: $id, ')
          ..write('sheetId: $sheetId, ')
          ..write('name: $name, ')
          ..write('instrument: $instrument, ')
          ..write('pageCount: $pageCount')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations
    with TableInfo<$AnnotationsTable, AnnotationsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _voiceIdMeta = const VerificationMeta(
    'voiceId',
  );
  @override
  late final GeneratedColumn<int> voiceId = GeneratedColumn<int>(
    'voice_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES voices (id)',
    ),
  );
  static const VerificationMeta _ebeneMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xRelativeMeta = const VerificationMeta(
    'xRelative',
  );
  @override
  late final GeneratedColumn<double> xRelative = GeneratedColumn<double>(
    'x_relativ',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yRelativeMeta = const VerificationMeta(
    'yRelative',
  );
  @override
  late final GeneratedColumn<double> yRelative = GeneratedColumn<double>(
    'y_relativ',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seiteMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<double> page = GeneratedColumn<double>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _svgDataMeta = const VerificationMeta(
    'svgData',
  );
  @override
  late final GeneratedColumn<String> svgData = GeneratedColumn<String>(
    'svg_daten',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    voiceId,
    level,
    xRelative,
    yRelative,
    page,
    svgData,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnnotationsData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('voice_id')) {
      context.handle(
        _voiceIdMeta,
        voiceId.isAcceptableOrUnknown(data['voice_id']!, _voiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_voiceIdMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _ebeneMeta,
        level.isAcceptableOrUnknown(data['level']!, _ebeneMeta),
      );
    } else if (isInserting) {
      context.missing(_ebeneMeta);
    }
    if (data.containsKey('x_relativ')) {
      context.handle(
        _xRelativeMeta,
        xRelative.isAcceptableOrUnknown(data['x_relativ']!, _xRelativeMeta),
      );
    } else if (isInserting) {
      context.missing(_xRelativeMeta);
    }
    if (data.containsKey('y_relativ')) {
      context.handle(
        _yRelativeMeta,
        yRelative.isAcceptableOrUnknown(data['y_relativ']!, _yRelativeMeta),
      );
    } else if (isInserting) {
      context.missing(_yRelativeMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _seiteMeta,
        page.isAcceptableOrUnknown(data['page']!, _seiteMeta),
      );
    } else if (isInserting) {
      context.missing(_seiteMeta);
    }
    if (data.containsKey('svg_daten')) {
      context.handle(
        _svgDataMeta,
        svgData.isAcceptableOrUnknown(data['svg_daten']!, _svgDataMeta),
      );
    } else if (isInserting) {
      context.missing(_svgDataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnnotationsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnotationsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      voiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stimme_id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      xRelative: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x_relativ'],
      )!,
      yRelative: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y_relativ'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}page'],
      )!,
      svgData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}svg_daten'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}erstellt_am'],
      )!,
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }
}

class AnnotationsData extends DataClass
    implements Insertable<AnnotationsData> {
  final int id;
  final int voiceId;
  final String level;
  final double xRelative;
  final double yRelative;
  final double page;
  final String svgData;
  final DateTime createdAt;
  const AnnotationsData({
    required this.id,
    required this.voiceId,
    required this.level,
    required this.xRelative,
    required this.yRelative,
    required this.page,
    required this.svgData,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['voice_id'] = Variable<int>(voiceId);
    map['level'] = Variable<String>(level);
    map['x_relativ'] = Variable<double>(xRelative);
    map['y_relativ'] = Variable<double>(yRelative);
    map['page'] = Variable<double>(page);
    map['svg_daten'] = Variable<String>(svgData);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      id: Value(id),
      voiceId: Value(voiceId),
      level: Value(level),
      xRelative: Value(xRelative),
      yRelative: Value(yRelative),
      page: Value(page),
      svgData: Value(svgData),
      createdAt: Value(createdAt),
    );
  }

  factory AnnotationsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnotationsData(
      id: serializer.fromJson<int>(json['id']),
      voiceId: serializer.fromJson<int>(json['voiceId']),
      level: serializer.fromJson<String>(json['level']),
      xRelative: serializer.fromJson<double>(json['xRelative']),
      yRelative: serializer.fromJson<double>(json['yRelative']),
      page: serializer.fromJson<double>(json['page']),
      svgData: serializer.fromJson<String>(json['svgData']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'voiceId': serializer.toJson<int>(voiceId),
      'level': serializer.toJson<String>(level),
      'xRelative': serializer.toJson<double>(xRelative),
      'yRelative': serializer.toJson<double>(yRelative),
      'page': serializer.toJson<double>(page),
      'svgData': serializer.toJson<String>(svgData),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AnnotationsData copyWith({
    int? id,
    int? voiceId,
    String? level,
    double? xRelative,
    double? yRelative,
    double? page,
    String? svgData,
    DateTime? createdAt,
  }) => AnnotationsData(
    id: id ?? this.id,
    voiceId: voiceId ?? this.voiceId,
    level: level ?? this.level,
    xRelative: xRelative ?? this.xRelative,
    yRelative: yRelative ?? this.yRelative,
    page: page ?? this.page,
    svgData: svgData ?? this.svgData,
    createdAt: createdAt ?? this.createdAt,
  );
  AnnotationsData copyWithCompanion(AnnotationsCompanion data) {
    return AnnotationsData(
      id: data.id.present ? data.id.value : this.id,
      voiceId: data.voiceId.present ? data.voiceId.value : this.voiceId,
      level: data.level.present ? data.level.value : this.level,
      xRelative: data.xRelative.present ? data.xRelative.value : this.xRelative,
      yRelative: data.yRelative.present ? data.yRelative.value : this.yRelative,
      page: data.page.present ? data.page.value : this.page,
      svgData: data.svgData.present ? data.svgData.value : this.svgData,
      createdAt: data.createdAt.present
          ? data.createdAt.value
          : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsData(')
          ..write('id: $id, ')
          ..write('voiceId: $voiceId, ')
          ..write('level: $level, ')
          ..write('xRelative: $xRelative, ')
          ..write('yRelative: $yRelative, ')
          ..write('page: $page, ')
          ..write('svgData: $svgData, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    voiceId,
    level,
    xRelative,
    yRelative,
    page,
    svgData,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnotationsData &&
          other.id == this.id &&
          other.voiceId == this.voiceId &&
          other.level == this.level &&
          other.xRelative == this.xRelative &&
          other.yRelative == this.yRelative &&
          other.page == this.page &&
          other.svgData == this.svgData &&
          other.createdAt == this.createdAt);
}

class AnnotationsCompanion extends UpdateCompanion<AnnotationsData> {
  final Value<int> id;
  final Value<int> voiceId;
  final Value<String> level;
  final Value<double> xRelative;
  final Value<double> yRelative;
  final Value<double> page;
  final Value<String> svgData;
  final Value<DateTime> createdAt;
  const AnnotationsCompanion({
    this.id = const Value.absent(),
    this.voiceId = const Value.absent(),
    this.level = const Value.absent(),
    this.xRelative = const Value.absent(),
    this.yRelative = const Value.absent(),
    this.page = const Value.absent(),
    this.svgData = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    this.id = const Value.absent(),
    required int voiceId,
    required String level,
    required double xRelative,
    required double yRelative,
    required double page,
    required String svgData,
    this.createdAt = const Value.absent(),
  }) : voiceId = Value(voiceId),
       level = Value(level),
       xRelative = Value(xRelative),
       yRelative = Value(yRelative),
       page = Value(page),
       svgData = Value(svgData);
  static Insertable<AnnotationsData> custom({
    Expression<int>? id,
    Expression<int>? voiceId,
    Expression<String>? level,
    Expression<double>? xRelative,
    Expression<double>? yRelative,
    Expression<double>? page,
    Expression<String>? svgData,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (voiceId != null) 'voice_id': voiceId,
      if (level != null) 'level': level,
      if (xRelative != null) 'x_relativ': xRelative,
      if (yRelative != null) 'y_relativ': yRelative,
      if (page != null) 'page': page,
      if (svgData != null) 'svg_daten': svgData,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AnnotationsCompanion copyWith({
    Value<int>? id,
    Value<int>? voiceId,
    Value<String>? level,
    Value<double>? xRelative,
    Value<double>? yRelative,
    Value<double>? page,
    Value<String>? svgData,
    Value<DateTime>? createdAt,
  }) {
    return AnnotationsCompanion(
      id: id ?? this.id,
      voiceId: voiceId ?? this.voiceId,
      level: level ?? this.level,
      xRelative: xRelative ?? this.xRelative,
      yRelative: yRelative ?? this.yRelative,
      page: page ?? this.page,
      svgData: svgData ?? this.svgData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (voiceId.present) {
      map['voice_id'] = Variable<int>(voiceId.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (xRelative.present) {
      map['x_relativ'] = Variable<double>(xRelative.value);
    }
    if (yRelative.present) {
      map['y_relativ'] = Variable<double>(yRelative.value);
    }
    if (page.present) {
      map['page'] = Variable<double>(page.value);
    }
    if (svgData.present) {
      map['svg_daten'] = Variable<String>(svgData.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('voiceId: $voiceId, ')
          ..write('level: $level, ')
          ..write('xRelative: $xRelative, ')
          ..write('yRelative: $yRelative, ')
          ..write('page: $page, ')
          ..write('svgData: $svgData, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ConfigEntriesTable extends ConfigEntries
    with TableInfo<$ConfigEntriesTable, ConfigEntriesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _ebeneMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta(
    'key',
  );
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wertMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
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
    level,
    key,
    value,
    isLocked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'konfiguration_eintraege';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfigEntriesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
        _ebeneMeta,
        level.isAcceptableOrUnknown(data['level']!, _ebeneMeta),
      );
    } else if (isInserting) {
      context.missing(_ebeneMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _wertMeta,
        value.isAcceptableOrUnknown(data['value']!, _wertMeta),
      );
    } else if (isInserting) {
      context.missing(_wertMeta);
    }
    if (data.containsKey('ist_gesperrt')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(
          data['ist_gesperrt']!,
          _isLockedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfigEntriesData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigEntriesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ist_gesperrt'],
      )!,
    );
  }

  @override
  $ConfigEntriesTable createAlias(String alias) {
    return $ConfigEntriesTable(attachedDatabase, alias);
  }
}

class ConfigEntriesData extends DataClass
    implements Insertable<ConfigEntriesData> {
  final int id;
  final String level;
  final String key;
  final String value;
  final bool isLocked;
  const ConfigEntriesData({
    required this.id,
    required this.level,
    required this.key,
    required this.value,
    required this.isLocked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['level'] = Variable<String>(level);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['ist_gesperrt'] = Variable<bool>(isLocked);
    return map;
  }

  ConfigEntriesCompanion toCompanion(bool nullToAbsent) {
    return ConfigEntriesCompanion(
      id: Value(id),
      level: Value(level),
      key: Value(key),
      value: Value(value),
      isLocked: Value(isLocked),
    );
  }

  factory ConfigEntriesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigEntriesData(
      id: serializer.fromJson<int>(json['id']),
      level: serializer.fromJson<String>(json['level']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'level': serializer.toJson<String>(level),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'isLocked': serializer.toJson<bool>(isLocked),
    };
  }

  ConfigEntriesData copyWith({
    int? id,
    String? level,
    String? key,
    String? value,
    bool? isLocked,
  }) => ConfigEntriesData(
    id: id ?? this.id,
    level: level ?? this.level,
    key: key ?? this.key,
    value: value ?? this.value,
    isLocked: isLocked ?? this.isLocked,
  );
  ConfigEntriesData copyWithCompanion(
    ConfigEntriesCompanion data,
  ) {
    return ConfigEntriesData(
      id: data.id.present ? data.id.value : this.id,
      level: data.level.present ? data.level.value : this.level,
      key: data.key.present
          ? data.key.value
          : this.key,
      value: data.value.present ? data.value.value : this.value,
      isLocked: data.isLocked.present
          ? data.isLocked.value
          : this.isLocked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigEntriesData(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('isLocked: $isLocked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, level, key, value, isLocked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigEntriesData &&
          other.id == this.id &&
          other.level == this.level &&
          other.key == this.key &&
          other.value == this.value &&
          other.isLocked == this.isLocked);
}

class ConfigEntriesCompanion
    extends UpdateCompanion<ConfigEntriesData> {
  final Value<int> id;
  final Value<String> level;
  final Value<String> key;
  final Value<String> value;
  final Value<bool> isLocked;
  const ConfigEntriesCompanion({
    this.id = const Value.absent(),
    this.level = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.isLocked = const Value.absent(),
  });
  ConfigEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String level,
    required String key,
    required String value,
    this.isLocked = const Value.absent(),
  }) : level = Value(level),
       key = Value(key),
       value = Value(value);
  static Insertable<ConfigEntriesData> custom({
    Expression<int>? id,
    Expression<String>? level,
    Expression<String>? key,
    Expression<String>? value,
    Expression<bool>? isLocked,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (level != null) 'level': level,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (isLocked != null) 'ist_gesperrt': isLocked,
    });
  }

  ConfigEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? level,
    Value<String>? key,
    Value<String>? value,
    Value<bool>? isLocked,
  }) {
    return ConfigEntriesCompanion(
      id: id ?? this.id,
      level: level ?? this.level,
      key: key ?? this.key,
      value: value ?? this.value,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (isLocked.present) {
      map['ist_gesperrt'] = Variable<bool>(isLocked.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigEntriesCompanion(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('isLocked: $isLocked')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SheetMusicsTable SheetMusics = $SheetMusicsTable(this);
  late final $VoicesTable voices = $VoicesTable(this);
  late final $AnnotationsTable Annotations = $AnnotationsTable(this);
  late final $ConfigEntriesTable ConfigEntries =
      $ConfigEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    SheetMusics,
    voices,
    Annotations,
    ConfigEntries,
  ];
}

typedef $$SheetMusicsTableCreateCompanionBuilder =
    SheetMusicsCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> composer,
      Value<String?> genre,
      Value<String?> localPath,
      Value<bool> isOfflineAvailable,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SheetMusicsTableUpdateCompanionBuilder =
    SheetMusicsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> composer,
      Value<String?> genre,
      Value<String?> localPath,
      Value<bool> isOfflineAvailable,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SheetMusicsTableReferences
    extends BaseReferences<_$AppDatabase, $SheetMusicsTable, SheetMusicsData> {
  $$SheetMusicsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VoicesTable, List<VoicesData>>
  _VoicesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.voices,
    aliasName: $_aliasNameGenerator(db.SheetMusics.id, db.voices.sheetId),
  );

  $$VoicesTableProcessedTableManager get VoicesRefs {
    final manager = $$VoicesTableTableManager(
      $_db,
      $_db.voices,
    ).filter((f) => f.sheetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_VoicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SheetMusicsTableFilterComposer extends Composer<_$AppDatabase, $SheetMusicsTable> {
  $$SheetMusicsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOfflineAvailable => $composableBuilder(
    column: $table.isOfflineAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> VoicesRefs(
    Expression<bool> Function($$VoicesTableFilterComposer f) f,
  ) {
    final $$VoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.voices,
      getReferencedColumn: (t) => t.sheetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoicesTableFilterComposer(
            $db: $db,
            $table: $db.voices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SheetMusicsTableOrderingComposer
    extends Composer<_$AppDatabase, $SheetMusicsTable> {
  $$SheetMusicsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOfflineAvailable => $composableBuilder(
    column: $table.isOfflineAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SheetMusicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SheetMusicsTable> {
  $$SheetMusicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get composer =>
      $composableBuilder(column: $table.composer, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOfflineAvailable => $composableBuilder(
    column: $table.isOfflineAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => column,
  );

  Expression<T> VoicesRefs<T extends Object>(
    Expression<T> Function($$VoicesTableAnnotationComposer a) f,
  ) {
    final $$VoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.voices,
      getReferencedColumn: (t) => t.sheetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.voices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SheetMusicsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SheetMusicsTable,
          SheetMusicsData,
          $$SheetMusicsTableFilterComposer,
          $$SheetMusicsTableOrderingComposer,
          $$SheetMusicsTableAnnotationComposer,
          $$SheetMusicsTableCreateCompanionBuilder,
          $$SheetMusicsTableUpdateCompanionBuilder,
          (SheetMusicsData, $$SheetMusicsTableReferences),
          SheetMusicsData,
          PrefetchHooks Function({bool VoicesRefs})
        > {
  $$SheetMusicsTableTableManager(_$AppDatabase db, $SheetMusicsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SheetMusicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SheetMusicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SheetMusicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> composer = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<bool> isOfflineAvailable = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SheetMusicsCompanion(
                id: id,
                title: title,
                composer: composer,
                genre: genre,
                localPath: localPath,
                isOfflineAvailable: isOfflineAvailable,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> composer = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<bool> isOfflineAvailable = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SheetMusicsCompanion.insert(
                id: id,
                title: title,
                composer: composer,
                genre: genre,
                localPath: localPath,
                isOfflineAvailable: isOfflineAvailable,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SheetMusicsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({VoicesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (VoicesRefs) db.voices],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (VoicesRefs)
                    await $_getPrefetchedData<
                      SheetMusicsData,
                      $SheetMusicsTable,
                      VoicesData
                    >(
                      currentTable: table,
                      referencedTable: $$SheetMusicsTableReferences._VoicesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$SheetMusicsTableReferences(db, table, p0).VoicesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sheetId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SheetMusicsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SheetMusicsTable,
      SheetMusicsData,
      $$SheetMusicsTableFilterComposer,
      $$SheetMusicsTableOrderingComposer,
      $$SheetMusicsTableAnnotationComposer,
      $$SheetMusicsTableCreateCompanionBuilder,
      $$SheetMusicsTableUpdateCompanionBuilder,
      (SheetMusicsData, $$SheetMusicsTableReferences),
      SheetMusicsData,
      PrefetchHooks Function({bool VoicesRefs})
    >;
typedef $$VoicesTableCreateCompanionBuilder =
    VoicesCompanion Function({
      Value<int> id,
      required int sheetId,
      required String name,
      Value<String?> instrument,
      Value<int> pageCount,
    });
typedef $$VoicesTableUpdateCompanionBuilder =
    VoicesCompanion Function({
      Value<int> id,
      Value<int> sheetId,
      Value<String> name,
      Value<String?> instrument,
      Value<int> pageCount,
    });

final class $$VoicesTableReferences
    extends BaseReferences<_$AppDatabase, $VoicesTable, VoicesData> {
  $$VoicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SheetMusicsTable _sheetIdTable(_$AppDatabase db) => db.SheetMusics.createAlias(
    $_aliasNameGenerator(db.voices.sheetId, db.SheetMusics.id),
  );

  $$SheetMusicsTableProcessedTableManager get sheetId {
    final $_column = $_itemColumn<int>('SheetMusics_id')!;

    final manager = $$SheetMusicsTableTableManager(
      $_db,
      $_db.SheetMusics,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sheetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AnnotationsTable, List<AnnotationsData>>
  _AnnotationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.Annotations,
    aliasName: $_aliasNameGenerator(db.voices.id, db.Annotations.voiceId),
  );

  $$AnnotationsTableProcessedTableManager get AnnotationsRefs {
    final manager = $$AnnotationsTableTableManager(
      $_db,
      $_db.Annotations,
    ).filter((f) => f.voiceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_AnnotationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VoicesTableFilterComposer
    extends Composer<_$AppDatabase, $VoicesTable> {
  $$VoicesTableFilterComposer({
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

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  $$SheetMusicsTableFilterComposer get sheetId {
    final $$SheetMusicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.SheetMusics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetMusicsTableFilterComposer(
            $db: $db,
            $table: $db.SheetMusics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> AnnotationsRefs(
    Expression<bool> Function($$AnnotationsTableFilterComposer f) f,
  ) {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.Annotations,
      getReferencedColumn: (t) => t.voiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.Annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $VoicesTable> {
  $$VoicesTableOrderingComposer({
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

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$SheetMusicsTableOrderingComposer get sheetId {
    final $$SheetMusicsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.SheetMusics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetMusicsTableOrderingComposer(
            $db: $db,
            $table: $db.SheetMusics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VoicesTable> {
  $$VoicesTableAnnotationComposer({
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

  GeneratedColumn<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => column,
  );

  $$SheetMusicsTableAnnotationComposer get sheetId {
    final $$SheetMusicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.SheetMusics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetMusicsTableAnnotationComposer(
            $db: $db,
            $table: $db.SheetMusics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> AnnotationsRefs<T extends Object>(
    Expression<T> Function($$AnnotationsTableAnnotationComposer a) f,
  ) {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.Annotations,
      getReferencedColumn: (t) => t.voiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.Annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VoicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VoicesTable,
          VoicesData,
          $$VoicesTableFilterComposer,
          $$VoicesTableOrderingComposer,
          $$VoicesTableAnnotationComposer,
          $$VoicesTableCreateCompanionBuilder,
          $$VoicesTableUpdateCompanionBuilder,
          (VoicesData, $$VoicesTableReferences),
          VoicesData,
          PrefetchHooks Function({bool sheetId, bool AnnotationsRefs})
        > {
  $$VoicesTableTableManager(_$AppDatabase db, $VoicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sheetId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> instrument = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
              }) => VoicesCompanion(
                id: id,
                sheetId: sheetId,
                name: name,
                instrument: instrument,
                pageCount: pageCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sheetId,
                required String name,
                Value<String?> instrument = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
              }) => VoicesCompanion.insert(
                id: id,
                sheetId: sheetId,
                name: name,
                instrument: instrument,
                pageCount: pageCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VoicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sheetId = false, AnnotationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (AnnotationsRefs) db.Annotations],
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
                    if (sheetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sheetId,
                                referencedTable: $$VoicesTableReferences
                                    ._sheetIdTable(db),
                                referencedColumn: $$VoicesTableReferences
                                    ._sheetIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (AnnotationsRefs)
                    await $_getPrefetchedData<
                      VoicesData,
                      $VoicesTable,
                      AnnotationsData
                    >(
                      currentTable: table,
                      referencedTable: $$VoicesTableReferences
                          ._AnnotationsRefsTable(db),
                      managerFromTypedResult: (p0) => $$VoicesTableReferences(
                        db,
                        table,
                        p0,
                      ).AnnotationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.voiceId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$VoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VoicesTable,
      VoicesData,
      $$VoicesTableFilterComposer,
      $$VoicesTableOrderingComposer,
      $$VoicesTableAnnotationComposer,
      $$VoicesTableCreateCompanionBuilder,
      $$VoicesTableUpdateCompanionBuilder,
      (VoicesData, $$VoicesTableReferences),
      VoicesData,
      PrefetchHooks Function({bool sheetId, bool AnnotationsRefs})
    >;
typedef $$AnnotationsTableCreateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<int> id,
      required int voiceId,
      required String level,
      required double xRelative,
      required double yRelative,
      required double page,
      required String svgData,
      Value<DateTime> createdAt,
    });
typedef $$AnnotationsTableUpdateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<int> id,
      Value<int> voiceId,
      Value<String> level,
      Value<double> xRelative,
      Value<double> yRelative,
      Value<double> page,
      Value<String> svgData,
      Value<DateTime> createdAt,
    });

final class $$AnnotationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AnnotationsTable, AnnotationsData> {
  $$AnnotationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VoicesTable _voiceIdTable(_$AppDatabase db) =>
      db.voices.createAlias(
        $_aliasNameGenerator(db.Annotations.voiceId, db.voices.id),
      );

  $$VoicesTableProcessedTableManager get voiceId {
    final $_column = $_itemColumn<int>('voice_id')!;

    final manager = $$VoicesTableTableManager(
      $_db,
      $_db.voices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_voiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
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

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get xRelative => $composableBuilder(
    column: $table.xRelative,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get yRelative => $composableBuilder(
    column: $table.yRelative,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get svgData => $composableBuilder(
    column: $table.svgData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VoicesTableFilterComposer get voiceId {
    final $$VoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.voiceId,
      referencedTable: $db.voices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoicesTableFilterComposer(
            $db: $db,
            $table: $db.voices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
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

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get xRelative => $composableBuilder(
    column: $table.xRelative,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get yRelative => $composableBuilder(
    column: $table.yRelative,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get svgData => $composableBuilder(
    column: $table.svgData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VoicesTableOrderingComposer get voiceId {
    final $$VoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.voiceId,
      referencedTable: $db.voices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoicesTableOrderingComposer(
            $db: $db,
            $table: $db.voices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<double> get xRelative =>
      $composableBuilder(column: $table.xRelative, builder: (column) => column);

  GeneratedColumn<double> get yRelative =>
      $composableBuilder(column: $table.yRelative, builder: (column) => column);

  GeneratedColumn<double> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get svgData =>
      $composableBuilder(column: $table.svgData, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => column,
  );

  $$VoicesTableAnnotationComposer get voiceId {
    final $$VoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.voiceId,
      referencedTable: $db.voices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.voices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationsTable,
          AnnotationsData,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (AnnotationsData, $$AnnotationsTableReferences),
          AnnotationsData,
          PrefetchHooks Function({bool voiceId})
        > {
  $$AnnotationsTableTableManager(_$AppDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> voiceId = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<double> xRelative = const Value.absent(),
                Value<double> yRelative = const Value.absent(),
                Value<double> page = const Value.absent(),
                Value<String> svgData = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AnnotationsCompanion(
                id: id,
                voiceId: voiceId,
                level: level,
                xRelative: xRelative,
                yRelative: yRelative,
                page: page,
                svgData: svgData,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int voiceId,
                required String level,
                required double xRelative,
                required double yRelative,
                required double page,
                required String svgData,
                Value<DateTime> createdAt = const Value.absent(),
              }) => AnnotationsCompanion.insert(
                id: id,
                voiceId: voiceId,
                level: level,
                xRelative: xRelative,
                yRelative: yRelative,
                page: page,
                svgData: svgData,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnnotationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({voiceId = false}) {
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
                    if (voiceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.voiceId,
                                referencedTable: $$AnnotationsTableReferences
                                    ._voiceIdTable(db),
                                referencedColumn: $$AnnotationsTableReferences
                                    ._voiceIdTable(db)
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

typedef $$AnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationsTable,
      AnnotationsData,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (AnnotationsData, $$AnnotationsTableReferences),
      AnnotationsData,
      PrefetchHooks Function({bool voiceId})
    >;
typedef $$ConfigEntriesTableCreateCompanionBuilder =
    ConfigEntriesCompanion Function({
      Value<int> id,
      required String level,
      required String key,
      required String value,
      Value<bool> isLocked,
    });
typedef $$ConfigEntriesTableUpdateCompanionBuilder =
    ConfigEntriesCompanion Function({
      Value<int> id,
      Value<String> level,
      Value<String> key,
      Value<String> value,
      Value<bool> isLocked,
    });

class $$ConfigEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigEntriesTable> {
  $$ConfigEntriesTableFilterComposer({
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

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfigEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigEntriesTable> {
  $$ConfigEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfigEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigEntriesTable> {
  $$ConfigEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => column,
  );

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => column,
  );
}

class $$ConfigEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigEntriesTable,
          ConfigEntriesData,
          $$ConfigEntriesTableFilterComposer,
          $$ConfigEntriesTableOrderingComposer,
          $$ConfigEntriesTableAnnotationComposer,
          $$ConfigEntriesTableCreateCompanionBuilder,
          $$ConfigEntriesTableUpdateCompanionBuilder,
          (
            ConfigEntriesData,
            BaseReferences<
              _$AppDatabase,
              $ConfigEntriesTable,
              ConfigEntriesData
            >,
          ),
          ConfigEntriesData,
          PrefetchHooks Function()
        > {
  $$ConfigEntriesTableTableManager(
    _$AppDatabase db,
    $ConfigEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ConfigEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConfigEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
              }) => ConfigEntriesCompanion(
                id: id,
                level: level,
                key: key,
                value: value,
                isLocked: isLocked,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String level,
                required String key,
                required String value,
                Value<bool> isLocked = const Value.absent(),
              }) => ConfigEntriesCompanion.insert(
                id: id,
                level: level,
                key: key,
                value: value,
                isLocked: isLocked,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfigEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfigEntriesTable,
      ConfigEntriesData,
      $$ConfigEntriesTableFilterComposer,
      $$ConfigEntriesTableOrderingComposer,
      $$ConfigEntriesTableAnnotationComposer,
      $$ConfigEntriesTableCreateCompanionBuilder,
      $$ConfigEntriesTableUpdateCompanionBuilder,
      (
        ConfigEntriesData,
        BaseReferences<
          _$AppDatabase,
          $ConfigEntriesTable,
          ConfigEntriesData
        >,
      ),
      ConfigEntriesData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SheetMusicsTableTableManager get SheetMusics =>
      $$SheetMusicsTableTableManager(_db, _db.SheetMusics);
  $$VoicesTableTableManager get voices =>
      $$VoicesTableTableManager(_db, _db.voices);
  $$AnnotationsTableTableManager get Annotations =>
      $$AnnotationsTableTableManager(_db, _db.Annotations);
  $$ConfigEntriesTableTableManager get ConfigEntries =>
      $$ConfigEntriesTableTableManager(
        _db,
        _db.ConfigEntries,
      );
}
