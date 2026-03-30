// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ShiftPlanListNotifier)
final shiftPlanListProvider = ShiftPlanListNotifierFamily._();

final class ShiftPlanListNotifierProvider
    extends $AsyncNotifierProvider<ShiftPlanListNotifier, List<ShiftPlan>> {
  ShiftPlanListNotifierProvider._({
    required ShiftPlanListNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'shiftPlanListProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shiftPlanListNotifierHash();

  @override
  String toString() {
    return r'shiftPlanListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ShiftPlanListNotifier create() => ShiftPlanListNotifier();

  @override
  bool operator ==(Object other) {
    return other is ShiftPlanListNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shiftPlanListNotifierHash() =>
    r'9b4f69eec3159f7a2e7c2811a7be8ac61b43649d';

final class ShiftPlanListNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ShiftPlanListNotifier,
          AsyncValue<List<ShiftPlan>>,
          List<ShiftPlan>,
          FutureOr<List<ShiftPlan>>,
          String
        > {
  ShiftPlanListNotifierFamily._()
    : super(
        retry: null,
        name: r'shiftPlanListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ShiftPlanListNotifierProvider call(String bandId) =>
      ShiftPlanListNotifierProvider._(argument: bandId, from: this);

  @override
  String toString() => r'shiftPlanListProvider';
}

abstract class _$ShiftPlanListNotifier extends $AsyncNotifier<List<ShiftPlan>> {
  late final _$args = ref.$arg as String;
  String get bandId => _$args;

  FutureOr<List<ShiftPlan>> build(String bandId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<ShiftPlan>>, List<ShiftPlan>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ShiftPlan>>, List<ShiftPlan>>,
              AsyncValue<List<ShiftPlan>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(ShiftPlanNotifier)
final shiftPlanProvider = ShiftPlanNotifierFamily._();

final class ShiftPlanNotifierProvider
    extends $AsyncNotifierProvider<ShiftPlanNotifier, ShiftPlan> {
  ShiftPlanNotifierProvider._({
    required ShiftPlanNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'shiftPlanProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shiftPlanNotifierHash();

  @override
  String toString() {
    return r'shiftPlanProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ShiftPlanNotifier create() => ShiftPlanNotifier();

  @override
  bool operator ==(Object other) {
    return other is ShiftPlanNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shiftPlanNotifierHash() => r'a9ace11688a0d8bbc556d79c575fa1178a7e732f';

final class ShiftPlanNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ShiftPlanNotifier,
          AsyncValue<ShiftPlan>,
          ShiftPlan,
          FutureOr<ShiftPlan>,
          (String, String)
        > {
  ShiftPlanNotifierFamily._()
    : super(
        retry: null,
        name: r'shiftPlanProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShiftPlanNotifierProvider call(String bandId, String planId) =>
      ShiftPlanNotifierProvider._(argument: (bandId, planId), from: this);

  @override
  String toString() => r'shiftPlanProvider';
}

abstract class _$ShiftPlanNotifier extends $AsyncNotifier<ShiftPlan> {
  late final _$args = ref.$arg as (String, String);
  String get bandId => _$args.$1;
  String get planId => _$args.$2;

  FutureOr<ShiftPlan> build(String bandId, String planId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ShiftPlan>, ShiftPlan>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ShiftPlan>, ShiftPlan>,
              AsyncValue<ShiftPlan>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

@ProviderFor(myShifts)
final myShiftsProvider = MyShiftsFamily._();

final class MyShiftsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Shift>>,
          List<Shift>,
          FutureOr<List<Shift>>
        >
    with $FutureModifier<List<Shift>>, $FutureProvider<List<Shift>> {
  MyShiftsProvider._({
    required MyShiftsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'myShiftsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myShiftsHash();

  @override
  String toString() {
    return r'myShiftsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Shift>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Shift>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return myShifts(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is MyShiftsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myShiftsHash() => r'd2d4082d4048ef8261ddf419eb7f2cb700fd1a26';

final class MyShiftsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Shift>>, (String, String)> {
  MyShiftsFamily._()
    : super(
        retry: null,
        name: r'myShiftsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MyShiftsProvider call(String bandId, String myMusicianId) =>
      MyShiftsProvider._(argument: (bandId, myMusicianId), from: this);

  @override
  String toString() => r'myShiftsProvider';
}

@ProviderFor(openShifts)
final openShiftsProvider = OpenShiftsFamily._();

final class OpenShiftsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Shift>>,
          List<Shift>,
          FutureOr<List<Shift>>
        >
    with $FutureModifier<List<Shift>>, $FutureProvider<List<Shift>> {
  OpenShiftsProvider._({
    required OpenShiftsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'openShiftsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$openShiftsHash();

  @override
  String toString() {
    return r'openShiftsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Shift>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Shift>> create(Ref ref) {
    final argument = this.argument as String;
    return openShifts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OpenShiftsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$openShiftsHash() => r'2093d44209c631d7dfb05365278e0896c46c7b28';

final class OpenShiftsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Shift>>, String> {
  OpenShiftsFamily._()
    : super(
        retry: null,
        name: r'openShiftsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OpenShiftsProvider call(String bandId) =>
      OpenShiftsProvider._(argument: bandId, from: this);

  @override
  String toString() => r'openShiftsProvider';
}
