// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_scroll_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier managing auto-scroll state transitions and settings.

@ProviderFor(AutoScroll)
final autoScrollProvider = AutoScrollProvider._();

/// Notifier managing auto-scroll state transitions and settings.
final class AutoScrollProvider
    extends $NotifierProvider<AutoScroll, AutoScrollState> {
  /// Notifier managing auto-scroll state transitions and settings.
  AutoScrollProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScrollProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScrollHash();

  @$internal
  @override
  AutoScroll create() => AutoScroll();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoScrollState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoScrollState>(value),
    );
  }
}

String _$autoScrollHash() => r'f3855734a0352462b94899e5c939e4e76b6190e6';

/// Notifier managing auto-scroll state transitions and settings.

abstract class _$AutoScroll extends $Notifier<AutoScrollState> {
  AutoScrollState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AutoScrollState, AutoScrollState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AutoScrollState, AutoScrollState>,
              AutoScrollState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
