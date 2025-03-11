import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../infrastructure/image/character_image_processor.dart';
import 'character_preview_panel.dart';
import 'region_painter.dart';
import 'region_properties_dialog.dart';

class CharacterExtractionPreview extends StatefulWidget {
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
  final String? workId;

  const CharacterExtractionPreview({
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
    this.workId,
  });

  @override
  State<CharacterExtractionPreview> createState() =>
      _CharacterExtractionPreviewState();
}

class _CharacterExtractionPreviewState extends State<CharacterExtractionPreview>
    with WidgetsBindingObserver {
  static const double _minRegionSize = 20.0;
  static const double _minZoomScale = 0.1;
  static const double _maxZoomScale = 10.0;
  static const EdgeInsets _viewerPadding = EdgeInsets.all(20.0);

  final TransformationController _transformationController =
      TransformationController();
  final ScrollController _scrollController = ScrollController();
  final Set<CharacterRegion> _selectedRegions = {};

  final _state = _PreviewState();
  late final CharacterRepository _repository;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main image preview area (takes 75% of the width)
        Expanded(
          flex: 75,
          child: Column(
            children: [
              _buildToolbar(),
              Expanded(
                child: _buildPreviewArea(),
              ),
            ],
          ),
        ),

        // Right preview panel (takes 25% of the width)
        SizedBox(
          width: 300, // Fixed width for preview panel
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CharacterPreviewPanel(
              region: _state.selectedRegion,
              label: _state.selectedRegion?.label,
              onClear: () {
                if (_state.selectedRegion == null) return;
                _handleRegionOperation(() {
                  _preserveAndUpdateState(() {
                    _state.selectedRegion = _state.selectedRegion!.copyWith(
                      isSaved: false,
                    );
                    if (widget.onRegionSelected != null) {
                      widget.onRegionSelected!(_state.selectedRegion!);
                    }
                  });
                  return Future<void>.value();
                }, errorMessage: '清除失败');
              },
              onSave: () => _showSaveDialog(_state.selectedRegion),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
    } else if (state == AppLifecycleState.resumed) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transformationController.dispose();
    _scrollController.dispose();
    _selectedRegions.clear();
    _state.reset();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeRepository();
    _state.currentIndex = widget.initialIndex;
  }

  void _announceStateChange(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  Widget _buildBoxSelectionTool() {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: '框选工具',
        value: _state.isBoxSelectionMode ? '已开启' : '未开启',
        hint: _state.isBoxSelectionMode ? '点击关闭框选模式' : '点击开启框选模式',
        enabled: true,
        child: IconButton(
          icon: Icon(
            _state.isBoxSelectionMode ? Icons.crop_din : Icons.crop_free,
            color: _state.isBoxSelectionMode
                ? Theme.of(context).primaryColor
                : null,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            _preserveAndUpdateState(() {
              _state.isBoxSelectionMode = !_state.isBoxSelectionMode;
              if (!_state.isBoxSelectionMode) {
                _clearSelection();
              }
              _announceStateChange(
                  '框选工具${_state.isBoxSelectionMode ? '已开启' : '已关闭'}');
            });
          },
          tooltip: '框选工具',
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: '删除选中区域',
        value: '${_selectedRegions.length}个区域',
        hint: '点击删除所有选中的区域',
        enabled: true,
        child: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _deleteSelectedRegions,
          tooltip: '删除选中区域',
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return MouseRegion(
      cursor: _getCursor(),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onDoubleTap: _handleDoubleTap,
        onPanStart:
            _state.isBoxSelectionMode ? _handlePanStart : _handleRegionStart,
        onPanUpdate:
            _state.isBoxSelectionMode ? _handlePanUpdate : _handleRegionUpdate,
        onPanEnd: _state.isBoxSelectionMode ? _handlePanEnd : _handleRegionEnd,
        onSecondaryTapDown: (_) {
          HapticFeedback.lightImpact();
          _cleanupState();
          _announceStateChange('清除所有状态');
        },
        child: InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: _viewerPadding,
          minScale: _minZoomScale,
          maxScale: _maxZoomScale,
          constrained: widget.enableZoom,
          child: Stack(
            children: [
              Center(child: _buildMainImage()),
              if (widget.collectedRegions != null) ..._buildRegions(),
              if (_state.selectionStart != null &&
                  _state.selectionCurrent != null)
                _buildSelectionOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainImage() {
    return Image.file(
      File(widget.imagePaths[_state.currentIndex]),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        _showErrorMessage('图片加载失败');
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('图片加载失败', style: TextStyle(color: Colors.red)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMultiSelectTool() {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: '多选工具',
        value: _state.isMultiSelectMode ? '已开启' : '未开启',
        hint: _state.isMultiSelectMode ? '点击关闭多选模式' : '点击开启多选模式',
        enabled: true,
        child: IconButton(
          icon: Icon(
            _state.isMultiSelectMode ? Icons.select_all : Icons.touch_app,
            color: _state.isMultiSelectMode
                ? Theme.of(context).primaryColor
                : null,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            _preserveAndUpdateState(() {
              _state.isMultiSelectMode = !_state.isMultiSelectMode;
              if (!_state.isMultiSelectMode) {
                _selectedRegions.clear();
                _state.selectedRegion = null;
              }
              _announceStateChange(
                  '多选模式${_state.isMultiSelectMode ? '已开启' : '已关闭'}');
            });
          },
          tooltip: '多选工具',
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Container(
      decoration: widget.previewDecoration ??
          BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
      child: widget.imagePaths.isNotEmpty
          ? _buildImageViewer()
          : const Center(child: Text('没有图片')),
    );
  }

  List<Widget> _buildRegions() {
    return widget.collectedRegions
            ?.where((region) => region.pageIndex == _state.currentIndex)
            .map((region) => MergeSemantics(
                  child: Semantics(
                    label: region.label ?? '未命名区域',
                    selected: _selectedRegions.contains(region),
                    enabled: true,
                    hint: _selectedRegions.contains(region)
                        ? '双击编辑区域属性'
                        : '点击选择区域',
                    value: _getRegionDescription(region),
                    child: ExcludeSemantics(
                      child: CustomPaint(
                        painter: RegionPainter(
                          region: region,
                          isSelected: _selectedRegions.contains(region),
                        ),
                      ),
                    ),
                  ),
                ))
            .toList() ??
        [];
  }

  Widget _buildSelectionCount() {
    return MergeSemantics(
      child: Semantics(
        label: '已选择区域数量',
        value: '${_selectedRegions.length}个',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '已选择: ${_selectedRegions.length}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionOverlay() {
    return CustomPaint(
      painter: RegionPainter(
        selectionStart: _state.selectionStart,
        selectionEnd: _state.selectionCurrent,
        isSelecting: true,
      ),
    );
  }

  Widget _buildToolbar() {
    return MergeSemantics(
      child: Semantics(
        container: true,
        label: '工具栏',
        child: Row(
          children: [
            _buildBoxSelectionTool(),
            _buildMultiSelectTool(),
            if (_selectedRegions.isNotEmpty) ...[
              _buildDeleteButton(),
              _buildSelectionCount(),
            ],
          ],
        ),
      ),
    );
  }

  void _cleanupState() {
    setState(() {
      _state.reset();
      _selectedRegions.clear();
    });
  }

  void _clearSelection() {
    setState(() {
      _state.selectionStart = null;
      _state.selectionCurrent = null;
      _state.selectedRegion = null;
      _selectedRegions.clear();
    });
  }

  Future<void> _deleteSelectedRegions() async {
    if (_selectedRegions.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除选中的${_selectedRegions.length}个区域吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _showProcessingIndicator();
    try {
      await _repository.deleteMany(
          _selectedRegions.map((region) => region.label ?? '').toList());

      _preserveAndUpdateState(() {
        if (widget.onRegionsDeleted != null) {
          widget.onRegionsDeleted!(_selectedRegions.toList());
        }
        _selectedRegions.clear();
        _state.selectedRegion = null;
        _announceStateChange('删除成功');
      });
    } catch (e) {
      _showErrorMessage('删除失败: $e');
    } finally {
      _hideProcessingIndicator();
    }
  }

  MouseCursor _getCursor() {
    if (_state.isBoxSelectionMode) {
      return SystemMouseCursors.precise;
    } else if (_state.resizeHandleIndex != null) {
      return SystemMouseCursors.resizeUpDown;
    } else if (_state.isRotating) {
      return SystemMouseCursors.grab;
    }
    return SystemMouseCursors.basic;
  }

  String _getRegionDescription(CharacterRegion region) {
    final size = '${region.rect.width.toInt()}×${region.rect.height.toInt()}';
    final position =
        '位置(${region.rect.left.toInt()}, ${region.rect.top.toInt()})';
    return '${region.label ?? "未命名区域"}, 大小$size, $position';
  }

  void _handleDoubleTap() async {
    if (_state.selectedRegion == null) return;
    await _showSaveDialog(_state.selectedRegion);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_state.isBoxSelectionMode) return;

    if (_state.selectionStart != null && _state.selectionCurrent != null) {
      final rect =
          Rect.fromPoints(_state.selectionStart!, _state.selectionCurrent!);

      if (rect.width >= _minRegionSize && rect.height >= _minRegionSize) {
        final region = CharacterRegion(
          pageIndex: _state.currentIndex,
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          imagePath: widget.imagePaths[_state.currentIndex],
        );

        if (widget.onRegionCreated != null) {
          widget.onRegionCreated!(region);
          _announceStateChange('已创建新区域');
        }

        _preserveAndUpdateState(() {
          _state.selectedRegion = region;
          _selectedRegions.clear();
          _selectedRegions.add(region);
        });
      } else {
        _announceStateChange('选择区域太小');
      }
    }

    _preserveAndUpdateState(() {
      _state.selectionStart = null;
      _state.selectionCurrent = null;
    });
  }

  void _handlePanStart(DragStartDetails details) {
    if (!_state.isBoxSelectionMode) return;

    _preserveAndUpdateState(() {
      _state.selectionStart = details.localPosition;
      _state.selectionCurrent = details.localPosition;
      HapticFeedback.selectionClick();
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_state.isBoxSelectionMode) return;

    _preserveAndUpdateState(() {
      _state.selectionCurrent = details.localPosition;
    });
  }

  void _handleRegionEnd(DragEndDetails details) {
    if (_state.selectedRegion == null) return;

    _preserveAndUpdateState(() {
      if (_state.isRotating) {
        _announceStateChange('完成旋转');
      } else if (_state.resizeHandleIndex != null) {
        _announceStateChange('完成调整大小');
      } else if (_state.dragStartOffset != null) {
        _announceStateChange('完成移动');
      }

      _state.resetManipulation();
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _handleRegionOperation(Future<void> Function() operation,
      {String? errorMessage}) {
    return operation().catchError((error) async {
      _showErrorMessage(errorMessage ?? '操作失败: $error');
      return Future<void>.value(); // Explicitly return a completed Future<void>
    });
  }

  void _handleRegionStart(DragStartDetails details) {
    if (_state.selectedRegion == null) return;

    final region = _state.selectedRegion!;
    final painter = RegionPainter(region: region, isSelected: true);

    final handleIndex =
        painter.getHandleAtPoint(details.localPosition, region.rect);

    if (handleIndex != null || region.rect.contains(details.localPosition)) {
      HapticFeedback.selectionClick();
    }

    _preserveAndUpdateState(() {
      if (handleIndex != null) {
        _state.resizeHandleIndex = handleIndex;
        _announceStateChange('开始调整区域大小');
      } else if (painter.isRotationHandle(details.localPosition, region.rect)) {
        _state.isRotating = true;
        _state.rotationStartAngle = region.rotation;
        _state.rotationCenter = region.rect.center;
        _announceStateChange('开始旋转区域');
      } else if (region.rect.contains(details.localPosition)) {
        _state.dragStartOffset = details.localPosition;
        _state.dragStartRect = region.rect;
        _announceStateChange('开始移动区域');
      }
    });
  }

  void _handleRegionUpdate(DragUpdateDetails details) {
    if (_state.selectedRegion == null) return;

    _preserveAndUpdateState(() {
      if (_state.resizeHandleIndex != null) {
        _handleResize(details, _state.selectedRegion!);
      } else if (_state.isRotating && _state.rotationCenter != null) {
        _handleRotate(details, _state.selectedRegion!);
      } else if (_state.dragStartOffset != null &&
          _state.dragStartRect != null) {
        final delta = details.localPosition - _state.dragStartOffset!;
        final rect = _state.dragStartRect!.translate(delta.dx, delta.dy);
        _state.selectedRegion = _state.selectedRegion!.copyWith(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
        );
      }
    });
  }

  void _handleResize(DragUpdateDetails details, CharacterRegion region) {
    if (_state.resizeHandleIndex == null) return;

    final delta = details.delta;
    double newLeft = region.rect.left;
    double newTop = region.rect.top;
    double newWidth = region.rect.width;
    double newHeight = region.rect.height;

    switch (_state.resizeHandleIndex!) {
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

    if (newWidth >= _minRegionSize && newHeight >= _minRegionSize) {
      _state.selectedRegion = region.copyWith(
        left: newLeft,
        top: newTop,
        width: newWidth,
        height: newHeight,
      );
    }
  }

  void _handleRotate(DragUpdateDetails details, CharacterRegion region) {
    if (_state.rotationCenter == null) return;

    final angle = math.atan2(
      details.localPosition.dy - _state.rotationCenter!.dy,
      details.localPosition.dx - _state.rotationCenter!.dx,
    );

    _state.selectedRegion = region.copyWith(rotation: angle);
  }

  void _handleTapDown(TapDownDetails details) {
    if (_state.isBoxSelectionMode) return;

    final tappedRegions = widget.collectedRegions
        ?.where((region) =>
            region.pageIndex == _state.currentIndex &&
            region.rect.contains(details.localPosition))
        .toList();

    final tappedRegion =
        tappedRegions?.isNotEmpty == true ? tappedRegions!.first : null;

    if (tappedRegion != null) {
      HapticFeedback.selectionClick();
    }

    _preserveAndUpdateState(() {
      if (_state.isMultiSelectMode && tappedRegion != null) {
        if (_selectedRegions.contains(tappedRegion)) {
          _selectedRegions.remove(tappedRegion);
          _announceStateChange('取消选择: ${_getRegionDescription(tappedRegion)}');
        } else {
          _selectedRegions.add(tappedRegion);
          _announceStateChange('选择: ${_getRegionDescription(tappedRegion)}');
        }
        _state.selectedRegion = tappedRegion;
      } else {
        _selectedRegions.clear();
        _state.selectedRegion = tappedRegion;
        if (tappedRegion != null) {
          _selectedRegions.add(tappedRegion);
          _announceStateChange('选择: ${_getRegionDescription(tappedRegion)}');
        }
      }

      if (tappedRegion != null && widget.onRegionSelected != null) {
        widget.onRegionSelected!(tappedRegion);
      }
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (_state.isBoxSelectionMode) return;

    final tappedRegions = widget.collectedRegions
        ?.where((region) =>
            region.pageIndex == _state.currentIndex &&
            region.rect.contains(details.localPosition))
        .toList();

    if (tappedRegions?.isEmpty ?? true) {
      _preserveAndUpdateState(() {
        if (!_state.isMultiSelectMode) {
          _state.selectedRegion = null;
          _selectedRegions.clear();
          _announceStateChange('清除选择');
        }
      });
    }
  }

  void _hideProcessingIndicator() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _initializeRepository() async {
    // Get repository from the provider without using watch
  }

  void _preserveAndUpdateState(VoidCallback operation) {
    setState(operation);
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showProcessingIndicator() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在处理...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSaveDialog(CharacterRegion? region) async {
    if (region == null) return;

    _handleRegionOperation(() async {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => RegionPropertiesDialog(
          region: region,
          onSave: (label, color) async {
            try {
              _showProcessingIndicator();

              // 处理图片
              final processor = CharacterImageProcessor();
              const outputDir = '';
              final charId = label ?? DateTime.now().toIso8601String();

              final paths = await processor.processCharacterImage(
                sourcePath: region.imagePath,
                outputDir: outputDir,
                charId: charId,
                region: region.rect,
                rotation: region.rotation,
                erasePoints: _state.erasePoints,
              );

              _preserveAndUpdateState(() {
                _state.selectedRegion = region.copyWith(
                  label: label,
                  color: color,
                  isSaved: true,
                );

                // 清除擦除点
                _state.erasePoints = null;

                if (widget.onRegionSelected != null) {
                  widget.onRegionSelected!(_state.selectedRegion!);
                }
              });

              _announceStateChange('集字已保存: $label');
              Navigator.of(context).pop({'saved': true, 'paths': paths});
            } catch (e) {
              _showErrorMessage('保存失败: $e');
            } finally {
              _hideProcessingIndicator();
            }
          },
        ),
      );

      if (result?['saved'] == true) {
        setState(() {});
      }
    }, errorMessage: '保存操作失败');
  }
}

class _PreviewState {
  int currentIndex = 0;
  bool isDragging = false;
  bool isBoxSelectionMode = false;
  bool isMultiSelectMode = false;

  Offset? selectionStart;
  Offset? selectionCurrent;
  CharacterRegion? selectedRegion;

  int? resizeHandleIndex;
  bool isRotating = false;
  double rotationStartAngle = 0;
  Offset? rotationCenter;
  Offset? dragStartOffset;
  Rect? dragStartRect;

  List<Offset>? erasePoints;

  void reset() {
    isDragging = false;
    isBoxSelectionMode = false;
    isMultiSelectMode = false;
    selectionStart = null;
    selectionCurrent = null;
    selectedRegion = null;
    resetManipulation();
    erasePoints = null;
  }

  void resetManipulation() {
    resizeHandleIndex = null;
    isRotating = false;
    rotationStartAngle = 0;
    rotationCenter = null;
    dragStartOffset = null;
    dragStartRect = null;
  }
}
