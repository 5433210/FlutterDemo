import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../domain/models/work/work_image.dart';

class ThumbnailStrip extends StatefulWidget {
  final List<WorkImage> images;
  final int selectedIndex;
  final Function(int) onTap;
  final bool isEditable;
  final Function(int, int)? onReorder;

  const ThumbnailStrip({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onTap,
    this.isEditable = false,
    this.onReorder,
  });

  @override
  State<ThumbnailStrip> createState() => _ThumbnailStripState();
}

class _ThumbnailStripState extends State<ThumbnailStrip> {
  final Map<String, bool> _fileExistsCache = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.isEditable) {
      // 非编辑模式：普通的滚动列表
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.images.length,
        itemBuilder: (context, index) => _buildThumbnail(context, index, theme),
      );
    }

    // 编辑模式：可重排序的列表
    return ReorderableListView(
      scrollDirection: Axis.horizontal,
      onReorder: (oldIndex, newIndex) {
        if (widget.onReorder != null) {
          widget.onReorder!(oldIndex, newIndex);
        }
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              elevation: 8.0 * animation.value,
              child: child,
            );
          },
          child: child,
        );
      },
      children: List.generate(
        widget.images.length,
        (index) => _buildThumbnail(context, index, theme),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkImageFiles();
  }

  Widget _buildThumbnail(BuildContext context, int index, ThemeData theme) {
    final image = widget.images[index];
    final isSelected = index == widget.selectedIndex;
    final fileExists = _fileExistsCache[image.id] ?? false;

    return GestureDetector(
      key: ValueKey(image.id),
      onTap: () => widget.onTap(index),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            if (fileExists)
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.file(
                  File(image.path),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image,
                          size: 32, color: Colors.grey),
                    );
                  },
                ),
              )
            else
              const Center(
                child: Icon(Icons.image_not_supported,
                    size: 32, color: Colors.grey),
              ),

            // Index label
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            // Selected indicator
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),

            // Drag handle in edit mode
            if (widget.isEditable)
              Positioned(
                bottom: 4,
                right: 4,
                child: Icon(
                  Icons.drag_handle,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

            // Error indicator
            if (!fileExists)
              Center(
                child: Tooltip(
                  message: '图片文件不存在',
                  child: Icon(
                    Icons.error_outline,
                    size: 24,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkImageFiles() async {
    for (final image in widget.images) {
      try {
        final file = File(image.path);
        _fileExistsCache[image.id] = await file.exists();
      } catch (e) {
        _fileExistsCache[image.id] = false;
      }
    }
    if (mounted) {
      setState(() {});
    }
  }
}
