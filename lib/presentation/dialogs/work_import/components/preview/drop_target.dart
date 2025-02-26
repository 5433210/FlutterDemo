import 'dart:io';

import 'package:flutter/material.dart';

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
        setState(() => _isDragging = true);
        return data.data.isNotEmpty;
      },
      onAcceptWithDetails: (details) {
        setState(() => _isDragging = false);
        final files = details.data.map((path) => File(path)).toList();
        widget.onFilesDropped(files);
      },
      onLeave: (_) {
        setState(() => _isDragging = false);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  _isDragging ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
