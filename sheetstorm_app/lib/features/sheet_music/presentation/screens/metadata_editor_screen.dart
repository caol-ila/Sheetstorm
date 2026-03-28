import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/sheet_music/application/import_notifier.dart';
import 'package:sheetstorm/features/sheet_music/data/models/import_models.dart';

/// Per-song metadata editor with AI suggestion display.
/// Shows one song at a time; user navigates through all songs.
class MetadataEditorScreen extends ConsumerStatefulWidget {
  const MetadataEditorScreen({
    super.key,
    required this.uploadId,
    required this.pieceIndex,
  });

  final String uploadId;
  final int pieceIndex;

  @override
  ConsumerState<MetadataEditorScreen> createState() =>
      _MetadataEditorScreenState();
}

class _MetadataEditorScreenState extends ConsumerState<MetadataEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _composerCtrl;
  late TextEditingController _arrangerCtrl;
  late TextEditingController _musicalKeyCtrl;
  late TextEditingController _timeSignatureCtrl;
  late TextEditingController _genreCtrl;

  // Fields that the user has manually confirmed
  final Set<String> _confirmed = {};

  TempPiece? _lastPiece;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _composerCtrl = TextEditingController();
    _arrangerCtrl = TextEditingController();
    _musicalKeyCtrl = TextEditingController();
    _timeSignatureCtrl = TextEditingController();
    _genreCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromState());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _composerCtrl.dispose();
    _arrangerCtrl.dispose();
    _musicalKeyCtrl.dispose();
    _timeSignatureCtrl.dispose();
    _genreCtrl.dispose();
    super.dispose();
  }

  void _syncFromState() {
    final current = ref.read(importProvider);
    if (current is! ImportEditingMetadata) return;
    final piece = current.currentPiece;

    if (_lastPiece?.tempId == piece.tempId) return;
    _lastPiece = piece;

    _titleCtrl.text = piece.title ?? '';
    _composerCtrl.text = piece.composer ?? '';
    _arrangerCtrl.text = piece.arranger ?? '';
    _musicalKeyCtrl.text = piece.musicalKey ?? '';
    _timeSignatureCtrl.text = piece.timeSignature ?? '';
    _genreCtrl.text = piece.genre ?? '';
    _confirmed
      ..clear()
      ..addAll(piece.fieldsConfirmed);
  }

  void _saveAndNavigate(bool forward) {
    if (!_formKey.currentState!.validate()) return;
    _persistToNotifier();

    if (forward) {
      ref.read(importProvider.notifier).nextPiece();
    } else {
      ref.read(importProvider.notifier).previousPiece();
    }
  }

  void _persistToNotifier() {
    ref.read(importProvider.notifier).updateMetadata(
          title: _titleCtrl.text.trim().isNotEmpty
              ? _titleCtrl.text.trim()
              : null,
          composer: _composerCtrl.text.trim().isNotEmpty
              ? _composerCtrl.text.trim()
              : null,
          arranger: _arrangerCtrl.text.trim().isNotEmpty
              ? _arrangerCtrl.text.trim()
              : null,
          musicalKey: _musicalKeyCtrl.text.trim().isNotEmpty
              ? _musicalKeyCtrl.text.trim()
              : null,
          timeSignature: _timeSignatureCtrl.text.trim().isNotEmpty
              ? _timeSignatureCtrl.text.trim()
              : null,
          genre: _genreCtrl.text.trim().isNotEmpty
              ? _genreCtrl.text.trim()
              : null,
          fieldsConfirmed: Set.from(_confirmed),
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
    final piece = editing.currentPiece;
    final v = piece.suggestions;

    return Scaffold(
      appBar: AppBar(
        title: Text('Stück ${editing.currentIndex + 1} von ${editing.pieces.length}'),
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
              ref.read(importProvider.notifier).goToSummary();
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
            _PieceProgress(
              current: editing.currentIndex + 1,
              total: editing.pieces.length,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Page thumbnails row ───────────────────────────────────────
            _PageStrip(
              pageIds: piece.pageIds,
              pages: editing.pages,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Metadata fields ───────────────────────────────────────────
            _MetadataField(
              label: 'Titel *',
              controller: _titleCtrl,
              suggestion: v?.title,
              fieldName: 'title',
              confirmed: _confirmed.contains('title'),
              onAccept: () {
                if (v?.title?.value != null) {
                  setState(() {
                    _titleCtrl.text = v!.title!.value!;
                    _confirmed.add('title');
                  });
                }
              },
              validator: (val) => null, // Title can be empty (defaults to "Unbekannt")
            ),
            const SizedBox(height: AppSpacing.md),

            _MetadataField(
              label: 'Komponist',
              controller: _composerCtrl,
              suggestion: v?.composer,
              fieldName: 'composer',
              confirmed: _confirmed.contains('composer'),
              onAccept: () {
                if (v?.composer?.value != null) {
                  setState(() {
                    _composerCtrl.text = v!.composer!.value!;
                    _confirmed.add('composer');
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),

            _MetadataField(
              label: 'Arrangeur',
              controller: _arrangerCtrl,
              fieldName: 'arranger',
              confirmed: _confirmed.contains('arranger'),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _MetadataField(
                    label: 'Tonart',
                    controller: _musicalKeyCtrl,
                    suggestion: v?.musicalKey,
                    fieldName: 'musical_key',
                    confirmed: _confirmed.contains('musical_key'),
                    onAccept: () {
                      if (v?.musicalKey?.value != null) {
                        setState(() {
                          _musicalKeyCtrl.text = v!.musicalKey!.value!;
                          _confirmed.add('musical_key');
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetadataField(
                    label: 'Taktart',
                    controller: _timeSignatureCtrl,
                    suggestion: v?.timeSignature,
                    fieldName: 'time_signature',
                    confirmed: _confirmed.contains('time_signature'),
                    onAccept: () {
                      if (v?.timeSignature?.value != null) {
                        setState(() {
                          _timeSignatureCtrl.text = v!.timeSignature!.value!;
                          _confirmed.add('time_signature');
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
              fieldName: 'genre',
              confirmed: _confirmed.contains('genre'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── AI Suggestion summary ─────────────────────────────────────
            if (v != null) _AiSuggestionSummary(suggestions: v),

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

class _PieceProgress extends StatelessWidget {
  const _PieceProgress({required this.current, required this.total});

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

class _PageStrip extends StatelessWidget {
  const _PageStrip({required this.pageIds, required this.pages});

  final List<String> pageIds;
  final List<PageInfo> pages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pagesToShow = pageIds.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${pageIds.length} Seite(n)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pagesToShow.length + (pageIds.length > 6 ? 1 : 0),
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
                    '+${pageIds.length - 6}',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }
              final id = pagesToShow[idx];
              final page = pages.where((s) => s.pageId == id).firstOrNull;
              return Container(
                width: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  page != null ? '${page.pageNumber}' : '?',
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
    this.suggestion,
    required this.fieldName,
    this.confirmed = false,
    this.onAccept,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final AiSuggestion<String>? suggestion;
  final String fieldName;
  final bool confirmed;
  final VoidCallback? onAccept;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final hasVorschlag = suggestion?.value != null;
    final fieldIsEmpty = controller.text.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hasVorschlag && fieldIsEmpty ? suggestion!.value : null,
            hintStyle: TextStyle(
              color: _confidenceColor(suggestion?.stufe).withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
            suffixIcon: confirmed
                ? const Icon(Icons.check_circle,
                    color: AppColors.success, size: 20)
                : null,
          ),
        ),
        if (hasVorschlag && !confirmed) ...[
          const SizedBox(height: AppSpacing.xs),
          _AiChip(
            suggestion: suggestion!,
            onAccept: onAccept,
          ),
        ],
      ],
    );
  }

  Color _confidenceColor(ConfidenceLevel? stufe) {
    return switch (stufe) {
      ConfidenceLevel.high => AppColors.success,
      ConfidenceLevel.medium => AppColors.warning,
      ConfidenceLevel.low => AppColors.error,
      _ => AppColors.textSecondary,
    };
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip({required this.suggestion, this.onAccept});

  final AiSuggestion<String> suggestion;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidenceColor = switch (suggestion.stufe) {
      ConfidenceLevel.high => AppColors.success,
      ConfidenceLevel.medium => AppColors.warning,
      ConfidenceLevel.low => AppColors.error,
      _ => AppColors.textSecondary,
    };
    final confidenceLabel = switch (suggestion.stufe) {
      ConfidenceLevel.high => 'KI-Vorschlag (sicher)',
      ConfidenceLevel.medium => 'KI-Vorschlag (wahrscheinlich)',
      ConfidenceLevel.low => 'KI-Vorschlag (unsicher)',
      _ => 'KI-Vorschlag',
    };

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: confidenceColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '$confidenceLabel: „${suggestion.value}"',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onAccept != null)
          TextButton(
            onPressed: onAccept,
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
  const _AiSuggestionSummary({required this.suggestions});

  final MetadataSuggestions suggestions;

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
