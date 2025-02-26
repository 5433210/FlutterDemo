import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../theme/app_sizes.dart';

class ImageDropTarget extends StatefulWidget {
  final Widget child;
  final void Function(List<File>) onFilesDropped;

  const ImageDropTarget({
    super.key,
    required this.child,
    required this.onFilesDropped,
  });

  @override
  State<ImageDropTarget> createState() => _ImageDropTargetState();
}

class _ImageDropTargetState extends State<ImageDropTarget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DragTarget<List<String>>(
      onWillAcceptWithDetails: (data) {
        final hasValidFiles = data.data.any((path) {
              final ext = path.toLowerCase();
              return ext.endsWith('.jpg') ||
                  ext.endsWith('.jpeg') ||
                  ext.endsWith('.png') ||
                  ext.endsWith('.webp');
            }) ??
            false;

        setState(() => _isDragging = hasValidFiles);
        return hasValidFiles;
      },
      onAcceptWithDetails: (data) {
        setState(() => _isDragging = false);
        final files = data.data
            .map((path) => File(path))
            .where((file) => file.existsSync())
            .toList();

        if (files.isNotEmpty) {
          HapticFeedback.selectionClick();
          widget.onFilesDropped(files);
        }
      },
      onLeave: (_) => setState(() => _isDragging = false),
      builder: (context, candidateData, rejectedData) {
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (_isDragging)
              Container(
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.l,
                      vertical: AppSizes.m,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSizes.xs),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.file_upload),
                        const SizedBox(height: AppSizes.s),
                        Text(
                          '松开鼠标添加图片',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
