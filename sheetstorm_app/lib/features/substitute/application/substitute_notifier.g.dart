// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'substitute_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SubstituteListNotifier)
final substituteListProvider = SubstituteListNotifierFamily._();

final class SubstituteListNotifierProvider
    extends
        $AsyncNotifierProvider<SubstituteListNotifier, List<SubstituteAccess>> {
  SubstituteListNotifierProvider._({
    required SubstituteListNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'substituteListProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$substituteListNotifierHash();

  @override
  String toString() {
    return r'substituteListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SubstituteListNotifier create() => SubstituteListNotifier();

  @override
  bool operator ==(Object other) {
    return other is SubstituteListNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$substituteListNotifierHash() =>
    r'68d3aa9d08d724624bfbf959739c1e1c63d8764e';

final class SubstituteListNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SubstituteListNotifier,
          AsyncValue<List<SubstituteAccess>>,
          List<SubstituteAccess>,
          FutureOr<List<SubstituteAccess>>,
          String
        > {
  SubstituteListNotifierFamily._()
    : super(
        retry: null,
        name: r'substituteListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  SubstituteListNotifierProvider call(String bandId) =>
      SubstituteListNotifierProvider._(argument: bandId, from: this);

  @override
  String toString() => r'substituteListProvider';
}

abstract class _$SubstituteListNotifier
    extends $AsyncNotifier<List<SubstituteAccess>> {
  late final _$args = ref.$arg as String;
  String get bandId => _$args;

  FutureOr<List<SubstituteAccess>> build(String bandId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<SubstituteAccess>>, List<SubstituteAccess>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<SubstituteAccess>>,
                List<SubstituteAccess>
              >,
              AsyncValue<List<SubstituteAccess>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(activeSubstitutes)
final activeSubstitutesProvider = ActiveSubstitutesFamily._();

final class ActiveSubstitutesProvider
    extends
        $FunctionalProvider<
          List<SubstituteAccess>,
          List<SubstituteAccess>,
          List<SubstituteAccess>
        >
    with $Provider<List<SubstituteAccess>> {
  ActiveSubstitutesProvider._({
    required ActiveSubstitutesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeSubstitutesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeSubstitutesHash();

  @override
  String toString() {
    return r'activeSubstitutesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<SubstituteAccess>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SubstituteAccess> create(Ref ref) {
    final argument = this.argument as String;
    return activeSubstitutes(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SubstituteAccess> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SubstituteAccess>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveSubstitutesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeSubstitutesHash() => r'c6cd744a7fccc7fa34d5a1661ac87d3927e74923';

final class ActiveSubstitutesFamily extends $Family
    with $FunctionalFamilyOverride<List<SubstituteAccess>, String> {
  ActiveSubstitutesFamily._()
    : super(
        retry: null,
        name: r'activeSubstitutesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveSubstitutesProvider call(String bandId) =>
      ActiveSubstitutesProvider._(argument: bandId, from: this);

  @override
  String toString() => r'activeSubstitutesProvider';
}
