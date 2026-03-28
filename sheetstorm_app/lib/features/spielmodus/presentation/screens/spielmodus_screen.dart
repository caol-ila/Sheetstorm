import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

/// Performance-Modus Screen — Focus-First (ux-design.md § 1.1)
/// - Navigation vollständig ausgeblendet
/// - Asymmetrische Tap-Zonen: 40% zurück / 60% weiter (ux-design.md)
/// - Touch-Targets ≥ 64px im Spielmodus (ux-design.md § 1.2)
/// - Bildschirm-Timeout deaktiviert
class SpielmodusScreen extends ConsumerStatefulWidget {
  const SpielmodusScreen({super.key, required this.notenId});
  final String notenId;

  @override
  ConsumerState<SpielmodusScreen> createState() => _SpielmodusScreenState();
}

class _SpielmodusScreenState extends ConsumerState<SpielmodusScreen> {
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    // Vollbild und Wakelock aktivieren
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // PDF-Viewer placeholder
          const Center(
            child: Text(
              '🎵',
              style: TextStyle(fontSize: 64),
            ),
          ),

          // Asymmetrische Tap-Zonen (40% zurück / 60% weiter)
          Positioned.fill(
            child: Row(
              children: [
                // Zurück-Zone: 40%
                GestureDetector(
                  onTap: () {
                    // TODO: Vorherige Seite / Half-Page-Turn zurück
                  },
                  child: Container(
                    width: screenWidth * 0.40,
                    color: Colors.transparent,
                  ),
                ),
                // Mitte: Controls togglen
                GestureDetector(
                  onTap: _toggleControls,
                  child: Container(
                    width: screenWidth * 0.00,
                    color: Colors.transparent,
                  ),
                ),
                // Weiter-Zone: 60%
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Nächste Seite / Half-Page-Turn weiter
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Eingeblendete Controls (nur wenn aktiv)
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: AppDurations.fast,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Zurück',
                          ),
                          const Spacer(),
                          // Kontextmenü max. 5 Optionen (decisions.md)
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onPressed: () => _showContextMenu(context),
                            tooltip: 'Optionen',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) => const _SpielmodusContextMenu(),
    );
  }
}

/// Kontextmenü max. 5 Optionen (decisions.md / ux-design.md)
class _SpielmodusContextMenu extends StatelessWidget {
  const _SpielmodusContextMenu();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.nights_stay_outlined, 'Nachtmodus'),
      (Icons.flip_to_back_outlined, 'Half-Page-Turn'),
      (Icons.text_fields, 'Schriftgröße'),
      (Icons.layers_outlined, 'Annotations-Layer'),
      (Icons.brightness_6_outlined, 'Helligkeit'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map(
              (item) => ListTile(
                leading: Icon(item.$1, color: AppColors.darkTextPrimary),
                title: Text(
                  item.$2,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                ),
                onTap: () => Navigator.of(context).pop(),
                minVerticalPadding: AppSpacing.sm,
              ),
            )
            .toList(),
      ),
    );
  }
}
