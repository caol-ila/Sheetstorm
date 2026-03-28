import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/kapelle/application/kapelle_notifier.dart';

class CreateKapelleScreen extends ConsumerStatefulWidget {
  const CreateKapelleScreen({super.key});

  @override
  ConsumerState<CreateKapelleScreen> createState() =>
      _CreateKapelleScreenState();
}

class _CreateKapelleScreenState extends ConsumerState<CreateKapelleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _beschreibungController = TextEditingController();
  final _ortController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _beschreibungController.dispose();
    _ortController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final kapelle =
        await ref.read(kapelleListProvider.notifier).createKapelle(
              name: _nameController.text.trim(),
              beschreibung: _beschreibungController.text.trim().isNotEmpty
                  ? _beschreibungController.text.trim()
                  : null,
              ort: _ortController.text.trim().isNotEmpty
                  ? _ortController.text.trim()
                  : null,
            );

    if (!mounted) return;

    if (kapelle != null) {
      context.go(AppRoutes.kapelle);
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kapelle konnte nicht erstellt werden.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Neue Kapelle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'z.B. Musikkapelle Musterstadt',
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Bitte gib einen Namen ein.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _beschreibungController,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung',
                    hintText: 'Optional: Kurze Beschreibung',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 500,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _ortController,
                  decoration: const InputDecoration(
                    labelText: 'Ort',
                    hintText: 'Optional: z.B. Musterstadt',
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  maxLength: 100,
                  onFieldSubmitted: (_) => _submit(),
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
                      : const Text('Kapelle erstellen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
