import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/performance_mode/data/models/performance_mode_models.dart';

/// Setlist quick-navigation bottom sheet (UX §9).
///
/// Tap on "Stück 3/12" in overlay opens this list.
/// Highlights current piece, allows jumping to any position.
class SetlistNavigationSheet extends StatelessWidget {
  const SetlistNavigationSheet({
    super.key,
    required this.setlist,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final List<SetlistItem> setlist;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Setlist-Navigation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.fontSizeLg,
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Setlist items
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: setlist.length,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = setlist[index];
                final isCurrent = index == currentIndex;

                return ListTile(
                  leading: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCurrent
                          ? AppColors.darkPrimary
                          : Colors.white54,
                      fontSize: AppTypography.fontSizeBase,
                      fontWeight: AppTypography.weightMedium,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.white70,
                      fontWeight: isCurrent
                          ? AppTypography.weightBold
                          : AppTypography.weightNormal,
                    ),
                  ),
                  trailing: isCurrent
                      ? Icon(Icons.play_arrow, color: AppColors.darkPrimary)
                      : null,
                  selected: isCurrent,
                  selectedTileColor: AppColors.darkPrimary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  onTap: () {
                    onItemSelected(index);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
