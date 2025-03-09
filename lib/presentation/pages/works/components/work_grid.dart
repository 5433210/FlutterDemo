import 'package:demo/domain/models/work/work_entity.dart';
import 'package:flutter/material.dart';

import '../../../widgets/common/grid_placeholder.dart';
import 'work_card.dart';

class WorkGrid extends StatelessWidget {
  final List<WorkEntity> works;
  final Function(WorkEntity) onWorkTap;
  final bool isLoading;

  const WorkGrid({
    super.key,
    required this.works,
    required this.onWorkTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal grid dimensions
        final double width = constraints.maxWidth;
        final int crossAxisCount = _calculateCrossAxisCount(width);
        final double itemWidth = width / crossAxisCount;
        final double itemHeight = itemWidth * 1.4; // 10:14 aspect ratio

        // Apply padding for smaller screens
        final double padding = width < 600 ? 8.0 : 16.0;

        return GridView.builder(
          padding: EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: padding,
            mainAxisSpacing: padding,
          ),
          itemCount: works.length,
          cacheExtent: 500, // Increase cache to reduce rebuilds when scrolling
          itemBuilder: (context, index) {
            // Use indexed key to ensure proper recycling
            return WorkCard(
              key: ValueKey('work-${works[index].id}'),
              work: works[index],
              onTap: () => onWorkTap(works[index]),
            );
          },
        );
      },
    );
  }

  // Calculate optimal number of columns based on screen width
  int _calculateCrossAxisCount(double width) {
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }
}

// A placeholder grid to show while loading
class WorkGridPlaceholder extends StatelessWidget {
  final int itemCount;

  const WorkGridPlaceholder({
    super.key,
    this.itemCount = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = _calculateCrossAxisCount(width);
        final double itemWidth = width / crossAxisCount;
        final double itemHeight = itemWidth * 1.4;
        final double padding = width < 600 ? 8.0 : 16.0;

        return GridView.builder(
          padding: EdgeInsets.all(padding),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: padding,
            mainAxisSpacing: padding,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return const GridPlaceholder();
          },
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }
}
