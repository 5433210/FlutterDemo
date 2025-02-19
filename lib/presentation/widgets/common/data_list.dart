import 'package:flutter/material.dart';

class DataList extends StatelessWidget {
  final bool isGridView;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double gridSpacing;
  final int gridCrossAxisCount;

  const DataList({
    super.key,
    this.isGridView = true,
    required this.itemCount,
    required this.itemBuilder,
    this.gridSpacing = 16.0,
    this.gridCrossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCrossAxisCount,
          mainAxisSpacing: gridSpacing,
          crossAxisSpacing: gridSpacing,
          childAspectRatio: 1,
        ),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
