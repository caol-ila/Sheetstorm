import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/band/application/invitations_notifier.dart';
import 'package:sheetstorm/features/band/data/models/band_models.dart';

enum _InvitationMode { email, link }

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key, required this.bandId});

  final String bandId;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  _InvitationMode _mode = _InvitationMode.email;
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  BandRole _role = BandRole.musician;
  int _expiryDays = 7;
  bool _isSubmitting = false;
  String? _generatedLink;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
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

    final invitation = await ref
        .read(invitationsProvider(widget.bandId).notifier)
        .createEmail(
          email: email,
          role: _role,
          expiryDays: _expiryDays,
          message: _messageController.text.trim().isNotEmpty
              ? _messageController.text.trim()
              : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (invitation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Einladung an $email gesendet.')),
      );
      _emailController.clear();
      _messageController.clear();
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

    final invitation = await ref
        .read(invitationsProvider(widget.bandId).notifier)
        .createLink(role: _role, expiryDays: _expiryDays);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (invitation != null) {
      setState(() => _generatedLink = invitation.link);
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
              SegmentedButton<_InvitationMode>(
                segments: const [
                  ButtonSegment(
                    value: _InvitationMode.email,
                    label: Text('Per E-Mail'),
                    icon: Icon(Icons.email_outlined),
                  ),
                  ButtonSegment(
                    value: _InvitationMode.link,
                    label: Text('Per Link'),
                    icon: Icon(Icons.link),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() {
                  _mode = s.first;
                  _generatedLink = null;
                }),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Role picker
              DropdownButtonFormField<BandRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Rolle',
                ),
                items: BandRole.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Expiry picker
              DropdownButtonFormField<int>(
                initialValue: _expiryDays,
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
                  if (v != null) setState(() => _expiryDays = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              if (_mode == _InvitationMode.email) ...[
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
                  controller: _messageController,
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
