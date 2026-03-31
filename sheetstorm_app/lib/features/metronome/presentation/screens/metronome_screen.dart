import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/metronome/application/metronome_notifier.dart';
import 'package:sheetstorm/features/metronome/presentation/widgets/conductor_controls.dart';
import 'package:sheetstorm/features/metronome/presentation/widgets/musician_view.dart';

/// Main metronome screen. Shows conductor or musician view based on role.
///
/// The role check is done locally from band membership — no server roundtrip.
class MetronomeScreen extends ConsumerStatefulWidget {
  final bool isConductor;

  const MetronomeScreen({
    super.key,
    this.isConductor = false,
  });

  @override
  ConsumerState<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends ConsumerState<MetronomeScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-join as musician if not conductor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isConductor) {
        ref.read(metronomeProvider.notifier).joinAsMusician();
      }
    });
  }

  @override
  void dispose() {
    // Leave session when navigating away
    ref.read(metronomeProvider.notifier).leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronom'),
      ),
      body: widget.isConductor
          ? const ConductorControls()
          : const MusicianView(),
    );
  }
}
