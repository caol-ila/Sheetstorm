// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_scroll_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for persistent auto-scroll settings via SharedPreferences.

@ProviderFor(AutoScrollSettings)
final autoScrollSettingsProvider = AutoScrollSettingsProvider._();

/// Notifier for persistent auto-scroll settings via SharedPreferences.
final class AutoScrollSettingsProvider
    extends $NotifierProvider<AutoScrollSettings, AutoScrollSettingsState> {
  /// Notifier for persistent auto-scroll settings via SharedPreferences.
  AutoScrollSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScrollSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScrollSettingsHash();

  @$internal
  @override
  AutoScrollSettings create() => AutoScrollSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoScrollSettingsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoScrollSettingsState>(value),
    );
  }
}

String _$autoScrollSettingsHash() =>
    r'd9f0218a27606cebee7de02dad54bea87df7e6c6';

/// Notifier for persistent auto-scroll settings via SharedPreferences.

abstract class _$AutoScrollSettings extends $Notifier<AutoScrollSettingsState> {
  AutoScrollSettingsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AutoScrollSettingsState, AutoScrollSettingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AutoScrollSettingsState, AutoScrollSettingsState>,
              AutoScrollSettingsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
