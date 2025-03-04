import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../common/sidebar_toggle.dart';
import './collection_result.dart';
import './collection_tools.dart';

// Toolbar height constant since we can't use kToolbarHeight
const double _toolbarHeight = 48.0;

class CollectionPreview extends StatefulWidget {
  final String workId;
  final List<String> images;

  const CollectionPreview({
    super.key,
    required this.workId,
    required this.images,
  });

  @override
  State<CollectionPreview> createState() => _CollectionPreviewState();
}

class SelectionPainter extends CustomPainter {
  final Offset selectionStart;
  final Offset selectionEnd;
  final List<Rect> selectedAreas;
  final List<Path> lassoSelections;

  SelectionPainter({
    required this.selectionStart,
    required this.selectionEnd,
    required this.selectedAreas,
    required this.lassoSelections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw existing selected areas
    for (final rect in selectedAreas) {
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, strokePaint);
    }

    // Draw current selection rectangle
    final currentRect = Rect.fromPoints(selectionStart, selectionEnd);
    canvas.drawRect(currentRect, paint);
    canvas.drawRect(currentRect, strokePaint);

    // Draw lasso selections
    for (final path in lassoSelections) {
      canvas.drawPath(path, paint);
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) {
    return selectionStart != oldDelegate.selectionStart ||
        selectionEnd != oldDelegate.selectionEnd ||
        selectedAreas != oldDelegate.selectedAreas ||
        lassoSelections != oldDelegate.lassoSelections;
  }
}

class _CollectionPreviewState extends State<CollectionPreview> {
  final TransformationController _transformationController =
      TransformationController();
  late double _currentScale;
  bool _isDragging = false;
  bool _isPanelOpen = true;
  int _currentImageIndex = 0;

  // Image processing controls
  final bool _autoDetectStrokes = true;
  final bool _binarization = false;
  final double _noiseReduction = 0.5;
  final double _grayscale = 0.5;

  // Tool selection
  final SelectionTool _currentSelectionTool = SelectionTool.click;
  final ViewTool _currentViewTool = ViewTool.pan;

  // Selection related variables
  Offset? _selectionStart;
  Offset? _selectionEnd;
  final List<Rect> _selectedAreas = [];
  final List<Path> _lassoSelections = [];
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Main content area
          Expanded(
            child: Column(
              children: [
                _buildImageProcessingToolbar(context),

                // Image preview area
                Expanded(
                  child: Column(
                    children: [
                      // Main preview
                      Expanded(
                        child: GestureDetector(
                          onScaleStart: _handleScaleStart,
                          onScaleUpdate: _handleScaleUpdate,
                          onScaleEnd: _handleScaleEnd,
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 0.5,
                            maxScale: 5.0,
                            child: Stack(
                              children: [
                                // Image
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.white,
                                    child: widget.images.isNotEmpty
                                        ? Image.file(
                                            File(widget
                                                .images[_currentImageIndex]),
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Center(
                                                child: Text('图片加载失败: $error'),
                                              );
                                            },
                                          )
                                        : const Center(
                                            child: Text('无可用图片'),
                                          ),
                                  ),
                                ),
                                // Selection overlays
                                if (_selectionStart != null &&
                                    _selectionEnd != null)
                                  CustomPaint(
                                    painter: SelectionPainter(
                                      selectionStart: _selectionStart!,
                                      selectionEnd: _selectionEnd!,
                                      selectedAreas: _selectedAreas,
                                      lassoSelections: _lassoSelections,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Thumbnail list at bottom
                      if (widget.images.length > 1)
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                              },
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              itemCount: widget.images.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _currentImageIndex = index),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: index == _currentImageIndex
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: Image.file(
                                            File(widget.images[index]),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Center(
                                                child: Icon(Icons.broken_image),
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          right: 4,
                                          top: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sidebar toggle button
          Material(
            elevation: 1,
            child: Container(
              width: 32,
              color: Theme.of(context).colorScheme.surface,
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.center,
              child: SidebarToggle(
                isOpen: _isPanelOpen,
                onToggle: () {
                  setState(() {
                    _isPanelOpen = !_isPanelOpen;
                  });
                },
                alignRight: true,
              ),
            ),
          ),

          // Right panel
          if (_isPanelOpen)
            Container(
              width: 350,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  left: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: const CollectionResult(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentScale = 1.0;
  }

  Widget _buildImageProcessingToolbar(BuildContext context) {
    return Container(height: 1); // Placeholder empty toolbar
  }

  void _finalizeLassoSelection() {
    if (_lassoSelections.isNotEmpty) {
      _lassoSelections.last.close();
    }
  }

  void _finalizeRectangleSelection() {
    final rect = Rect.fromPoints(_selectionStart!, _selectionEnd!);
    setState(() {
      _selectedAreas.add(rect);
    });
  }

  void _handleImageNavigation(bool next) {
    setState(() {
      if (next) {
        _currentImageIndex = (_currentImageIndex + 1) % widget.images.length;
      } else {
        _currentImageIndex = (_currentImageIndex - 1 + widget.images.length) %
            widget.images.length;
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _isDragging = false;
    if (_currentSelectionTool == SelectionTool.rectangle &&
        _selectionStart != null &&
        _selectionEnd != null) {
      _finalizeRectangleSelection();
    } else if (_currentSelectionTool == SelectionTool.lasso &&
        _lassoSelections.isNotEmpty) {
      _finalizeLassoSelection();
    }
    setState(() {
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _isDragging = true;
    if (_currentSelectionTool == SelectionTool.rectangle) {
      _selectionStart = details.localFocalPoint;
    } else if (_currentSelectionTool == SelectionTool.lasso) {
      _lassoSelections.add(Path()
        ..moveTo(details.localFocalPoint.dx, details.localFocalPoint.dy));
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_currentViewTool == ViewTool.zoom) {
      setState(() {
        _currentScale = (_transformationController.value.getMaxScaleOnAxis() *
                details.scale)
            .clamp(0.5, 5.0);
        _transformationController.value = Matrix4.identity()
          ..scale(_currentScale);
      });
    } else if (_currentViewTool == ViewTool.pan) {
      // Handle panning
    } else if (_currentSelectionTool == SelectionTool.rectangle &&
        _selectionStart != null) {
      setState(() {
        _selectionEnd = details.localFocalPoint;
      });
    } else if (_currentSelectionTool == SelectionTool.lasso &&
        _lassoSelections.isNotEmpty) {
      setState(() {
        _lassoSelections.last
            .lineTo(details.localFocalPoint.dx, details.localFocalPoint.dy);
      });
    }
  }
}
