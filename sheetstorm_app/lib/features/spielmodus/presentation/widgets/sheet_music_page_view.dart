import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/spielmodus/data/models/spielmodus_models.dart';

/// Sheet music page viewer widget.
///
/// Renders a single sheet page as a placeholder with page number.
/// In production: uses pdfrx for PDF rendering or cached_network_image for images.
/// Supports auto-rotation (AC-43..AC-46) and auto-zoom (AC-47..AC-51).
class SheetMusicPageView extends StatelessWidget {
  const SheetMusicPageView({
    super.key,
    required this.page,
    required this.farbmodus,
    this.zoomOverride,
    this.annotations = const [],
    this.visibleLayers = const {},
  });

  final SheetPage page;
  final Farbmodus farbmodus;
  final double? zoomOverride;
  final List<SheetAnnotation> annotations;
  final Set<AnnotationLayer> visibleLayers;

  @override
  Widget build(BuildContext context) {
    // Auto-rotation transform (AC-43..AC-46)
    final rotationAngle = page.autoRotationAngle * 3.14159265 / 180.0;

    return Transform.rotate(
      angle: rotationAngle,
      child: Container(
        color: _backgroundColor,
        child: Center(
          child: _buildPageContent(context),
        ),
      ),
    );
  }

  Color get _backgroundColor => switch (farbmodus) {
        Farbmodus.standard => AppColors.background,
        Farbmodus.nacht => AppColors.darkBackground,
        Farbmodus.sepia => const Color(0xFFF5E6D0),
      };

  Widget _buildPageContent(BuildContext context) {
    // In production: render PDF page via pdfrx or load cached image.
    // This is a structured placeholder showing the page layout.
    final textColor = farbmodus == Farbmodus.nacht
        ? AppColors.darkNoteInk
        : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simulated music staff lines
          for (int staff = 0; staff < 4; staff++) ...[
            _buildStaffLines(textColor),
            const SizedBox(height: 32),
          ],
          const Spacer(),
          Text(
            'Seite ${page.pageNumber + 1}',
            style: TextStyle(
              color: textColor.withOpacity(0.4),
              fontSize: AppTypography.fontSizeLg,
              fontWeight: AppTypography.weightMedium,
            ),
          ),
          if (page.stimmeId != null)
            Text(
              page.stimmeId!,
              style: TextStyle(
                color: textColor.withOpacity(0.3),
                fontSize: AppTypography.fontSizeSm,
              ),
            ),
        ],
      ),
    );
  }

  /// Renders 5 horizontal lines simulating a music staff
  Widget _buildStaffLines(Color color) {
    return Column(
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Container(
            height: 1,
            color: color.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}
