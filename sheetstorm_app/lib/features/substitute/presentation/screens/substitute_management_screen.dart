import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/substitute/application/pending_substitute_link_provider.dart';
import 'package:sheetstorm/features/substitute/application/substitute_notifier.dart';
import 'package:sheetstorm/features/substitute/data/models/substitute_models.dart';
import 'package:sheetstorm/features/substitute/presentation/widgets/access_link_card.dart';
import 'package:sheetstorm/features/substitute/presentation/widgets/substitute_status_badge.dart';

class SubstituteManagementScreen extends ConsumerStatefulWidget {
  const SubstituteManagementScreen({super.key, required this.bandId});

  final String bandId;

  @override
  ConsumerState<SubstituteManagementScreen> createState() =>
      _SubstituteManagementScreenState();
}

class _SubstituteManagementScreenState
    extends ConsumerState<SubstituteManagementScreen> {
  SubstituteStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final accessListAsync =
        ref.watch(substituteListProvider(widget.bandId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aushilfen-Zugänge'),
        actions: [
          PopupMenuButton<SubstituteStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              setState(() {
                _filterStatus = status;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Alle anzeigen'),
              ),
              const PopupMenuItem(
                value: SubstituteStatus.active,
                child: Text('Nur Aktive'),
              ),
              const PopupMenuItem(
                value: SubstituteStatus.expired,
                child: Text('Nur Abgelaufene'),
              ),
              const PopupMenuItem(
                value: SubstituteStatus.revoked,
                child: Text('Nur Widerrufene'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Aushilfe hinzufügen'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(substituteListProvider(widget.bandId).notifier)
              .refresh();
        },
        child: accessListAsync.when(
          data: (accessList) {
            final filteredList = _filterStatus == null
                ? accessList
                : accessList
                    .where((access) => access.status == _filterStatus)
                    .toList();

            if (filteredList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Keine Aushilfen-Zugänge',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Erstelle einen neuen Zugang mit dem +-Button',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final access = filteredList[index];
                return AccessLinkCard(
                  access: access,
                  onRevoke: () => _revokeAccess(access.id),
                  onExtend: () => _showExtendDialog(access),
                  onShowQR: () => _showQRCode(access),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Fehler: $error'),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String instrument = '';
    String voice = '';
    DateTime? expiresAt;
    String? note;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Aushilfe hinzufügen'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name *'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Pflichtfeld' : null,
                    onSaved: (value) => name = value!,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Instrument *'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Pflichtfeld' : null,
                    onSaved: (value) => instrument = value!,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Stimme *'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Pflichtfeld' : null,
                    onSaved: (value) => voice = value!,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Notiz (optional)',
                      hintText: 'z.B. Ersatz für...',
                    ),
                    maxLines: 2,
                    onSaved: (value) => note = value?.isNotEmpty == true ? value : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    title: const Text('Gültig bis'),
                    subtitle: Text(
                      expiresAt != null
                          ? _formatDate(expiresAt!)
                          : '7 Tage (Standard)',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() {
                          expiresAt = date;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(context);
                  
                  final notifier = ref.read(
                    substituteListProvider(widget.bandId).notifier,
                  );
                  
                  final link = await notifier.createAccess(
                    name: name,
                    instrument: instrument,
                    voice: voice,
                    expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 7)),
                    note: note,
                  );
                  
                  if (link != null && mounted) {
                    _showLinkDialog(link);
                  }
                }
              },
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLinkDialog(SubstituteLink link) async {
    if (!mounted) return;
    ref.read(pendingSubstituteLinkProvider.notifier).set(link);
    context.push('/app/band/${widget.bandId}/substitute/link');
  }

  Future<void> _revokeAccess(String accessId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zugang widerrufen?'),
        content: const Text(
          'Der Aushilfsmusiker kann den Link nicht mehr verwenden. Dies kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Widerrufen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier =
          ref.read(substituteListProvider(widget.bandId).notifier);
      final success = await notifier.revokeAccess(accessId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Zugang widerrufen' : 'Fehler beim Widerrufen',
            ),
          ),
        );
      }
    }
  }

  Future<void> _showExtendDialog(SubstituteAccess access) async {
    DateTime? newDate;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gültigkeit verlängern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Aktuell gültig bis: ${_formatDate(access.expiresAt)}'),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                ElevatedButton(
                  onPressed: () {
                    newDate = DateTime.now().add(const Duration(days: 1));
                    Navigator.pop(context);
                  },
                  child: const Text('+1 Tag'),
                ),
                ElevatedButton(
                  onPressed: () {
                    newDate = DateTime.now().add(const Duration(days: 7));
                    Navigator.pop(context);
                  },
                  child: const Text('+7 Tage'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: access.expiresAt,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      newDate = date;
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Datum wählen'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );

    if (newDate != null) {
      final notifier =
          ref.read(substituteListProvider(widget.bandId).notifier);
      final success = await notifier.extendExpiry(access.id, newDate!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Gültigkeit verlängert' : 'Fehler beim Verlängern',
            ),
          ),
        );
      }
    }
  }

  void _showQRCode(SubstituteAccess access) {
    context.push('/app/band/${widget.bandId}/substitute/qr/${access.id}');
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
