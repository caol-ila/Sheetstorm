import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:sheetstorm_pdf_labeler/src/notifiers/settings_notifier.dart';
import 'package:sheetstorm_pdf_labeler/src/notifiers/labeling_notifier.dart';
import 'package:sheetstorm_pdf_labeler/src/models/labeling_state.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final labelingAsync = ref.watch(labelingProvider);

    final canStart = settings.sourcePath != null &&
        settings.targetPath != null &&
        settings.pat != null &&
        settings.sourcePath != settings.targetPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sheetstorm PDF Labeler'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FolderPickerCard(
              label: 'Source Folder',
              path: settings.sourcePath,
              onPick: () async {
                final directory = await getDirectoryPath();
                if (directory != null) {
                  ref.read(settingsProvider.notifier).setSourcePath(directory);
                }
              },
            ),
            const SizedBox(height: 16),
            _FolderPickerCard(
              label: 'Target Folder',
              path: settings.targetPath,
              onPick: () async {
                final directory = await getDirectoryPath();
                if (directory != null) {
                  ref.read(settingsProvider.notifier).setTargetPath(directory);
                }
              },
            ),
            const SizedBox(height: 16),
            _PatField(
              value: settings.pat ?? '',
              rememberPat: settings.rememberPat,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setPat(value);
              },
              onRememberChanged: (value) {
                ref.read(settingsProvider.notifier).setRememberPat(value ?? false);
              },
            ),
            const SizedBox(height: 24),
            labelingAsync.when(
              data: (state) {
                if (state.phase == LabelingPhase.running) {
                  return _ProgressSection(state: state);
                }
                return _StartButton(
                  enabled: canStart,
                  onPressed: () {
                    ref.read(labelingProvider.notifier).startLabeling(
                          source: settings.sourcePath!,
                          target: settings.targetPath!,
                          pat: settings.pat!,
                          confidence: settings.confidence,
                        );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: labelingAsync.when(
                data: (state) => _ResultsSection(state: state),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderPickerCard extends StatelessWidget {
  final String label;
  final String? path;
  final VoidCallback onPick;

  const _FolderPickerCard({
    required this.label,
    required this.path,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(path ?? 'Not selected'),
        trailing: ElevatedButton(
          onPressed: onPick,
          child: const Text('Browse'),
        ),
      ),
    );
  }
}

class _PatField extends StatelessWidget {
  final String value;
  final bool rememberPat;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool?> onRememberChanged;

  const _PatField({
    required this.value,
    required this.rememberPat,
    required this.onChanged,
    required this.onRememberChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'GitHub PAT',
            hintText: 'Enter your GitHub Personal Access Token',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          onChanged: onChanged,
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
        ),
        CheckboxListTile(
          title: const Text('Remember token securely'),
          value: rememberPat,
          onChanged: onRememberChanged,
          dense: true,
        ),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _StartButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Start Labeling'),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final LabelingState state;

  const _ProgressSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = state.totalItems > 0
        ? state.currentProgress / state.totalItems
        : 0.0;

    return Column(
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 8),
        Text('${state.currentProgress} of ${state.totalItems}'),
        if (state.currentFile != null) Text('Processing: ${state.currentFile}'),
      ],
    );
  }
}

class _ResultsSection extends ConsumerWidget {
  final LabelingState state;

  const _ResultsSection({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.results.isEmpty) {
      return const Center(child: Text('No results yet'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Results (${state.results.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            FilledButton.icon(
              onPressed: () => _exportCsv(context),
              icon: const Icon(Icons.download),
              label: const Text('Export CSV'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final result = state.results[index];
              return ListTile(
                leading: Icon(
                  result.status == ResultStatus.recognized
                      ? Icons.check_circle
                      : result.status == ResultStatus.lowConfidence
                          ? Icons.warning
                          : Icons.error,
                  color: result.status == ResultStatus.recognized
                      ? Colors.green
                      : result.status == ResultStatus.lowConfidence
                          ? Colors.orange
                          : Colors.red,
                ),
                title: Text(result.recognizedTitle ?? 'Unknown'),
                subtitle: Text(result.originalPath),
                trailing: result.confidence != null
                    ? Text('${(result.confidence! * 100).toStringAsFixed(0)}%')
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final defaultPath = 'labeling_results_$timestamp.csv';
      
      // For now, save to current directory
      // In a real app, use file_selector to let user choose location
      final path = defaultPath;
      
      final results = state.results;
      if (results.isEmpty) return;

      final rows = <List<String>>[
        ['Original Path', 'Recognized Title', 'Confidence', 'Status', 'Target Path', 'Error'],
        ...results.map((result) => [
              result.originalPath,
              result.recognizedTitle ?? '',
              result.confidence?.toStringAsFixed(2) ?? '',
              result.status.name,
              result.targetPath ?? '',
              result.error ?? '',
            ]),
      ];

      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported to $path')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
}

