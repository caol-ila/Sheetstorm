// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RegisterNotifier)
final registerProvider = RegisterNotifierFamily._();

final class RegisterNotifierProvider
    extends $AsyncNotifierProvider<RegisterNotifier, List<Register>> {
  RegisterNotifierProvider._({
    required RegisterNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'registerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$registerNotifierHash();

  @override
  String toString() {
    return r'registerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RegisterNotifier create() => RegisterNotifier();

  @override
  bool operator ==(Object other) {
    return other is RegisterNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$registerNotifierHash() => r'4ffa60414894b7fd18c6ddeef8bb308fbdddf8d2';

final class RegisterNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          RegisterNotifier,
          AsyncValue<List<Register>>,
          List<Register>,
          FutureOr<List<Register>>,
          String
        > {
  RegisterNotifierFamily._()
    : super(
        retry: null,
        name: r'registerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RegisterNotifierProvider call(String kapelleId) =>
      RegisterNotifierProvider._(argument: kapelleId, from: this);

  @override
  String toString() => r'registerProvider';
}

abstract class _$RegisterNotifier extends $AsyncNotifier<List<Register>> {
  late final _$args = ref.$arg as String;
  String get kapelleId => _$args;

  FutureOr<List<Register>> build(String kapelleId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Register>>, List<Register>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Register>>, List<Register>>,
              AsyncValue<List<Register>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
