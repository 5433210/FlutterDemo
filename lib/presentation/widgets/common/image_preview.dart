import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/character_region.dart';
import 'region_painter.dart';

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

class _ImagePreviewState extends State<ImagePreview> {
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;
  bool _isBoxSelectionMode = false;
  Offset? _selectionStart;
  Offset? _selectionCurrent;
  CharacterRegion? _selectedRegion;

  int? _resizeHandleIndex;
  bool _isRotating = false;
  double _rotationStartAngle = 0;
  Offset? _rotationCenter;

  // 拖动相关变量
  Offset? _dragStartOffset;
  Rect? _dragStartRect;

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
              if (_selectedRegion != null) ...[
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    if (widget.onRegionsDeleted != null) {
                      widget.onRegionsDeleted!([_selectedRegion!]);
                    }
                    setState(() {
                      _selectedRegion = null;
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
                  ? MouseRegion(
                      cursor: _getCursor(),
                      child: GestureDetector(
                        onTapDown: _handleTapDown,
                        onTapUp: _handleTapUp,
                        onPanStart: _isBoxSelectionMode
                            ? _handlePanStart
                            : _handleRegionStart,
                        onPanUpdate: _isBoxSelectionMode
                            ? _handlePanUpdate
                            : _handleRegionUpdate,
                        onPanEnd: _isBoxSelectionMode
                            ? _handlePanEnd
                            : _handleRegionEnd,
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
                          maxScale: 10.0,
                          constrained: widget.enableZoom,
                          child: Stack(
                            children: [
                              // 主图片
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
                                    .map((region) => CustomPaint(
                                          painter: RegionPainter(
                                            region: region,
                                            isSelected:
                                                region == _selectedRegion,
                                          ),
                                        )),

                              // 当前选择框
                              if (_selectionStart != null &&
                                  _selectionCurrent != null)
                                CustomPaint(
                                  painter: RegionPainter(
                                    selectionStart: _selectionStart,
                                    selectionEnd: _selectionCurrent,
                                    isSelecting: true,
                                  ),
                                ),
                            ],
                          ),
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

  void _clearSelection() {
    setState(() {
      _selectionStart = null;
      _selectionCurrent = null;
    });
  }

  MouseCursor _getCursor() {
    if (_isBoxSelectionMode) {
      return SystemMouseCursors.precise;
    }

    if (_selectedRegion != null) {
      if (_resizeHandleIndex != null) {
        final isHorizontal = _resizeHandleIndex! % 2 == 0;
        final isVertical = _resizeHandleIndex! % 2 == 1;
        if (isHorizontal) return SystemMouseCursors.resizeLeftRight;
        if (isVertical) return SystemMouseCursors.resizeUpDown;
        return SystemMouseCursors.resizeUpLeftDownRight;
      }
      if (_isRotating) return SystemMouseCursors.grab;
      if (_dragStartOffset != null) return SystemMouseCursors.move;
      return SystemMouseCursors.click;
    }

    return SystemMouseCursors.basic;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_selectionStart != null && _selectionCurrent != null) {
      final rect = Rect.fromPoints(_selectionStart!, _selectionCurrent!);
      if (rect.width > 10 && rect.height > 10) {
        final region = CharacterRegion(
          pageIndex: _currentIndex,
          rect: rect,
          imagePath: widget.imagePaths[_currentIndex],
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

  void _handleRegionEnd(DragEndDetails details) {
    _resizeHandleIndex = null;
    _isRotating = false;
    _rotationStartAngle = 0;
    _rotationCenter = null;
    _dragStartOffset = null;
    _dragStartRect = null;
  }

  void _handleRegionStart(DragStartDetails details) {
    if (_selectedRegion == null) return;

    final painter = RegionPainter(region: _selectedRegion, isSelected: true);
    final handleIndex = painter.getHandleAtPoint(
      details.localPosition,
      _selectedRegion!.rect,
    );

    if (handleIndex != null) {
      _resizeHandleIndex = handleIndex;
    } else if (painter.isRotationHandle(
        details.localPosition, _selectedRegion!.rect)) {
      _isRotating = true;
      _rotationStartAngle = _selectedRegion!.rotation;
      _rotationCenter = _selectedRegion!.rect.center;
    } else if (_selectedRegion!.rect.contains(details.localPosition)) {
      _dragStartOffset = details.localPosition;
      _dragStartRect = _selectedRegion!.rect;
    }
  }

  void _handleRegionUpdate(DragUpdateDetails details) {
    if (_selectedRegion == null) return;
    setState(() {
      if (_resizeHandleIndex != null) {
        _handleResize(details, _resizeHandleIndex!, _selectedRegion!);
      } else if (_isRotating) {
        _handleRotate(details, _selectedRegion!);
      } else if (_dragStartOffset != null && _dragStartRect != null) {
        final delta = details.localPosition - _dragStartOffset!;
        _selectedRegion!.rect = _dragStartRect!.translate(delta.dx, delta.dy);
      }
    });
  }

  void _handleResize(
      DragUpdateDetails details, int handleIndex, CharacterRegion region) {
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
  }

  void _handleRotate(DragUpdateDetails details, CharacterRegion region) {
    if (_rotationCenter == null) return;

    final angle = math.atan2(
      details.localPosition.dy - _rotationCenter!.dy,
      details.localPosition.dx - _rotationCenter!.dx,
    );
    region.rotation = angle;
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isBoxSelectionMode) return;

    final tappedRegions = widget.collectedRegions
        ?.where((region) =>
            region.pageIndex == _currentIndex &&
            region.rect.contains(details.localPosition))
        .toList();

    final tappedRegion =
        tappedRegions?.isNotEmpty == true ? tappedRegions!.first : null;

    setState(() {
      _selectedRegion = tappedRegion;
      if (tappedRegion != null && widget.onRegionSelected != null) {
        widget.onRegionSelected!(tappedRegion);
      }
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isBoxSelectionMode) return;

    final tappedRegions = widget.collectedRegions
        ?.where((region) =>
            region.pageIndex == _currentIndex &&
            region.rect.contains(details.localPosition))
        .toList();

    if (tappedRegions?.isEmpty ?? true) {
      setState(() {
        _selectedRegion = null;
      });
    }
  }
}
