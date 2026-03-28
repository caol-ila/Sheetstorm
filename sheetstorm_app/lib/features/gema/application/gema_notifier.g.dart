// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gema_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GemaReportListNotifier)
final gemaReportListProvider = GemaReportListNotifierFamily._();

final class GemaReportListNotifierProvider
    extends $AsyncNotifierProvider<GemaReportListNotifier, List<GemaReport>> {
  GemaReportListNotifierProvider._({
    required GemaReportListNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'gemaReportListProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gemaReportListNotifierHash();

  @override
  String toString() {
    return r'gemaReportListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  GemaReportListNotifier create() => GemaReportListNotifier();

  @override
  bool operator ==(Object other) {
    return other is GemaReportListNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gemaReportListNotifierHash() =>
    r'd0d018a1cd2558794f0f85dba4c053dbf7ebe6b5';

final class GemaReportListNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GemaReportListNotifier,
          AsyncValue<List<GemaReport>>,
          List<GemaReport>,
          FutureOr<List<GemaReport>>,
          String
        > {
  GemaReportListNotifierFamily._()
    : super(
        retry: null,
        name: r'gemaReportListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  GemaReportListNotifierProvider call(String kapelleId) =>
      GemaReportListNotifierProvider._(argument: kapelleId, from: this);

  @override
  String toString() => r'gemaReportListProvider';
}

abstract class _$GemaReportListNotifier
    extends $AsyncNotifier<List<GemaReport>> {
  late final _$args = ref.$arg as String;
  String get kapelleId => _$args;

  FutureOr<List<GemaReport>> build(String kapelleId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<GemaReport>>, List<GemaReport>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<GemaReport>>, List<GemaReport>>,
              AsyncValue<List<GemaReport>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(GemaReportDetailNotifier)
final gemaReportDetailProvider = GemaReportDetailNotifierFamily._();

final class GemaReportDetailNotifierProvider
    extends $AsyncNotifierProvider<GemaReportDetailNotifier, GemaReport> {
  GemaReportDetailNotifierProvider._({
    required GemaReportDetailNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'gemaReportDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gemaReportDetailNotifierHash();

  @override
  String toString() {
    return r'gemaReportDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GemaReportDetailNotifier create() => GemaReportDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is GemaReportDetailNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gemaReportDetailNotifierHash() =>
    r'1537032da83594486cf5a6ae6c8cd1c45066720d';

final class GemaReportDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GemaReportDetailNotifier,
          AsyncValue<GemaReport>,
          GemaReport,
          FutureOr<GemaReport>,
          (String, String)
        > {
  GemaReportDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'gemaReportDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GemaReportDetailNotifierProvider call(String kapelleId, String reportId) =>
      GemaReportDetailNotifierProvider._(
        argument: (kapelleId, reportId),
        from: this,
      );

  @override
  String toString() => r'gemaReportDetailProvider';
}

abstract class _$GemaReportDetailNotifier extends $AsyncNotifier<GemaReport> {
  late final _$args = ref.$arg as (String, String);
  String get kapelleId => _$args.$1;
  String get reportId => _$args.$2;

  FutureOr<GemaReport> build(String kapelleId, String reportId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GemaReport>, GemaReport>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GemaReport>, GemaReport>,
              AsyncValue<GemaReport>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
