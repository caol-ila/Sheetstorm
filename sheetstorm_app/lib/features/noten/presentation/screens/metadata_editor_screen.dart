import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/noten/application/import_notifier.dart';
import 'package:sheetstorm/features/noten/data/models/import_models.dart';

/// Per-song metadata editor with AI suggestion display.
/// Shows one song at a time; user navigates through all songs.
class MetadataEditorScreen extends ConsumerStatefulWidget {
  const MetadataEditorScreen({
    super.key,
    required this.uploadId,
    required this.stueckIndex,
  });

  final String uploadId;
  final int stueckIndex;

  @override
  ConsumerState<MetadataEditorScreen> createState() =>
      _MetadataEditorScreenState();
}

class _MetadataEditorScreenState extends ConsumerState<MetadataEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titelCtrl;
  late TextEditingController _komponistCtrl;
  late TextEditingController _arrangeurCtrl;
  late TextEditingController _tonartCtrl;
  late TextEditingController _taktartCtrl;
  late TextEditingController _genreCtrl;

  // Fields that the user has manually confirmed
  final Set<String> _bestaetigt = {};

  TempStueck? _lastStueck;

  @override
  void initState() {
    super.initState();
    _titelCtrl = TextEditingController();
    _komponistCtrl = TextEditingController();
    _arrangeurCtrl = TextEditingController();
    _tonartCtrl = TextEditingController();
    _taktartCtrl = TextEditingController();
    _genreCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromState());
  }

  @override
  void dispose() {
    _titelCtrl.dispose();
    _komponistCtrl.dispose();
    _arrangeurCtrl.dispose();
    _tonartCtrl.dispose();
    _taktartCtrl.dispose();
    _genreCtrl.dispose();
    super.dispose();
  }

  void _syncFromState() {
    final current = ref.read(importProvider);
    if (current is! ImportEditingMetadata) return;
    final stueck = current.currentStueck;

    if (_lastStueck?.tempId == stueck.tempId) return;
    _lastStueck = stueck;

    _titelCtrl.text = stueck.titel ?? '';
    _komponistCtrl.text = stueck.komponist ?? '';
    _arrangeurCtrl.text = stueck.arrangeur ?? '';
    _tonartCtrl.text = stueck.tonart ?? '';
    _taktartCtrl.text = stueck.taktart ?? '';
    _genreCtrl.text = stueck.genre ?? '';
    _bestaetigt
      ..clear()
      ..addAll(stueck.felderBestaetigt);
  }

  void _saveAndNavigate(bool forward) {
    if (!_formKey.currentState!.validate()) return;
    _persistToNotifier();

    if (forward) {
      ref.read(importProvider.notifier).naechstesStueck();
    } else {
      ref.read(importProvider.notifier).vorherigesStueck();
    }
  }

  void _persistToNotifier() {
    ref.read(importProvider.notifier).metadatenAktualisieren(
          titel: _titelCtrl.text.trim().isNotEmpty
              ? _titelCtrl.text.trim()
              : null,
          komponist: _komponistCtrl.text.trim().isNotEmpty
              ? _komponistCtrl.text.trim()
              : null,
          arrangeur: _arrangeurCtrl.text.trim().isNotEmpty
              ? _arrangeurCtrl.text.trim()
              : null,
          tonart: _tonartCtrl.text.trim().isNotEmpty
              ? _tonartCtrl.text.trim()
              : null,
          taktart: _taktartCtrl.text.trim().isNotEmpty
              ? _taktartCtrl.text.trim()
              : null,
          genre: _genreCtrl.text.trim().isNotEmpty
              ? _genreCtrl.text.trim()
              : null,
          felderBestaetigt: Set.from(_bestaetigt),
        );
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importProvider);

    // Listen for navigation transitions
    ref.listen<ImportState>(importProvider, (prev, next) {
      if (next is ImportSummary) {
        context.pushReplacement(AppRoutes.importSummary(next.uploadId));
      } else if (next is ImportEditingMetadata) {
        // Song changed — sync form
        _syncFromState();
      }
    });

    if (importState is! ImportEditingMetadata) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final editing = importState;
    final stueck = editing.currentStueck;
    final v = stueck.vorschlaege;

    return Scaffold(
      appBar: AppBar(
        title: Text('Stück ${editing.currentIndex + 1} von ${editing.stuecke.length}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: editing.isFirst
              ? null
              : () => _saveAndNavigate(false),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _persistToNotifier();
              ref.read(importProvider.notifier).zuZusammenfassung();
            },
            child: const Text('Überspringen'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Song progress indicator ───────────────────────────────────
            _StueckProgress(
              current: editing.currentIndex + 1,
              total: editing.stuecke.length,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Page thumbnails row ───────────────────────────────────────
            _SeitenLeiste(
              seitenIds: stueck.seitenIds,
              seiten: editing.seiten,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Metadata fields ───────────────────────────────────────────
            _MetadataField(
              label: 'Titel *',
              controller: _titelCtrl,
              vorschlag: v?.titel,
              feldName: 'titel',
              bestaetigt: _bestaetigt.contains('titel'),
              onAnnehmen: () {
                if (v?.titel?.wert != null) {
                  setState(() {
                    _titelCtrl.text = v!.titel!.wert!;
                    _bestaetigt.add('titel');
                  });
                }
              },
              validator: (val) => null, // Title can be empty (defaults to "Unbekannt")
            ),
            const SizedBox(height: AppSpacing.md),

            _MetadataField(
              label: 'Komponist',
              controller: _komponistCtrl,
              vorschlag: v?.komponist,
              feldName: 'komponist',
              bestaetigt: _bestaetigt.contains('komponist'),
              onAnnehmen: () {
                if (v?.komponist?.wert != null) {
                  setState(() {
                    _komponistCtrl.text = v!.komponist!.wert!;
                    _bestaetigt.add('komponist');
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),

            _MetadataField(
              label: 'Arrangeur',
              controller: _arrangeurCtrl,
              feldName: 'arrangeur',
              bestaetigt: _bestaetigt.contains('arrangeur'),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _MetadataField(
                    label: 'Tonart',
                    controller: _tonartCtrl,
                    vorschlag: v?.tonart,
                    feldName: 'tonart',
                    bestaetigt: _bestaetigt.contains('tonart'),
                    onAnnehmen: () {
                      if (v?.tonart?.wert != null) {
                        setState(() {
                          _tonartCtrl.text = v!.tonart!.wert!;
                          _bestaetigt.add('tonart');
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetadataField(
                    label: 'Taktart',
                    controller: _taktartCtrl,
                    vorschlag: v?.taktart,
                    feldName: 'taktart',
                    bestaetigt: _bestaetigt.contains('taktart'),
                    onAnnehmen: () {
                      if (v?.taktart?.wert != null) {
                        setState(() {
                          _taktartCtrl.text = v!.taktart!.wert!;
                          _bestaetigt.add('taktart');
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _MetadataField(
              label: 'Genre',
              controller: _genreCtrl,
              feldName: 'genre',
              bestaetigt: _bestaetigt.contains('genre'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── AI Suggestion summary ─────────────────────────────────────
            if (v != null) _AiSuggestionSummary(vorschlaege: v),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (!editing.isFirst)
                OutlinedButton.icon(
                  onPressed: () => _saveAndNavigate(false),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Zurück'),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _saveAndNavigate(true),
                icon: Icon(
                  editing.isLast ? Icons.check : Icons.arrow_forward,
                ),
                label: Text(editing.isLast ? 'Fertig' : 'Weiter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _StueckProgress extends StatelessWidget {
  const _StueckProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stück $current von $total',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(value: current / total),
      ],
    );
  }
}

class _SeitenLeiste extends StatelessWidget {
  const _SeitenLeiste({required this.seitenIds, required this.seiten});

  final List<String> seitenIds;
  final List<SeiteInfo> seiten;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pagesToShow = seitenIds.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${seitenIds.length} Seite(n)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pagesToShow.length + (seitenIds.length > 6 ? 1 : 0),
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, idx) {
              if (idx == 6) {
                return Container(
                  width: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+${seitenIds.length - 6}',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }
              final id = pagesToShow[idx];
              final seite = seiten.where((s) => s.seiteId == id).firstOrNull;
              return Container(
                width: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  seite != null ? '${seite.seiteNr}' : '?',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MetadataField extends StatelessWidget {
  const _MetadataField({
    required this.label,
    required this.controller,
    this.vorschlag,
    required this.feldName,
    this.bestaetigt = false,
    this.onAnnehmen,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final AiVorschlag<String>? vorschlag;
  final String feldName;
  final bool bestaetigt;
  final VoidCallback? onAnnehmen;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final hasVorschlag = vorschlag?.wert != null;
    final fieldIsEmpty = controller.text.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hasVorschlag && fieldIsEmpty ? vorschlag!.wert : null,
            hintStyle: TextStyle(
              color: _konfidenzColor(vorschlag?.stufe).withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
            suffixIcon: bestaetigt
                ? const Icon(Icons.check_circle,
                    color: AppColors.success, size: 20)
                : null,
          ),
        ),
        if (hasVorschlag && !bestaetigt) ...[
          const SizedBox(height: AppSpacing.xs),
          _AiChip(
            vorschlag: vorschlag!,
            onAnnehmen: onAnnehmen,
          ),
        ],
      ],
    );
  }

  Color _konfidenzColor(KonfidenzStufe? stufe) {
    return switch (stufe) {
      KonfidenzStufe.hoch => AppColors.success,
      KonfidenzStufe.mittel => AppColors.warning,
      KonfidenzStufe.niedrig => AppColors.error,
      _ => AppColors.textSecondary,
    };
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip({required this.vorschlag, this.onAnnehmen});

  final AiVorschlag<String> vorschlag;
  final VoidCallback? onAnnehmen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final konfidenzColor = switch (vorschlag.stufe) {
      KonfidenzStufe.hoch => AppColors.success,
      KonfidenzStufe.mittel => AppColors.warning,
      KonfidenzStufe.niedrig => AppColors.error,
      _ => AppColors.textSecondary,
    };
    final konfidenzLabel = switch (vorschlag.stufe) {
      KonfidenzStufe.hoch => 'KI-Vorschlag (sicher)',
      KonfidenzStufe.mittel => 'KI-Vorschlag (wahrscheinlich)',
      KonfidenzStufe.niedrig => 'KI-Vorschlag (unsicher)',
      _ => 'KI-Vorschlag',
    };

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: konfidenzColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '$konfidenzLabel: „${vorschlag.wert}"',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onAnnehmen != null)
          TextButton(
            onPressed: onAnnehmen,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              minimumSize: const Size(44, 32),
            ),
            child: const Text('Annehmen'),
          ),
      ],
    );
  }
}

class _AiSuggestionSummary extends StatelessWidget {
  const _AiSuggestionSummary({required this.vorschlaege});

  final MetadataVorschlaege vorschlaege;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_outlined,
              size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KI-Erkennung aktiv',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Vorschläge können manuell überschrieben werden. '
                  'Bestätigte Felder werden nicht erneut durch die KI geändert.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
