import 'dart:io';

import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../common/sidebar_toggle.dart';
import './collection_tools.dart';

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
      child: Column(
        children: [
          // Image navigation toolbar
          Container(
            height: kToolbarHeight - 8,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '第 ${_currentImageIndex + 1}/${widget.images.length} 页',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.navigate_before),
                  onPressed: _currentImageIndex > 0
                      ? () => _handleImageNavigation(false)
                      : null,
                  tooltip: '上一页',
                ),
                IconButton(
                  icon: const Icon(Icons.navigate_next),
                  onPressed: _currentImageIndex < widget.images.length - 1
                      ? () => _handleImageNavigation(true)
                      : null,
                  tooltip: '下一页',
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Row(
              children: [
                // Image preview
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
                                      File(widget.images[_currentImageIndex]),
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
                          if (_selectionStart != null && _selectionEnd != null)
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

                // Right panel toggle button
                SidebarToggle(
                  isOpen: _isPanelOpen,
                  onToggle: () {
                    setState(() {
                      _isPanelOpen = !_isPanelOpen;
                    });
                  },
                  alignRight: true,
                ),
              ],
            ),
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
