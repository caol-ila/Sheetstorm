// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spielmodus_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).

@ProviderFor(PerformanceModeSettingsNotifier)
final spielmodusSettingsProvider = PerformanceModeSettingsNotifierProvider._();

/// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).
final class PerformanceModeSettingsNotifierProvider
    extends
        $NotifierProvider<PerformanceModeSettingsNotifier, PerformanceModeSettings> {
  /// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).
  PerformanceModeSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spielmodusSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$performanceModeSettingsNotifierHash();

  @$internal
  @override
  PerformanceModeSettingsNotifier create() => PerformanceModeSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PerformanceModeSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PerformanceModeSettings>(value),
    );
  }
}

String _$performanceModeSettingsNotifierHash() =>
    r'94e8ab6f488dd63827ca04978210014a915a9d92';

/// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).

abstract class _$PerformanceModeSettingsNotifier
    extends $Notifier<PerformanceModeSettings> {
  PerformanceModeSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<PerformanceModeSettings, PerformanceModeSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PerformanceModeSettings, PerformanceModeSettings>,
              PerformanceModeSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
