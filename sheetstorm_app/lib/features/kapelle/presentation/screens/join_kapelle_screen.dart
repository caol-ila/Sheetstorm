import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/kapelle/application/kapelle_notifier.dart';
import 'package:sheetstorm/features/kapelle/data/services/kapelle_service.dart';

class JoinKapelleScreen extends ConsumerStatefulWidget {
  const JoinKapelleScreen({super.key});

  @override
  ConsumerState<JoinKapelleScreen> createState() => _JoinKapelleScreenState();
}

class _JoinKapelleScreenState extends ConsumerState<JoinKapelleScreen> {
  final _tokenController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Einladungscode ein.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(kapelleServiceProvider);
      await service.acceptEinladung(token);

      if (!mounted) return;

      await ref.read(kapelleListProvider.notifier).refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erfolgreich beigetreten!')),
      );
      context.go(AppRoutes.kapelle);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Einladung konnte nicht angenommen werden. '
            'Überprüfe den Code und versuche es erneut.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kapelle beitreten')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Icon(
                Icons.mail_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Einladungscode eingeben',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Gib den Einladungscode oder -link ein, '
                'den du von einem Kapellenadmin erhalten hast.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Einladungscode / Link',
                  hintText: 'Code oder Link einfügen',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(AppSpacing.touchTargetMin),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Beitreten'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
