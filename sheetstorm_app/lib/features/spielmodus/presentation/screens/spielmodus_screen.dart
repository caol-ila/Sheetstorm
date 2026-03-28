import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/annotationen/application/annotation_notifier.dart';
import 'package:sheetstorm/features/annotationen/presentation/widgets/annotation_layer.dart';
import 'package:sheetstorm/features/annotationen/presentation/widgets/layer_toggle_panel.dart';

/// Performance-Modus Screen — Focus-First (ux-design.md § 1.1)
/// - Navigation vollständig ausgeblendet
/// - Asymmetrische Tap-Zonen: 40% zurück / 60% weiter (ux-design.md)
/// - Touch-Targets ≥ 64px im Spielmodus (ux-design.md § 1.2)
/// - Bildschirm-Timeout deaktiviert
/// - Annotation Layer Overlay (SVG-Layer für Echtzeit-Annotationen)
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    // Don't toggle controls if annotation mode is active
    final annotationState = ref.read(annotationProvider(widget.notenId));
    if (annotationState.isAnnotationMode) return;
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final annotationState = ref.watch(annotationProvider(widget.notenId));
    final isAnnotating = annotationState.isAnnotationMode;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // 1. PDF-Viewer placeholder (Hintergrund)
          const Center(
            child: Text(
              '🎵',
              style: TextStyle(fontSize: 64),
            ),
          ),

          // 2. Asymmetrische Tap-Zonen (nur wenn NICHT im Annotationsmodus)
          if (!isAnnotating)
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

          // 3. Annotation Layer (SVG overlay — above PDF, below UI)
          Positioned.fill(
            child: AnnotationLayer(
              stuckId: widget.notenId,
              pageIndex: 0, // TODO: Wire to actual page index
              isDirigent: false, // TODO: Wire to actual role
              stimmeName: null, // TODO: Wire to actual Stimme
            ),
          ),

          // 4. Eingeblendete Controls (nur wenn aktiv UND nicht im Annotationsmodus)
          if (_showControls && !isAnnotating)
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
      builder: (context) => _SpielmodusContextMenu(stuckId: widget.notenId),
    );
  }
}

/// Kontextmenü max. 5 Optionen (decisions.md / ux-design.md)
class _SpielmodusContextMenu extends ConsumerWidget {
  const _SpielmodusContextMenu({required this.stuckId});
  final String stuckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.nights_stay_outlined,
                color: AppColors.darkTextPrimary),
            title: const Text('Nachtmodus',
                style: TextStyle(color: AppColors.darkTextPrimary)),
            onTap: () => Navigator.of(context).pop(),
            minVerticalPadding: AppSpacing.sm,
          ),
          ListTile(
            leading: const Icon(Icons.flip_to_back_outlined,
                color: AppColors.darkTextPrimary),
            title: const Text('Half-Page-Turn',
                style: TextStyle(color: AppColors.darkTextPrimary)),
            onTap: () => Navigator.of(context).pop(),
            minVerticalPadding: AppSpacing.sm,
          ),
          ListTile(
            leading: const Icon(Icons.text_fields,
                color: AppColors.darkTextPrimary),
            title: const Text('Schriftgröße',
                style: TextStyle(color: AppColors.darkTextPrimary)),
            onTap: () => Navigator.of(context).pop(),
            minVerticalPadding: AppSpacing.sm,
          ),
          // Annotations-Layer Toggle (UX-Spec §5.2)
          ListTile(
            leading: const Icon(Icons.layers_outlined,
                color: AppColors.darkTextPrimary),
            title: const Text('Annotations-Layer',
                style: TextStyle(color: AppColors.darkTextPrimary)),
            onTap: () {
              Navigator.of(context).pop();
              _showLayerToggle(context, ref);
            },
            minVerticalPadding: AppSpacing.sm,
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined,
                color: AppColors.darkTextPrimary),
            title: const Text('Helligkeit',
                style: TextStyle(color: AppColors.darkTextPrimary)),
            onTap: () => Navigator.of(context).pop(),
            minVerticalPadding: AppSpacing.sm,
          ),
        ],
      ),
    );
  }

  void _showLayerToggle(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: LayerTogglePanel(stuckId: stuckId),
      ),
    );
  }
}
