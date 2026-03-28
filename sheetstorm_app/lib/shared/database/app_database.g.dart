// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SheetMusicsTable extends SheetMusics
    with TableInfo<$SheetMusicsTable, SheetMusic> {
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
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
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOfflineAvailableMeta =
      const VerificationMeta('isOfflineAvailable');
  @override
  late final GeneratedColumn<bool> isOfflineAvailable = GeneratedColumn<bool>(
    'is_offline_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_offline_available" IN (0, 1))',
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
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
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
  static const String $name = 'sheet_musics';
  @override
  VerificationContext validateIntegrity(
    Insertable<SheetMusic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
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
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('is_offline_available')) {
      context.handle(
        _isOfflineAvailableMeta,
        isOfflineAvailable.isAcceptableOrUnknown(
          data['is_offline_available']!,
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
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SheetMusic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SheetMusic(
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
        data['${effectivePrefix}local_path'],
      ),
      isOfflineAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_offline_available'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SheetMusicsTable createAlias(String alias) {
    return $SheetMusicsTable(attachedDatabase, alias);
  }
}

class SheetMusic extends DataClass implements Insertable<SheetMusic> {
  final int id;
  final String title;
  final String? composer;
  final String? genre;
  final String? localPath;
  final bool isOfflineAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SheetMusic({
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
      map['local_path'] = Variable<String>(localPath);
    }
    map['is_offline_available'] = Variable<bool>(isOfflineAvailable);
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

  factory SheetMusic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SheetMusic(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      composer: serializer.fromJson<String?>(json['composer']),
      genre: serializer.fromJson<String?>(json['genre']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      isOfflineAvailable: serializer.fromJson<bool>(json['isOfflineAvailable']),
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

  SheetMusic copyWith({
    int? id,
    String? title,
    Value<String?> composer = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    bool? isOfflineAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SheetMusic(
    id: id ?? this.id,
    title: title ?? this.title,
    composer: composer.present ? composer.value : this.composer,
    genre: genre.present ? genre.value : this.genre,
    localPath: localPath.present ? localPath.value : this.localPath,
    isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SheetMusic copyWithCompanion(SheetMusicsCompanion data) {
    return SheetMusic(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      composer: data.composer.present ? data.composer.value : this.composer,
      genre: data.genre.present ? data.genre.value : this.genre,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      isOfflineAvailable: data.isOfflineAvailable.present
          ? data.isOfflineAvailable.value
          : this.isOfflineAvailable,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SheetMusic(')
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
      (other is SheetMusic &&
          other.id == this.id &&
          other.title == this.title &&
          other.composer == this.composer &&
          other.genre == this.genre &&
          other.localPath == this.localPath &&
          other.isOfflineAvailable == this.isOfflineAvailable &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SheetMusicsCompanion extends UpdateCompanion<SheetMusic> {
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
  static Insertable<SheetMusic> custom({
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
      if (localPath != null) 'local_path': localPath,
      if (isOfflineAvailable != null)
        'is_offline_available': isOfflineAvailable,
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
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (isOfflineAvailable.present) {
      map['is_offline_available'] = Variable<bool>(isOfflineAvailable.value);
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

class $VoicesTable extends Voices with TableInfo<$VoicesTable, Voice> {
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
    'sheet_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sheet_musics (id)',
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
    'page_count',
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
    Insertable<Voice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sheet_id')) {
      context.handle(
        _sheetIdMeta,
        sheetId.isAcceptableOrUnknown(data['sheet_id']!, _sheetIdMeta),
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
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Voice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Voice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sheetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sheet_id'],
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
        data['${effectivePrefix}page_count'],
      )!,
    );
  }

  @override
  $VoicesTable createAlias(String alias) {
    return $VoicesTable(attachedDatabase, alias);
  }
}

class Voice extends DataClass implements Insertable<Voice> {
  final int id;
  final int sheetId;
  final String name;
  final String? instrument;
  final int pageCount;
  const Voice({
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
    map['sheet_id'] = Variable<int>(sheetId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || instrument != null) {
      map['instrument'] = Variable<String>(instrument);
    }
    map['page_count'] = Variable<int>(pageCount);
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

  factory Voice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Voice(
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

  Voice copyWith({
    int? id,
    int? sheetId,
    String? name,
    Value<String?> instrument = const Value.absent(),
    int? pageCount,
  }) => Voice(
    id: id ?? this.id,
    sheetId: sheetId ?? this.sheetId,
    name: name ?? this.name,
    instrument: instrument.present ? instrument.value : this.instrument,
    pageCount: pageCount ?? this.pageCount,
  );
  Voice copyWithCompanion(VoicesCompanion data) {
    return Voice(
      id: data.id.present ? data.id.value : this.id,
      sheetId: data.sheetId.present ? data.sheetId.value : this.sheetId,
      name: data.name.present ? data.name.value : this.name,
      instrument: data.instrument.present
          ? data.instrument.value
          : this.instrument,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Voice(')
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
      (other is Voice &&
          other.id == this.id &&
          other.sheetId == this.sheetId &&
          other.name == this.name &&
          other.instrument == this.instrument &&
          other.pageCount == this.pageCount);
}

class VoicesCompanion extends UpdateCompanion<Voice> {
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
  static Insertable<Voice> custom({
    Expression<int>? id,
    Expression<int>? sheetId,
    Expression<String>? name,
    Expression<String>? instrument,
    Expression<int>? pageCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sheetId != null) 'sheet_id': sheetId,
      if (name != null) 'name': name,
      if (instrument != null) 'instrument': instrument,
      if (pageCount != null) 'page_count': pageCount,
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
      map['sheet_id'] = Variable<int>(sheetId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (instrument.present) {
      map['instrument'] = Variable<String>(instrument.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
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
    with TableInfo<$AnnotationsTable, Annotation> {
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
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
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
    'x_relative',
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
    'y_relative',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
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
    'svg_data',
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
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Annotation> instance, {
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
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('x_relative')) {
      context.handle(
        _xRelativeMeta,
        xRelative.isAcceptableOrUnknown(data['x_relative']!, _xRelativeMeta),
      );
    } else if (isInserting) {
      context.missing(_xRelativeMeta);
    }
    if (data.containsKey('y_relative')) {
      context.handle(
        _yRelativeMeta,
        yRelative.isAcceptableOrUnknown(data['y_relative']!, _yRelativeMeta),
      );
    } else if (isInserting) {
      context.missing(_yRelativeMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('svg_data')) {
      context.handle(
        _svgDataMeta,
        svgData.isAcceptableOrUnknown(data['svg_data']!, _svgDataMeta),
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
  Annotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Annotation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      voiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}voice_id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      xRelative: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x_relative'],
      )!,
      yRelative: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y_relative'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}page'],
      )!,
      svgData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}svg_data'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }
}

class Annotation extends DataClass implements Insertable<Annotation> {
  final int id;
  final int voiceId;
  final String level;
  final double xRelative;
  final double yRelative;
  final double page;
  final String svgData;
  final DateTime createdAt;
  const Annotation({
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
    map['x_relative'] = Variable<double>(xRelative);
    map['y_relative'] = Variable<double>(yRelative);
    map['page'] = Variable<double>(page);
    map['svg_data'] = Variable<String>(svgData);
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

  factory Annotation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Annotation(
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

  Annotation copyWith({
    int? id,
    int? voiceId,
    String? level,
    double? xRelative,
    double? yRelative,
    double? page,
    String? svgData,
    DateTime? createdAt,
  }) => Annotation(
    id: id ?? this.id,
    voiceId: voiceId ?? this.voiceId,
    level: level ?? this.level,
    xRelative: xRelative ?? this.xRelative,
    yRelative: yRelative ?? this.yRelative,
    page: page ?? this.page,
    svgData: svgData ?? this.svgData,
    createdAt: createdAt ?? this.createdAt,
  );
  Annotation copyWithCompanion(AnnotationsCompanion data) {
    return Annotation(
      id: data.id.present ? data.id.value : this.id,
      voiceId: data.voiceId.present ? data.voiceId.value : this.voiceId,
      level: data.level.present ? data.level.value : this.level,
      xRelative: data.xRelative.present ? data.xRelative.value : this.xRelative,
      yRelative: data.yRelative.present ? data.yRelative.value : this.yRelative,
      page: data.page.present ? data.page.value : this.page,
      svgData: data.svgData.present ? data.svgData.value : this.svgData,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Annotation(')
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
      (other is Annotation &&
          other.id == this.id &&
          other.voiceId == this.voiceId &&
          other.level == this.level &&
          other.xRelative == this.xRelative &&
          other.yRelative == this.yRelative &&
          other.page == this.page &&
          other.svgData == this.svgData &&
          other.createdAt == this.createdAt);
}

class AnnotationsCompanion extends UpdateCompanion<Annotation> {
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
  static Insertable<Annotation> custom({
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
      if (xRelative != null) 'x_relative': xRelative,
      if (yRelative != null) 'y_relative': yRelative,
      if (page != null) 'page': page,
      if (svgData != null) 'svg_data': svgData,
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
      map['x_relative'] = Variable<double>(xRelative.value);
    }
    if (yRelative.present) {
      map['y_relative'] = Variable<double>(yRelative.value);
    }
    if (page.present) {
      map['page'] = Variable<double>(page.value);
    }
    if (svgData.present) {
      map['svg_data'] = Variable<String>(svgData.value);
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
    with TableInfo<$ConfigEntriesTable, ConfigEntry> {
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
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
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
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, level, key, value, isLocked];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'config_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfigEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
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
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfigEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigEntry(
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
        data['${effectivePrefix}is_locked'],
      )!,
    );
  }

  @override
  $ConfigEntriesTable createAlias(String alias) {
    return $ConfigEntriesTable(attachedDatabase, alias);
  }
}

class ConfigEntry extends DataClass implements Insertable<ConfigEntry> {
  final int id;
  final String level;
  final String key;
  final String value;
  final bool isLocked;
  const ConfigEntry({
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
    map['is_locked'] = Variable<bool>(isLocked);
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

  factory ConfigEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigEntry(
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

  ConfigEntry copyWith({
    int? id,
    String? level,
    String? key,
    String? value,
    bool? isLocked,
  }) => ConfigEntry(
    id: id ?? this.id,
    level: level ?? this.level,
    key: key ?? this.key,
    value: value ?? this.value,
    isLocked: isLocked ?? this.isLocked,
  );
  ConfigEntry copyWithCompanion(ConfigEntriesCompanion data) {
    return ConfigEntry(
      id: data.id.present ? data.id.value : this.id,
      level: data.level.present ? data.level.value : this.level,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigEntry(')
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
      (other is ConfigEntry &&
          other.id == this.id &&
          other.level == this.level &&
          other.key == this.key &&
          other.value == this.value &&
          other.isLocked == this.isLocked);
}

class ConfigEntriesCompanion extends UpdateCompanion<ConfigEntry> {
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
  static Insertable<ConfigEntry> custom({
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
      if (isLocked != null) 'is_locked': isLocked,
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
      map['is_locked'] = Variable<bool>(isLocked.value);
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
  late final $SheetMusicsTable sheetMusics = $SheetMusicsTable(this);
  late final $VoicesTable voices = $VoicesTable(this);
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  late final $ConfigEntriesTable configEntries = $ConfigEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sheetMusics,
    voices,
    annotations,
    configEntries,
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
    extends BaseReferences<_$AppDatabase, $SheetMusicsTable, SheetMusic> {
  $$SheetMusicsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VoicesTable, List<Voice>> _voicesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.voices,
    aliasName: $_aliasNameGenerator(db.sheetMusics.id, db.voices.sheetId),
  );

  $$VoicesTableProcessedTableManager get voicesRefs {
    final manager = $$VoicesTableTableManager(
      $_db,
      $_db.voices,
    ).filter((f) => f.sheetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_voicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SheetMusicsTableFilterComposer
    extends Composer<_$AppDatabase, $SheetMusicsTable> {
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

  Expression<bool> voicesRefs(
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

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<bool> get isOfflineAvailable => $composableBuilder(
    column: $table.isOfflineAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> voicesRefs<T extends Object>(
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
          SheetMusic,
          $$SheetMusicsTableFilterComposer,
          $$SheetMusicsTableOrderingComposer,
          $$SheetMusicsTableAnnotationComposer,
          $$SheetMusicsTableCreateCompanionBuilder,
          $$SheetMusicsTableUpdateCompanionBuilder,
          (SheetMusic, $$SheetMusicsTableReferences),
          SheetMusic,
          PrefetchHooks Function({bool voicesRefs})
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
                (e) => (
                  e.readTable(table),
                  $$SheetMusicsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({voicesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (voicesRefs) db.voices],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (voicesRefs)
                    await $_getPrefetchedData<
                      SheetMusic,
                      $SheetMusicsTable,
                      Voice
                    >(
                      currentTable: table,
                      referencedTable: $$SheetMusicsTableReferences
                          ._voicesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SheetMusicsTableReferences(
                            db,
                            table,
                            p0,
                          ).voicesRefs,
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
      SheetMusic,
      $$SheetMusicsTableFilterComposer,
      $$SheetMusicsTableOrderingComposer,
      $$SheetMusicsTableAnnotationComposer,
      $$SheetMusicsTableCreateCompanionBuilder,
      $$SheetMusicsTableUpdateCompanionBuilder,
      (SheetMusic, $$SheetMusicsTableReferences),
      SheetMusic,
      PrefetchHooks Function({bool voicesRefs})
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
    extends BaseReferences<_$AppDatabase, $VoicesTable, Voice> {
  $$VoicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SheetMusicsTable _sheetIdTable(_$AppDatabase db) => db.sheetMusics
      .createAlias($_aliasNameGenerator(db.voices.sheetId, db.sheetMusics.id));

  $$SheetMusicsTableProcessedTableManager get sheetId {
    final $_column = $_itemColumn<int>('sheet_id')!;

    final manager = $$SheetMusicsTableTableManager(
      $_db,
      $_db.sheetMusics,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sheetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AnnotationsTable, List<Annotation>>
  _annotationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.annotations,
    aliasName: $_aliasNameGenerator(db.voices.id, db.annotations.voiceId),
  );

  $$AnnotationsTableProcessedTableManager get annotationsRefs {
    final manager = $$AnnotationsTableTableManager(
      $_db,
      $_db.annotations,
    ).filter((f) => f.voiceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_annotationsRefsTable($_db));
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
      referencedTable: $db.sheetMusics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetMusicsTableFilterComposer(
            $db: $db,
            $table: $db.sheetMusics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> annotationsRefs(
    Expression<bool> Function($$AnnotationsTableFilterComposer f) f,
  ) {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.voiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
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
      referencedTable: $db.sheetMusics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetMusicsTableOrderingComposer(
            $db: $db,
            $table: $db.sheetMusics,
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

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  $$SheetMusicsTableAnnotationComposer get sheetId {
    final $$SheetMusicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.sheetMusics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetMusicsTableAnnotationComposer(
            $db: $db,
            $table: $db.sheetMusics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> annotationsRefs<T extends Object>(
    Expression<T> Function($$AnnotationsTableAnnotationComposer a) f,
  ) {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.voiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
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
          Voice,
          $$VoicesTableFilterComposer,
          $$VoicesTableOrderingComposer,
          $$VoicesTableAnnotationComposer,
          $$VoicesTableCreateCompanionBuilder,
          $$VoicesTableUpdateCompanionBuilder,
          (Voice, $$VoicesTableReferences),
          Voice,
          PrefetchHooks Function({bool sheetId, bool annotationsRefs})
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
                (e) =>
                    (e.readTable(table), $$VoicesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({sheetId = false, annotationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (annotationsRefs) db.annotations],
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
                  if (annotationsRefs)
                    await $_getPrefetchedData<Voice, $VoicesTable, Annotation>(
                      currentTable: table,
                      referencedTable: $$VoicesTableReferences
                          ._annotationsRefsTable(db),
                      managerFromTypedResult: (p0) => $$VoicesTableReferences(
                        db,
                        table,
                        p0,
                      ).annotationsRefs,
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
      Voice,
      $$VoicesTableFilterComposer,
      $$VoicesTableOrderingComposer,
      $$VoicesTableAnnotationComposer,
      $$VoicesTableCreateCompanionBuilder,
      $$VoicesTableUpdateCompanionBuilder,
      (Voice, $$VoicesTableReferences),
      Voice,
      PrefetchHooks Function({bool sheetId, bool annotationsRefs})
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
    extends BaseReferences<_$AppDatabase, $AnnotationsTable, Annotation> {
  $$AnnotationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VoicesTable _voiceIdTable(_$AppDatabase db) => db.voices.createAlias(
    $_aliasNameGenerator(db.annotations.voiceId, db.voices.id),
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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
          Annotation,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (Annotation, $$AnnotationsTableReferences),
          Annotation,
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
      Annotation,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (Annotation, $$AnnotationsTableReferences),
      Annotation,
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

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);
}

class $$ConfigEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigEntriesTable,
          ConfigEntry,
          $$ConfigEntriesTableFilterComposer,
          $$ConfigEntriesTableOrderingComposer,
          $$ConfigEntriesTableAnnotationComposer,
          $$ConfigEntriesTableCreateCompanionBuilder,
          $$ConfigEntriesTableUpdateCompanionBuilder,
          (
            ConfigEntry,
            BaseReferences<_$AppDatabase, $ConfigEntriesTable, ConfigEntry>,
          ),
          ConfigEntry,
          PrefetchHooks Function()
        > {
  $$ConfigEntriesTableTableManager(_$AppDatabase db, $ConfigEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigEntriesTableAnnotationComposer($db: db, $table: table),
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
      ConfigEntry,
      $$ConfigEntriesTableFilterComposer,
      $$ConfigEntriesTableOrderingComposer,
      $$ConfigEntriesTableAnnotationComposer,
      $$ConfigEntriesTableCreateCompanionBuilder,
      $$ConfigEntriesTableUpdateCompanionBuilder,
      (
        ConfigEntry,
        BaseReferences<_$AppDatabase, $ConfigEntriesTable, ConfigEntry>,
      ),
      ConfigEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SheetMusicsTableTableManager get sheetMusics =>
      $$SheetMusicsTableTableManager(_db, _db.sheetMusics);
  $$VoicesTableTableManager get voices =>
      $$VoicesTableTableManager(_db, _db.voices);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db, _db.annotations);
  $$ConfigEntriesTableTableManager get configEntries =>
      $$ConfigEntriesTableTableManager(_db, _db.configEntries);
}
