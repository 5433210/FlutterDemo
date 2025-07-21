import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';

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
                final allPaths = detail.files.map((file) => file.path).toList();

                // Filter out directories and only keep files
                final filePaths = <String>[];
                for (final path in allPaths) {
                  final file = File(path);
                  final directory = Directory(path);

                  if (file.existsSync() && !directory.existsSync()) {
                    // It's a file, add it to the list
                    filePaths.add(path);
                  } else if (directory.existsSync()) {
                    // It's a directory, log a warning but don't process
                    AppLogger.warning('拖拽的目录将被忽略: $path');
                  }
                }

                // Only process if we have valid files
                if (filePaths.isNotEmpty) {
                  widget.onFilesDropped(filePaths);
                } else if (allPaths.isNotEmpty) {
                  // All dropped items were directories, show a user-friendly message
                  AppLogger.info('拖拽的项目中没有可导入的文件，目录需要通过"导入文件夹"功能处理');
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
                            AppLocalizations.of(context).dropToImportImages,
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
