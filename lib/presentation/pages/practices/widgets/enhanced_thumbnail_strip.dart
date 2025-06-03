import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../widgets/practice/practice_edit_controller.dart';

/// Enhanced Thumbnail Strip with Advanced Features
/// 增强的缩略图条，包含高级功能
class EnhancedThumbnailStrip extends StatefulWidget {
  final List<Map<String, dynamic>> pages;
  final int currentPageIndex;
  final Function(int) onPageSelected;
  final VoidCallback onAddPage;
  final Function(int) onDeletePage;
  final Function(int, int)? onReorderPages;
  final Function(int)? onDuplicatePage;
  final Function(List<int>)? onDeleteMultiplePages;
  final PracticeEditController? controller;

  const EnhancedThumbnailStrip({
    super.key,
    required this.pages,
    required this.currentPageIndex,
    required this.onPageSelected,
    required this.onAddPage,
    required this.onDeletePage,
    this.onReorderPages,
    this.onDuplicatePage,
    this.onDeleteMultiplePages,
    this.controller,
  });

  @override
  State<EnhancedThumbnailStrip> createState() => _EnhancedThumbnailStripState();
}

/// 页面预览绘制器
class PagePreviewPainter extends CustomPainter {
  final List<Map<String, dynamic>> elements;
  final double thumbnailSize;

  PagePreviewPainter({
    required this.elements,
    required this.thumbnailSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final element in elements) {
      final type = element['type'] as String?;

      switch (type) {
        case 'text':
          _drawTextElement(canvas, element, size, paint);
          break;
        case 'shape':
          _drawShapeElement(canvas, element, size, paint);
          break;
        case 'image':
          _drawImageElement(canvas, element, size, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! PagePreviewPainter ||
        oldDelegate.elements != elements ||
        oldDelegate.thumbnailSize != thumbnailSize;
  }

  void _drawImageElement(
      Canvas canvas, Map<String, dynamic> element, Size size, Paint paint) {
    final x = (element['x'] as num?)?.toDouble() ?? 0;
    final y = (element['y'] as num?)?.toDouble() ?? 0;
    final width = (element['width'] as num?)?.toDouble() ?? 20;
    final height = (element['height'] as num?)?.toDouble() ?? 20;

    paint.color = Colors.grey.withOpacity(0.7);
    paint.style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(
      x * 0.1,
      y * 0.1,
      width * 0.1,
      height * 0.1,
    );

    canvas.drawRect(rect, paint);

    // 绘制图像占位符图标
    paint.color = Colors.white;
    final iconSize = (width * 0.05).clamp(2.0, 8.0);
    final iconRect = Rect.fromCenter(
      center: rect.center,
      width: iconSize,
      height: iconSize,
    );
    canvas.drawRect(iconRect, paint);
  }

  void _drawShapeElement(
      Canvas canvas, Map<String, dynamic> element, Size size, Paint paint) {
    final x = (element['x'] as num?)?.toDouble() ?? 0;
    final y = (element['y'] as num?)?.toDouble() ?? 0;
    final width = (element['width'] as num?)?.toDouble() ?? 20;
    final height = (element['height'] as num?)?.toDouble() ?? 20;
    final shapeType = element['shapeType'] as String? ?? 'rectangle';

    paint.color = Colors.blue.withOpacity(0.7);
    paint.style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(
      x * 0.1,
      y * 0.1,
      width * 0.1,
      height * 0.1,
    );

    switch (shapeType) {
      case 'circle':
        canvas.drawOval(rect, paint);
        break;
      case 'rectangle':
      default:
        canvas.drawRect(rect, paint);
        break;
    }
  }

  void _drawTextElement(
      Canvas canvas, Map<String, dynamic> element, Size size, Paint paint) {
    final x = (element['x'] as num?)?.toDouble() ?? 0;
    final y = (element['y'] as num?)?.toDouble() ?? 0;
    final text = element['text'] as String? ?? '';
    final fontSize = (element['fontSize'] as num?)?.toDouble() ?? 12;

    if (text.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text.length > 10 ? '${text.substring(0, 10)}...' : text,
          style: TextStyle(
            fontSize: fontSize * 0.3, // 缩放字体大小
            color: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(x * 0.1, y * 0.1)); // 缩放位置
    }
  }
}

class _EnhancedThumbnailStripState extends State<EnhancedThumbnailStrip>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // 多选状态
  final Set<int> _selectedPages = {};
  bool _isMultiSelectMode = false;

  // 拖拽状态
  int? _draggingIndex;
  int? _dropTargetIndex;

  // 缩放控制
  double _thumbnailSize = 80.0;
  final double _minThumbnailSize = 60.0;
  final double _maxThumbnailSize = 120.0;

  // 动画控制器
  late AnimationController _addPageAnimationController;
  late AnimationController _deletePageAnimationController;

  bool get _canZoomIn => _thumbnailSize < _maxThumbnailSize;

  /// 缩放相关方法
  bool get _canZoomOut => _thumbnailSize > _minThumbnailSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: _thumbnailSize + 60, // 额外空间用于控件和标签
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 控制栏
          _buildControlBar(),

          // 缩略图条
          Expanded(
            child: _buildThumbnailList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _addPageAnimationController.dispose();
    _deletePageAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _addPageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _deletePageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  /// 添加页面
  void _addPage() {
    _addPageAnimationController.forward().then((_) {
      _addPageAnimationController.reset();
    });

    widget.onAddPage();
  }

  /// 构建控制栏
  Widget _buildControlBar() {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 页面信息
          Text(
            '页面 ${widget.currentPageIndex + 1} / ${widget.pages.length}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),

          const SizedBox(width: 16),

          // 多选模式切换
          if (widget.pages.length > 1)
            IconButton(
              icon: Icon(
                _isMultiSelectMode ? Icons.check_circle : Icons.checklist,
                size: 16,
              ),
              onPressed: _toggleMultiSelectMode,
              tooltip: _isMultiSelectMode ? '退出多选' : '多选模式',
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),

          const Spacer(),

          // 多选操作按钮
          if (_isMultiSelectMode && _selectedPages.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              onPressed: _deleteSelectedPages,
              tooltip: '删除选中页面',
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
            const SizedBox(width: 4),
          ],

          // 缩放控制
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out, size: 16),
                onPressed: _canZoomOut ? _zoomOut : null,
                tooltip: '缩小',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              SizedBox(
                width: 60,
                child: Slider(
                  value: _thumbnailSize,
                  min: _minThumbnailSize,
                  max: _maxThumbnailSize,
                  divisions: 6,
                  onChanged: (value) {
                    setState(() {
                      _thumbnailSize = value;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, size: 16),
                onPressed: _canZoomIn ? _zoomIn : null,
                tooltip: '放大',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // 添加页面按钮
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('添加'),
            onPressed: _addPage,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建页面预览
  Widget _buildPagePreview(Map<String, dynamic> page) {
    final colorScheme = Theme.of(context).colorScheme;
    final elements = page['elements'] as List<dynamic>? ?? [];

    return Container(
      color: _parseColor(page['backgroundColor'] as String?) ?? Colors.white,
      child: CustomPaint(
        painter: PagePreviewPainter(
          elements: elements.cast<Map<String, dynamic>>(),
          thumbnailSize: _thumbnailSize,
        ),
        size: Size(_thumbnailSize, _thumbnailSize),
      ),
    );
  }

  /// 构建单个缩略图项
  Widget _buildThumbnailItem(int index) {
    final page = widget.pages[index];
    final isSelected = index == widget.currentPageIndex;
    final isMultiSelected = _selectedPages.contains(index);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: ValueKey('page_$index'),
      width: _thumbnailSize + 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          // 缩略图
          Expanded(
            child: GestureDetector(
              onTap: () => _handleThumbnailTap(index),
              onLongPress: () => _handleThumbnailLongPress(index),
              onSecondaryTap: () => _showContextMenu(index),
              child: Container(
                width: _thumbnailSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : isMultiSelected
                            ? colorScheme.secondary
                            : colorScheme.outline,
                    width: isSelected || isMultiSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    // 页面预览
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: _buildPagePreview(page),
                    ),

                    // 多选标记
                    if (_isMultiSelectMode)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isMultiSelected
                                ? colorScheme.secondary
                                : colorScheme.surfaceContainerHigh
                                    .withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: isMultiSelected
                              ? Icon(
                                  Icons.check,
                                  size: 14,
                                  color: colorScheme.onSecondary,
                                )
                              : null,
                        ),
                      ),

                    // 拖拽指示器
                    if (_draggingIndex == index)
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // 页面标签
          Text(
            '${index + 1}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建缩略图列表
  Widget _buildThumbnailList() {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: widget.pages.length,
        onReorder: (oldIndex, newIndex) {
          if (!_isMultiSelectMode && widget.onReorderPages != null) {
            widget.onReorderPages!(oldIndex, newIndex);
          }
        },
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.1,
                child: Card(
                  elevation: 8,
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          return _buildThumbnailItem(index);
        },
      ),
    );
  }

  /// 删除选中的页面
  void _deleteSelectedPages() {
    if (widget.onDeleteMultiplePages != null) {
      widget.onDeleteMultiplePages!(_selectedPages.toList());
    } else {
      // 逐个删除（从后往前删除以避免索引变化）
      final sortedIndices = _selectedPages.toList()
        ..sort((a, b) => b.compareTo(a));
      for (final index in sortedIndices) {
        widget.onDeletePage(index);
      }
    }

    setState(() {
      _selectedPages.clear();
      _isMultiSelectMode = false;
    });
  }

  /// 处理键盘事件
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          if (widget.currentPageIndex > 0) {
            widget.onPageSelected(widget.currentPageIndex - 1);
          }
          break;
        case LogicalKeyboardKey.arrowRight:
          if (widget.currentPageIndex < widget.pages.length - 1) {
            widget.onPageSelected(widget.currentPageIndex + 1);
          }
          break;
        case LogicalKeyboardKey.delete:
          if (_isMultiSelectMode && _selectedPages.isNotEmpty) {
            _deleteSelectedPages();
          }
          break;
        case LogicalKeyboardKey.escape:
          if (_isMultiSelectMode) {
            _toggleMultiSelectMode();
          }
          break;
      }
    }
  }

  /// 处理缩略图长按
  void _handleThumbnailLongPress(int index) {
    if (!_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = true;
        _selectedPages.add(index);
      });

      HapticFeedback.mediumImpact();
    }
  }

  /// 处理缩略图点击
  void _handleThumbnailTap(int index) {
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedPages.contains(index)) {
          _selectedPages.remove(index);
        } else {
          _selectedPages.add(index);
        }
      });
    } else {
      widget.onPageSelected(index);
    }
  }

  /// 解析颜色字符串
  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;

    try {
      if (colorString.startsWith('#')) {
        return Color(
            int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (e) {
      debugPrint('Failed to parse color: $colorString');
    }

    return null;
  }

  /// 显示上下文菜单
  void _showContextMenu(int index) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      items: [
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy),
              SizedBox(width: 8),
              Text('复制页面'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete),
              SizedBox(width: 8),
              Text('删除页面'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'duplicate' && widget.onDuplicatePage != null) {
        widget.onDuplicatePage!(index);
      } else if (value == 'delete') {
        widget.onDeletePage(index);
      }
    });
  }

  /// 切换多选模式
  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedPages.clear();
      }
    });
  }

  void _zoomIn() {
    setState(() {
      _thumbnailSize =
          (_thumbnailSize + 10).clamp(_minThumbnailSize, _maxThumbnailSize);
    });
  }

  void _zoomOut() {
    setState(() {
      _thumbnailSize =
          (_thumbnailSize - 10).clamp(_minThumbnailSize, _maxThumbnailSize);
    });
  }
}
