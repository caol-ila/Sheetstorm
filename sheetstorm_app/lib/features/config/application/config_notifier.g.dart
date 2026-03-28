// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConfigNotifier)
final configProvider = ConfigNotifierProvider._();

final class ConfigNotifierProvider
    extends $NotifierProvider<ConfigNotifier, ConfigState> {
  ConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configNotifierHash();

  @$internal
  @override
  ConfigNotifier create() => ConfigNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConfigState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConfigState>(value),
    );
  }
}

String _$configNotifierHash() => r'20c743a051d9848dde45723bb38ac3324014127f';

abstract class _$ConfigNotifier extends $Notifier<ConfigState> {
  ConfigState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ConfigState, ConfigState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConfigState, ConfigState>,
              ConfigState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
