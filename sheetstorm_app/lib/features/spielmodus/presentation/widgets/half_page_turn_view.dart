import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/spielmodus/data/models/spielmodus_models.dart';
import 'package:sheetstorm/features/spielmodus/presentation/widgets/sheet_music_page_view.dart';

/// Half-Page-Turn widget (AC-13..AC-20, UX §5).
///
/// Shows bottom half of current page + top half of next page,
/// preventing the "page-jump-shock" during page turns.
/// Supports configurable split ratio (40/60, 50/50, 60/40).
class HalfPageTurnView extends StatelessWidget {
  const HalfPageTurnView({
    super.key,
    required this.currentPage,
    this.nextPage,
    required this.farbmodus,
    this.splitRatio = 0.5,
    this.showDivider = true,
  });

  final SheetPage currentPage;
  final SheetPage? nextPage;
  final Farbmodus farbmodus;

  /// Split ratio: 0.4, 0.5, or 0.6 (AC-17)
  final double splitRatio;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final topHeight = totalHeight * splitRatio;
        final bottomHeight = totalHeight * (1 - splitRatio);

        return Column(
          children: [
            // Top half: bottom portion of current page
            SizedBox(
              height: topHeight,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: splitRatio,
                  child: SheetMusicPageView(
                    page: currentPage,
                    farbmodus: farbmodus,
                  ),
                ),
              ),
            ),

            // Subtle divider line (AC-14)
            if (showDivider) _buildDivider(),

            // Bottom half: top portion of next page
            SizedBox(
              height: bottomHeight - (showDivider ? 1 : 0),
              child: nextPage != null
                  ? ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: 1 - splitRatio,
                        child: SheetMusicPageView(
                          page: nextPage!,
                          farbmodus: farbmodus,
                        ),
                      ),
                    )
                  : _buildEmptyHalf(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDivider() {
    // Night mode: dimmed orange for warmth (UX §5.3)
    final color = farbmodus == Farbmodus.nacht
        ? const Color(0x40D97706)
        : AppColors.border.withOpacity(0.3);

    return Container(height: 1, color: color);
  }

  Widget _buildEmptyHalf() {
    final bgColor = farbmodus == Farbmodus.nacht
        ? AppColors.darkBackground
        : AppColors.background;
    return Container(color: bgColor);
  }
}
