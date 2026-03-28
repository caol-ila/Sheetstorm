// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spielmodus_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).

@ProviderFor(SpielmodusSettingsNotifier)
final spielmodusSettingsProvider = SpielmodusSettingsNotifierProvider._();

/// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).
final class SpielmodusSettingsNotifierProvider
    extends
        $NotifierProvider<SpielmodusSettingsNotifier, SpielmodusEinstellungen> {
  /// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).
  SpielmodusSettingsNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$spielmodusSettingsNotifierHash();

  @$internal
  @override
  SpielmodusSettingsNotifier create() => SpielmodusSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpielmodusEinstellungen value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpielmodusEinstellungen>(value),
    );
  }
}

String _$spielmodusSettingsNotifierHash() =>
    r'94e8ab6f488dd63827ca04978210014a915a9d92';

/// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).

abstract class _$SpielmodusSettingsNotifier
    extends $Notifier<SpielmodusEinstellungen> {
  SpielmodusEinstellungen build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<SpielmodusEinstellungen, SpielmodusEinstellungen>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SpielmodusEinstellungen, SpielmodusEinstellungen>,
              SpielmodusEinstellungen,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
