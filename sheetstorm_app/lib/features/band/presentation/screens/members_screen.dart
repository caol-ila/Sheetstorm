import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/band/application/members_notifier.dart';
import 'package:sheetstorm/features/band/data/models/band_models.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';
import 'package:sheetstorm/features/band/presentation/widgets/member_list_tile.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key, required this.bandId});

  final String bandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersState = ref.watch(membersProvider(bandId));
    final isAdmin = _isAdmin(ref);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mitglieder')),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () =>
                  context.go(AppRoutes.bandInvite(bandId: bandId)),
              tooltip: 'Einladen',
              child: const Icon(Icons.person_add),
            )
          : null,
      body: membersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Fehler beim Laden', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () => ref
                    .read(membersProvider(bandId).notifier)
                    .refresh(),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Noch keine Mitglieder',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref
                .read(membersProvider(bandId).notifier)
                .refresh(),
            child: ListView.separated(
              itemCount: members.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = members[index];
                return MemberListTile(
                  member: member,
                  isAdmin: isAdmin,
                  onEditRoles: isAdmin
                      ? () => _showRoleEditSheet(context, ref, member)
                      : null,
                  onRemove: isAdmin
                      ? () => _confirmRemove(context, ref, member)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool _isAdmin(WidgetRef ref) {
    final listState = ref.watch(bandListProvider);
    return listState.whenOrNull(
          data: (bands) =>
              bands
                  .cast<Band?>()
                  .firstWhere((k) => k!.id == bandId, orElse: () => null)
                  ?.isAdmin ??
              false,
        ) ??
        false;
  }

  Future<void> _showRoleEditSheet(
    BuildContext context,
    WidgetRef ref,
    Member member,
  ) async {
    final selectedRoles = <BandRole>{...member.roles};

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Rollen für ${member.name}',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                ...BandRole.values.map((role) => CheckboxListTile(
                      value: selectedRoles.contains(role),
                      title: Text(role.label),
                      onChanged: (v) {
                        setSheetState(() {
                          if (v == true) {
                            selectedRoles.add(role);
                          } else {
                            selectedRoles.remove(role);
                          }
                        });
                      },
                    )),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final success = await ref
                        .read(
                            membersProvider(bandId).notifier)
                        .updateRoles(
                          member.musicianId,
                          selectedRoles.toList(),
                        );
                    if (!context.mounted) return;
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Rollen konnten nicht aktualisiert werden.'),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(AppSpacing.touchTargetMin),
                  ),
                  child: const Text('Speichern'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    Member member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mitglied entfernen?'),
        content: Text(
          'Möchtest du "${member.name}" wirklich aus der Kapelle entfernen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final success = await ref
        .read(membersProvider(bandId).notifier)
        .removeMember(member.musicianId);

    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mitglied konnte nicht entfernt werden.'),
        ),
      );
    }
  }
}
