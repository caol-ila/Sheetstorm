import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/annotationen/data/models/stamp_catalog.dart';

/// Grid picker for musical stamp annotations (UX-Spec §3.5).
///
/// Organized by category tabs: Dynamik, Artikulation, Atemzeichen, Navigation.
class StampPicker extends StatefulWidget {
  const StampPicker({
    super.key,
    required this.onStampSelected,
  });

  final void Function(String category, String value) onStampSelected;

  @override
  State<StampPicker> createState() => _StampPickerState();
}

class _StampPickerState extends State<StampPicker>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: StampCatalog.categories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(
              fontSize: AppTypography.fontSizeXs,
              fontWeight: AppTypography.weightMedium,
            ),
            tabs: StampCatalog.categories
                .map((c) => Tab(text: c.label))
                .toList(),
          ),
          // Stamp grids
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: StampCatalog.categories
                  .map((category) => _StampGrid(
                        category: category,
                        onSelected: widget.onStampSelected,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StampGrid extends StatelessWidget {
  const _StampGrid({
    required this.category,
    required this.onSelected,
  });

  final StampCategory category;
  final void Function(String category, String value) onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.3,
      ),
      itemCount: category.stamps.length,
      itemBuilder: (_, index) {
        final stamp = category.stamps[index];
        return _StampButton(
          stamp: stamp,
          onTap: () => onSelected(category.id, stamp.value),
        );
      },
    );
  }
}

class _StampButton extends StatelessWidget {
  const _StampButton({
    required this.stamp,
    required this.onTap,
  });

  final StampDefinition stamp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedSm,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: AppSpacing.roundedSm,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Text(
                stamp.display,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
