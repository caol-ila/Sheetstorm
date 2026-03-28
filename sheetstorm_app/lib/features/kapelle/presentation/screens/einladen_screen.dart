import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/kapelle/application/einladungen_notifier.dart';
import 'package:sheetstorm/features/kapelle/data/models/kapelle_models.dart';

enum _EinladungsModus { email, link }

class EinladenScreen extends ConsumerStatefulWidget {
  const EinladenScreen({super.key, required this.kapelleId});

  final String kapelleId;

  @override
  ConsumerState<EinladenScreen> createState() => _EinladenScreenState();
}

class _EinladenScreenState extends ConsumerState<EinladenScreen> {
  _EinladungsModus _modus = _EinladungsModus.email;
  final _emailController = TextEditingController();
  final _nachrichtController = TextEditingController();
  KapelleRolle _rolle = KapelleRolle.musiker;
  int _ablaufTage = 7;
  bool _isSubmitting = false;
  String? _generatedLink;

  @override
  void dispose() {
    _emailController.dispose();
    _nachrichtController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib eine E-Mail-Adresse ein.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final einladung = await ref
        .read(einladungenProvider(widget.kapelleId).notifier)
        .createEmail(
          email: email,
          rolle: _rolle,
          ablaufTage: _ablaufTage,
          nachricht: _nachrichtController.text.trim().isNotEmpty
              ? _nachrichtController.text.trim()
              : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (einladung != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Einladung an $email gesendet.')),
      );
      _emailController.clear();
      _nachrichtController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Einladung konnte nicht erstellt werden.'),
        ),
      );
    }
  }

  Future<void> _generateLink() async {
    setState(() {
      _isSubmitting = true;
      _generatedLink = null;
    });

    final einladung = await ref
        .read(einladungenProvider(widget.kapelleId).notifier)
        .createLink(rolle: _rolle, ablaufTage: _ablaufTage);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (einladung != null) {
      setState(() => _generatedLink = einladung.link);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link konnte nicht generiert werden.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Einladen')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mode toggle
              SegmentedButton<_EinladungsModus>(
                segments: const [
                  ButtonSegment(
                    value: _EinladungsModus.email,
                    label: Text('Per E-Mail'),
                    icon: Icon(Icons.email_outlined),
                  ),
                  ButtonSegment(
                    value: _EinladungsModus.link,
                    label: Text('Per Link'),
                    icon: Icon(Icons.link),
                  ),
                ],
                selected: {_modus},
                onSelectionChanged: (s) => setState(() {
                  _modus = s.first;
                  _generatedLink = null;
                }),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Role picker
              DropdownButtonFormField<KapelleRolle>(
                initialValue: _rolle,
                decoration: const InputDecoration(
                  labelText: 'Rolle',
                ),
                items: KapelleRolle.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _rolle = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Expiry picker
              DropdownButtonFormField<int>(
                initialValue: _ablaufTage,
                decoration: const InputDecoration(
                  labelText: 'Gültigkeit',
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 Tag')),
                  DropdownMenuItem(value: 7, child: Text('7 Tage')),
                  DropdownMenuItem(value: 14, child: Text('14 Tage')),
                  DropdownMenuItem(value: 30, child: Text('30 Tage')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _ablaufTage = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              if (_modus == _EinladungsModus.email) ...[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail-Adresse *',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _nachrichtController,
                  decoration: const InputDecoration(
                    labelText: 'Nachricht (optional)',
                    hintText: 'Persönliche Nachricht zur Einladung',
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitEmail,
                  style: FilledButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(AppSpacing.touchTargetMin),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Einladung senden'),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _generateLink,
                  style: FilledButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(AppSpacing.touchTargetMin),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: const Text('Link generieren'),
                ),
                if (_generatedLink != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Einladungslink',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: AppSpacing.roundedSm,
                            ),
                            child: Text(
                              _generatedLink!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _generatedLink!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Link kopiert!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Link kopieren'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
