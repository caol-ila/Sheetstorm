// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_mode_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).

@ProviderFor(PerformanceModeSettingsNotifier)
final performanceModeSettingsProvider =
    PerformanceModeSettingsNotifierProvider._();

/// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).
final class PerformanceModeSettingsNotifierProvider
    extends
        $NotifierProvider<
          PerformanceModeSettingsNotifier,
          PerformanceModeSettings
        > {
  /// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).
  PerformanceModeSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'performanceModeSettingsProvider',
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
    r'7f423cd4f6d6003825136a6e203a7762d3a8c2ef';

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
