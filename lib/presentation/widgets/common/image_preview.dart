import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// 定义字符区域数据结构
class CharacterRegion {
  final String id;
  final int pageIndex;
  Rect rect;
  double rotation;
  bool isSelected;
  bool isSaved;
  final DateTime createTime;

  CharacterRegion({
    String? id,
    required this.pageIndex,
    required this.rect,
    this.rotation = 0.0,
    this.isSelected = false,
    this.isSaved = false,
    DateTime? createTime,
  })  : id = id ?? const Uuid().v4(),
        createTime = createTime ?? DateTime.now();

  // 转换为数据库格式的 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': pageIndex,
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
      'rotation': rotation,
      'createTime': createTime.toIso8601String(),
    };
  }
}

class ImagePreview extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final Function(int)? onIndexChanged;
  final bool showThumbnails;
  final bool enableZoom;
  final BoxDecoration? previewDecoration;
  final EdgeInsets? padding;
  final List<CharacterRegion>? collectedRegions;
  final Function(CharacterRegion)? onRegionCreated;
  final Function(CharacterRegion)? onRegionSelected;
  final Function(List<CharacterRegion>)? onRegionsDeleted;

  const ImagePreview({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.showThumbnails = true,
    this.enableZoom = true,
    this.previewDecoration,
    this.padding,
    this.collectedRegions,
    this.onRegionCreated,
    this.onRegionSelected,
    this.onRegionsDeleted,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class SelectionPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  SelectionPainter({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) {
    return start != oldDelegate.start ||
        end != oldDelegate.end ||
        color != oldDelegate.color;
  }
}

class _ImagePreviewState extends State<ImagePreview> {
  // 用于调整大小的句柄区域
  static const double _handleSize = 8.0;
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;
  bool _isBoxSelectionMode = false;
  Offset? _selectionStart;
  Offset? _selectionCurrent;
  final List<CharacterRegion> _selectedRegions = [];

  CharacterRegion? _resizingRegion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        children: [
          // 工具栏
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isBoxSelectionMode ? Icons.crop_din : Icons.crop_free,
                  color: _isBoxSelectionMode
                      ? Theme.of(context).primaryColor
                      : null,
                ),
                onPressed: () {
                  setState(() {
                    _isBoxSelectionMode = !_isBoxSelectionMode;
                    if (!_isBoxSelectionMode) {
                      _clearSelection();
                    }
                  });
                },
                tooltip: '框选工具',
              ),
              if (_selectedRegions.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    if (widget.onRegionsDeleted != null) {
                      widget.onRegionsDeleted!(_selectedRegions);
                    }
                    setState(() {
                      _selectedRegions.clear();
                    });
                  },
                  tooltip: '删除选中区域',
                ),
              ],
            ],
          ),

          // 主预览区域
          Expanded(
            child: Container(
              decoration: widget.previewDecoration ??
                  BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
              child: widget.imagePaths.isNotEmpty
                  ? GestureDetector(
                      onPanStart: _isBoxSelectionMode ? _handlePanStart : null,
                      onPanUpdate:
                          _isBoxSelectionMode ? _handlePanUpdate : null,
                      onPanEnd: _isBoxSelectionMode ? _handlePanEnd : null,
                      onSecondaryTapDown: (_) {
                        setState(() {
                          _isBoxSelectionMode = false;
                          _clearSelection();
                        });
                      },
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        boundaryMargin: const EdgeInsets.all(20.0),
                        minScale: 0.1,
                        maxScale: 10.0, // 最大放大10倍
                        constrained: widget.enableZoom,
                        child: Stack(
                          children: [
                            Center(
                              child: Image.file(
                                File(widget.imagePaths[_currentIndex]),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.broken_image,
                                            size: 64, color: Colors.red),
                                        SizedBox(height: 16),
                                        Text('图片加载失败',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            // 已收集的字符区域
                            if (widget.collectedRegions != null)
                              ...widget.collectedRegions!
                                  .where((region) =>
                                      region.pageIndex == _currentIndex)
                                  .map((region) => _buildRegionBox(region)),
                            // 当前选择框
                            if (_selectionStart != null &&
                                _selectionCurrent != null)
                              CustomPaint(
                                painter: SelectionPainter(
                                  start: _selectionStart!,
                                  end: _selectionCurrent!,
                                  color: Colors.blue,
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : const Center(child: Text('没有图片')),
            ),
          ),

          // 缩略图列表
          if (widget.showThumbnails && widget.imagePaths.length > 1) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: MouseRegion(
                cursor: _isDragging
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.grab,
                child: Listener(
                  onPointerDown: (_) => setState(() => _isDragging = true),
                  onPointerUp: (_) => setState(() => _isDragging = false),
                  onPointerSignal: (signal) {
                    if (signal is PointerScrollEvent &&
                        _scrollController.hasClients) {
                      _scrollController.animateTo(
                        (_scrollController.offset + signal.scrollDelta.dy * 0.5)
                            .clamp(0.0,
                                _scrollController.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.imagePaths.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentIndex = index;
                                if (widget.onIndexChanged != null) {
                                  widget.onIndexChanged!(index);
                                }
                              });
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: index == _currentIndex
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey.shade300,
                                      width: index == _currentIndex ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Image.file(
                                    File(widget.imagePaths[index]),
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
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
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  Widget _buildRegionBox(CharacterRegion region) {
    final isSelected = _selectedRegions.contains(region);
    return Positioned.fromRect(
      rect: region.rect,
      child: Transform.rotate(
        angle: region.rotation,
        child: GestureDetector(
          onTap: () {
            if (_isBoxSelectionMode) return;
            setState(() {
              if (isSelected) {
                _selectedRegions.remove(region);
              } else {
                _selectedRegions.add(region);
                if (widget.onRegionSelected != null) {
                  widget.onRegionSelected!(region);
                }
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Colors.blue
                    : region.isSaved
                        ? Colors.green
                        : Colors.blue,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                if (isSelected) ...[
                  // 调整大小的句柄
                  ...List.generate(8, (index) {
                    final isHorizontal = index % 2 == 0;
                    final isVertical = index % 2 == 1;
                    return Positioned(
                      left: index < 4 ? 0 : null,
                      top: index < 2 || index > 5 ? 0 : null,
                      right: index >= 4 ? 0 : null,
                      bottom: index >= 2 && index <= 5 ? 0 : null,
                      child: GestureDetector(
                        onPanUpdate: (details) =>
                            _handleResize(details, index, region),
                        child: Container(
                          width: _handleSize,
                          height: _handleSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.blue),
                          ),
                          child: MouseRegion(
                            cursor: isHorizontal
                                ? SystemMouseCursors.resizeLeftRight
                                : isVertical
                                    ? SystemMouseCursors.resizeUpDown
                                    : SystemMouseCursors.resizeUpLeftDownRight,
                            child: Container(),
                          ),
                        ),
                      ),
                    );
                  }),
                  // 旋转句柄
                  Positioned(
                    top: -20,
                    right: -20,
                    child: GestureDetector(
                      onPanUpdate: (details) => _handleRotate(details, region),
                      child: Container(
                        width: _handleSize,
                        height: _handleSize,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectionStart = null;
      _selectionCurrent = null;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_selectionStart != null && _selectionCurrent != null) {
      final rect = Rect.fromPoints(_selectionStart!, _selectionCurrent!);
      if (rect.width > 10 && rect.height > 10) {
        final region = CharacterRegion(
          pageIndex: _currentIndex,
          rect: rect,
        );
        if (widget.onRegionCreated != null) {
          widget.onRegionCreated!(region);
        }
      }
    }
    _clearSelection();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _selectionStart = details.localPosition;
      _selectionCurrent = details.localPosition;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _selectionCurrent = details.localPosition;
    });
  }

  void _handleResize(
      DragUpdateDetails details, int handleIndex, CharacterRegion region) {
    setState(() {
      final delta = details.delta;
      double newLeft = region.rect.left;
      double newTop = region.rect.top;
      double newWidth = region.rect.width;
      double newHeight = region.rect.height;

      switch (handleIndex) {
        case 0: // 左上
          newLeft += delta.dx;
          newTop += delta.dy;
          newWidth -= delta.dx;
          newHeight -= delta.dy;
          break;
        case 1: // 上
          newTop += delta.dy;
          newHeight -= delta.dy;
          break;
        case 2: // 右上
          newWidth += delta.dx;
          newTop += delta.dy;
          newHeight -= delta.dy;
          break;
        case 3: // 右
          newWidth += delta.dx;
          break;
        case 4: // 右下
          newWidth += delta.dx;
          newHeight += delta.dy;
          break;
        case 5: // 下
          newHeight += delta.dy;
          break;
        case 6: // 左下
          newLeft += delta.dx;
          newWidth -= delta.dx;
          newHeight += delta.dy;
          break;
        case 7: // 左
          newLeft += delta.dx;
          newWidth -= delta.dx;
          break;
      }

      if (newWidth > 20 && newHeight > 20) {
        region.rect = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
      }
    });
  }

  void _handleRotate(DragUpdateDetails details, CharacterRegion region) {
    setState(() {
      final center = region.rect.center;
      final angle = math.atan2(
        details.localPosition.dy - center.dy,
        details.localPosition.dx - center.dx,
      );
      region.rotation = angle;
    });
  }
}
