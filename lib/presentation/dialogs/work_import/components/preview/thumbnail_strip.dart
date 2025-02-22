import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../theme/app_sizes.dart';

class ThumbnailStrip extends StatelessWidget {
  final List<File> images;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onRemove;
  final void Function(int oldIndex, int newIndex)? onReorder;

  const ThumbnailStrip({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onSelect,
    required this.onRemove,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSizes.m),
        proxyDecorator: (child, _, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Material(
                elevation: 4 * animation.value,
                child: child,
              );
            },
            child: child,
          );
        },
        itemCount: images.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex--;
          onReorder?.call(oldIndex, newIndex);
        },
        itemBuilder: (context, index) => _ThumbnailItem(
          key: ValueKey(images[index].path),
          image: images[index],
          isSelected: index == selectedIndex,
          onTap: () => onSelect(index),
          onRemove: () => onRemove(index),
        ),
      ),
    );
  }
}

class _ThumbnailItem extends StatelessWidget {
  final File image;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ThumbnailItem({
    super.key,
    required this.image,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.xs),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.dividerColor,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(AppSizes.xs),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.xs),
                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        if (isSelected)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filled(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
              iconSize: 16,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                padding: const EdgeInsets.all(4),
                minimumSize: const Size(24, 24),
              ),
            ),
          ),
      ],
    );
  }
}