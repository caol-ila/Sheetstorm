import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/metronome/application/metronome_notifier.dart';

/// BPM picker with slider, stepper, and tap tempo.
class BpmPicker extends ConsumerStatefulWidget {
  const BpmPicker({super.key});

  @override
  ConsumerState<BpmPicker> createState() => _BpmPickerState();
}

class _BpmPickerState extends ConsumerState<BpmPicker> {
  final List<DateTime> _tapTimes = [];
  static const _minBpm = 20.0;
  static const _maxBpm = 300.0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metronomeProvider);
    final notifier = ref.read(metronomeProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BPM display
        GestureDetector(
          onTap: () => _showBpmInput(context, state.bpm, notifier),
          child: Semantics(
            label: '${state.bpm} BPM',
            child: Column(
              children: [
                Text(
                  '${state.bpm}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'BPM',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Stepper + Slider row
        Row(
          children: [
            // [--] button
            _StepperButton(
              icon: Icons.keyboard_double_arrow_left,
              onPressed: () => notifier.setBpm(state.bpm - 5),
              semanticsLabel: 'BPM minus 5',
            ),
            // [-] button
            _StepperButton(
              icon: Icons.chevron_left,
              onPressed: () => notifier.setBpm(state.bpm - 1),
              semanticsLabel: 'BPM minus 1',
            ),

            // Slider
            Expanded(
              child: Slider(
                value: state.bpm.toDouble(),
                min: _minBpm,
                max: _maxBpm,
                divisions: (_maxBpm - _minBpm).toInt(),
                label: '${state.bpm}',
                onChanged: (value) => notifier.setBpm(value.round()),
              ),
            ),

            // [+] button
            _StepperButton(
              icon: Icons.chevron_right,
              onPressed: () => notifier.setBpm(state.bpm + 1),
              semanticsLabel: 'BPM plus 1',
            ),
            // [++] button
            _StepperButton(
              icon: Icons.keyboard_double_arrow_right,
              onPressed: () => notifier.setBpm(state.bpm + 5),
              semanticsLabel: 'BPM plus 5',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tap Tempo button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _onTapTempo,
            icon: const Icon(Icons.music_note),
            label: const Text('Tap Tempo'),
          ),
        ),
      ],
    );
  }

  void _onTapTempo() {
    final now = DateTime.now();
    _tapTimes.add(now);

    // Remove taps older than 2 seconds
    _tapTimes.removeWhere(
        (t) => now.difference(t) > const Duration(seconds: 2));

    if (_tapTimes.length >= 3) {
      // Calculate average interval
      final intervals = <int>[];
      for (var i = 1; i < _tapTimes.length; i++) {
        intervals
            .add(_tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds);
      }
      final avgInterval =
          intervals.reduce((a, b) => a + b) / intervals.length;
      final bpm = (60000 / avgInterval).round().clamp(20, 300);

      ref.read(metronomeProvider.notifier).setBpm(bpm);
    }
  }

  void _showBpmInput(
      BuildContext context, int currentBpm, MetronomeNotifier notifier) {
    final controller = TextEditingController(text: '$currentBpm');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('BPM eingeben'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'BPM',
            hintText: '20–300',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                notifier.setBpm(value);
              }
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticsLabel;

  const _StepperButton({
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: semanticsLabel,
      ),
    );
  }
}
