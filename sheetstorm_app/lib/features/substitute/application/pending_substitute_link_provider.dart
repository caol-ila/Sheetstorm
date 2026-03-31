import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/substitute/data/models/substitute_models.dart';

part 'pending_substitute_link_provider.g.dart';

/// Temporärer Provider, der einen frisch erstellten [SubstituteLink] hält,
/// damit die substitute/link-Route ohne `state.extra` navigieren kann.
///
/// Workflow:
/// 1. Nach `createAccess()` → `ref.read(pendingSubstituteLinkProvider.notifier).set(link)`
/// 2. `context.push('/app/band/$bandId/substitute/link')`
/// 3. Route liest via `ref.watch(pendingSubstituteLinkProvider)`
@riverpod
class PendingSubstituteLink extends _$PendingSubstituteLink {
  @override
  SubstituteLink? build() => null;

  void set(SubstituteLink? link) => state = link;
}
