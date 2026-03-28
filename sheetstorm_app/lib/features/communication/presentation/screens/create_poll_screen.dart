import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/communication/application/poll_notifier.dart';

class CreatePollScreen extends ConsumerStatefulWidget {
  const CreatePollScreen({
    required this.bandId,
    super.key,
  });

  final String bandId;

  @override
  ConsumerState<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends ConsumerState<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isAnonymous = true;
  bool _isMultiSelect = false;
  bool _showResultsAfterVoting = true;
  int _deadlineDays = 7;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Umfrage'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'Frage *',
              style: TextStyle(
                fontSize: AppTypography.fontSizeBase,
                fontWeight: AppTypography.weightBold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                hintText: 'Welcher Termin passt euch am besten?',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte gib eine Frage ein';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Optionen *',
              style: TextStyle(
                fontSize: AppTypography.fontSizeBase,
                fontWeight: AppTypography.weightBold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._buildOptions(),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Option hinzufügen'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Einstellungen',
              style: TextStyle(
                fontSize: AppTypography.fontSizeBase,
                fontWeight: AppTypography.weightBold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildDeadlineSelector(),
            SwitchListTile(
              title: const Text('Anonyme Abstimmung'),
              subtitle:
                  const Text('Namen der Teilnehmer werden nicht angezeigt'),
              value: _isAnonymous,
              onChanged: (value) => setState(() => _isAnonymous = value),
            ),
            SwitchListTile(
              title: const Text('Mehrfachauswahl'),
              subtitle: const Text('Teilnehmer können mehrere Optionen wählen'),
              value: _isMultiSelect,
              onChanged: (value) => setState(() => _isMultiSelect = value),
            ),
            SwitchListTile(
              title: const Text('Ergebnisse sofort anzeigen'),
              subtitle: const Text('Ergebnisse werden während der Abstimmung gezeigt'),
              value: _showResultsAfterVoting,
              onChanged: (value) =>
                  setState(() => _showResultsAfterVoting = value),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPoll,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Umfrage erstellen'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptions() {
    return List.generate(_optionControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _optionControllers[index],
                decoration: InputDecoration(
                  hintText: 'Option ${index + 1}',
                  border: const OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte gib eine Option ein';
                  }
                  return null;
                },
              ),
            ),
            if (_optionControllers.length > 2) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: () => _removeOption(index),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildDeadlineSelector() {
    return ListTile(
      title: const Text('Ablaufdatum'),
      subtitle: Text(
        _deadlineDays == 0 ? 'Kein Ablauf' : 'In $_deadlineDays Tagen',
      ),
      trailing: DropdownButton<int>(
        value: _deadlineDays,
        onChanged: (value) {
          if (value != null) {
            setState(() => _deadlineDays = value);
          }
        },
        items: const [
          DropdownMenuItem(value: 1, child: Text('1 Tag')),
          DropdownMenuItem(value: 3, child: Text('3 Tage')),
          DropdownMenuItem(value: 7, child: Text('7 Tage')),
          DropdownMenuItem(value: 14, child: Text('14 Tage')),
          DropdownMenuItem(value: 30, child: Text('30 Tage')),
          DropdownMenuItem(value: 0, child: Text('Kein Ablauf')),
        ],
      ),
    );
  }

  void _addOption() {
    if (_optionControllers.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximal 10 Optionen erlaubt')),
      );
      return;
    }
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _submitPoll() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens 2 Optionen erforderlich')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final deadline = _deadlineDays > 0
        ? DateTime.now().add(Duration(days: _deadlineDays))
        : null;

    final poll = await ref
        .read(pollListProvider(widget.bandId).notifier)
        .createPoll(
          question: question,
          options: options,
          deadline: deadline,
          isAnonymous: _isAnonymous,
          isMultiSelect: _isMultiSelect,
          showResultsAfterVoting: _showResultsAfterVoting,
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (poll != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Umfrage erfolgreich erstellt')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Erstellen der Umfrage')),
      );
    }
  }
}
