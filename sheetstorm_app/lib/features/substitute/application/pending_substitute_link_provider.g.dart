// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_substitute_link_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Temporärer Provider, der einen frisch erstellten [SubstituteLink] hält,
/// damit die substitute/link-Route ohne `state.extra` navigieren kann.
///
/// Workflow:
/// 1. Nach `createAccess()` → `ref.read(pendingSubstituteLinkProvider.notifier).set(link)`
/// 2. `context.push('/app/band/$bandId/substitute/link')`
/// 3. Route liest via `ref.watch(pendingSubstituteLinkProvider)`

@ProviderFor(PendingSubstituteLink)
final pendingSubstituteLinkProvider = PendingSubstituteLinkProvider._();

/// Temporärer Provider, der einen frisch erstellten [SubstituteLink] hält,
/// damit die substitute/link-Route ohne `state.extra` navigieren kann.
///
/// Workflow:
/// 1. Nach `createAccess()` → `ref.read(pendingSubstituteLinkProvider.notifier).set(link)`
/// 2. `context.push('/app/band/$bandId/substitute/link')`
/// 3. Route liest via `ref.watch(pendingSubstituteLinkProvider)`
final class PendingSubstituteLinkProvider
    extends $NotifierProvider<PendingSubstituteLink, SubstituteLink?> {
  /// Temporärer Provider, der einen frisch erstellten [SubstituteLink] hält,
  /// damit die substitute/link-Route ohne `state.extra` navigieren kann.
  ///
  /// Workflow:
  /// 1. Nach `createAccess()` → `ref.read(pendingSubstituteLinkProvider.notifier).set(link)`
  /// 2. `context.push('/app/band/$bandId/substitute/link')`
  /// 3. Route liest via `ref.watch(pendingSubstituteLinkProvider)`
  PendingSubstituteLinkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSubstituteLinkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSubstituteLinkHash();

  @$internal
  @override
  PendingSubstituteLink create() => PendingSubstituteLink();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubstituteLink? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubstituteLink?>(value),
    );
  }
}

String _$pendingSubstituteLinkHash() =>
    r'61b9ff3a2d246e6706d8b3eea1087907d31cb901';

/// Temporärer Provider, der einen frisch erstellten [SubstituteLink] hält,
/// damit die substitute/link-Route ohne `state.extra` navigieren kann.
///
/// Workflow:
/// 1. Nach `createAccess()` → `ref.read(pendingSubstituteLinkProvider.notifier).set(link)`
/// 2. `context.push('/app/band/$bandId/substitute/link')`
/// 3. Route liest via `ref.watch(pendingSubstituteLinkProvider)`

abstract class _$PendingSubstituteLink extends $Notifier<SubstituteLink?> {
  SubstituteLink? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SubstituteLink?, SubstituteLink?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SubstituteLink?, SubstituteLink?>,
              SubstituteLink?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
