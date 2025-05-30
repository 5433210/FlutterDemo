import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../../../infrastructure/logging/logger.dart';

/// A wrapper widget that enables system file drop capabilities for desktop platforms
class DesktopDropWrapper extends StatefulWidget {
  final Widget child;
  final Function(List<String> files) onFilesDropped;
  final bool showDropIndicator;

  const DesktopDropWrapper({
    Key? key,
    required this.child,
    required this.onFilesDropped,
    this.showDropIndicator = true,
  }) : super(key: key);

  @override
  State<DesktopDropWrapper> createState() => _DesktopDropWrapperState();
}

class _DesktopDropWrapperState extends State<DesktopDropWrapper> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: DropTarget(
            onDragDone: (detail) {
              try {
                // Extract file paths from the drag operation
                final fileNames =
                    detail.files.map((file) => file.path).toList();

                // Only process if we have valid files
                if (fileNames.isNotEmpty) {
                  widget.onFilesDropped(fileNames);
                }
              } catch (e) {
                AppLogger.error('DesktopDropWrapper error in onDragDone: $e');
              } finally {
                // Ensure dragging state is reset
                setState(() {
                  _isDragging = false;
                });
              }
            },
            onDragEntered: (_) {
              setState(() {
                _isDragging = true;
              });
            },
            onDragExited: (_) {
              setState(() {
                _isDragging = false;
              });
            },
            child: _isDragging && widget.showDropIndicator
                ? Container(
                    color: Colors.blue.withValues(alpha: 0.2),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.file_upload,
                            size: 64,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '释放鼠标以导入图片',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
