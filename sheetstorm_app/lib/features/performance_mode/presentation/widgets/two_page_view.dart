import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/performance_mode/data/models/performance_mode_models.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/sheet_music_page_view.dart';

/// Two-page (2-Up) view for tablet landscape mode (Spec §5.2).
///
/// Shows two pages side-by-side, each fit-width to half the viewport.
class TwoPageView extends StatelessWidget {
  const TwoPageView({
    super.key,
    required this.leftPage,
    this.rightPage,
    required this.colorMode,
  });

  final SheetPage leftPage;
  final SheetPage? rightPage;
  final ColorMode colorMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left page
        Expanded(
          child: SheetMusicPageView(
            page: leftPage,
            colorMode: colorMode,
          ),
        ),
        // Subtle divider between pages
        Container(
          width: 1,
          color: colorMode == ColorMode.night
              ? Colors.white.withOpacity(0.1)
              : AppColors.border.withOpacity(0.2),
        ),
        // Right page (or empty)
        Expanded(
          child: rightPage != null
              ? SheetMusicPageView(
                  page: rightPage!,
                  colorMode: colorMode,
                )
              : Container(
                  color: colorMode == ColorMode.night
                      ? AppColors.darkBackground
                      : AppColors.background,
                ),
        ),
      ],
    );
  }
}

