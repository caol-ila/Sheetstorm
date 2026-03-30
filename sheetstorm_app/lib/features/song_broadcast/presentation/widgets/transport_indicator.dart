// Small status widget showing the active broadcast transport type.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sheetstorm/features/song_broadcast/application/broadcast_notifier.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';

class TransportIndicator extends ConsumerWidget {
  const TransportIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transportType =
        ref.watch(broadcastProvider.select((s) => s.activeTransport));

    return switch (transportType) {
      TransportType.ble => const _TransportChip(
          icon: Icons.bluetooth,
          label: 'BLE',
          color: Colors.blue,
        ),
      TransportType.signalR => const _TransportChip(
          icon: Icons.wifi,
          label: 'Server',
          color: Colors.green,
        ),
      TransportType.none => const _TransportChip(
          icon: Icons.warning_amber_rounded,
          label: 'Offline',
          color: Colors.orange,
        ),
    };
  }
}

class _TransportChip extends StatelessWidget {
  const _TransportChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
