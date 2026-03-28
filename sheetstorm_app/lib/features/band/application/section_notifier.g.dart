// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SectionNotifier)
final registerProvider = SectionNotifierFamily._();

final class SectionNotifierProvider
    extends $AsyncNotifierProvider<SectionNotifier, List<Section>> {
  SectionNotifierProvider._({
    required SectionNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'registerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sectionNotifierHash();

  @override
  String toString() {
    return r'registerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SectionNotifier create() => SectionNotifier();

  @override
  bool operator ==(Object other) {
    return other is SectionNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sectionNotifierHash() => r'4ffa60414894b7fd18c6ddeef8bb308fbdddf8d2';

final class SectionNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SectionNotifier,
          AsyncValue<List<Section>>,
          List<Section>,
          FutureOr<List<Section>>,
          String
        > {
  SectionNotifierFamily._()
    : super(
        retry: null,
        name: r'registerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SectionNotifierProvider call(String bandId) =>
      SectionNotifierProvider._(argument: bandId, from: this);

  @override
  String toString() => r'registerProvider';
}

abstract class _$SectionNotifier extends $AsyncNotifier<List<Section>> {
  late final _$args = ref.$arg as String;
  String get bandId => _$args;

  FutureOr<List<Section>> build(String bandId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Section>>, List<Section>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Section>>, List<Section>>,
              AsyncValue<List<Section>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
