import 'package:demo/presentation/widgets/page_layout.dart';
import 'package:demo/presentation/widgets/practice/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        KeyEvent,
        KeyDownEvent,
        KeyUpEvent,
        LogicalKeyboardKey,
        HardwareKeyboard;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerState, ConsumerStatefulWidget;

import '../../widgets/common/resizable_panel.dart';
import '../../widgets/practice/control_handlers.dart';
import '../../widgets/practice/edit_toolbar.dart';
import '../../widgets/practice/element_operations.dart';
import '../../widgets/practice/element_renderers.dart';
import '../../widgets/practice/grid_painter.dart';
import '../../widgets/practice/page_operations.dart';
import '../../widgets/practice/page_thumbnail_strip.dart';
import '../../widgets/practice/practice_edit_controller.dart';
import '../../widgets/practice/practice_layer_panel.dart';
import '../../widgets/practice/practice_property_panel.dart';

/// 字帖编辑页面
class PracticeEditPage extends ConsumerStatefulWidget {
  final String? practiceId;

  const PracticeEditPage({super.key, this.practiceId});

  @override
  ConsumerState<PracticeEditPage> createState() => _PracticeEditPageState();
}

class _PracticeEditPageState extends ConsumerState<PracticeEditPage> {
  // 控制器
  late final PracticeEditController _controller;

  // 当前工具
  String _currentTool = 'select';

  // 网格大小
  final double _gridSize = 20.0;

  // 剪贴板
  Map<String, dynamic>? _clipboardElement;

  // 预览模式
  final bool _isPreviewMode = false;

  // 拖拽状态
  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  Offset _elementStartPosition = Offset.zero;

  // 键盘状态
  bool _isCtrlPressed = false;
  bool _isShiftPressed = false;

  // 键盘监听器
  late FocusNode _focusNode;

  // 缩放控制器
  late TransformationController _transformationController;

  // 控制页面缩略图显示
  final bool _showThumbnails = true;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: PageLayout(
        toolbar: TopNavigationBar(
          controller: _controller,
          isPreviewMode: _isPreviewMode,
          onTogglePreviewMode: () {
            setState(() {
              // Toggle preview mode functionality
            });
          },
          showThumbnails: _showThumbnails,
          onThumbnailToggle: (bool value) {
            setState(() {
              // Toggle thumbnails functionality
            });
          },
        ),
        body: _buildBody(context),
      ),
    );
  }

  @override
  void dispose() {
    // 移除键盘监听
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _focusNode.dispose();

    // 释放缩放控制器
    _transformationController.dispose();

    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = PracticeEditController();

    // 初始化键盘监听器
    _focusNode = FocusNode();

    // 初始化缩放控制器
    _transformationController = TransformationController();

    // 添加键盘监听
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);

    // 如果有ID，加载现有字帖
    if (widget.practiceId != null) {
      _loadPractice(widget.practiceId!);
    }
  }

  /// 将元素置于顶层
  void _bringElementToFront() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index >= 0 && index < elements.length - 1) {
      // 移除元素
      final element = elements.removeAt(index);
      // 添加到末尾（最顶层）
      elements.add(element);

      // 更新当前页面的元素
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
  }

  Widget _buildBody(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          children: [
            // 左侧面板
            if (!_isPreviewMode) _buildLeftPanel(),

            // 中央编辑区
            Expanded(
              child: Column(
                children: [
                  // 工具栏
                  if (!_isPreviewMode) _buildEditToolbar(),

                  // 编辑画布
                  Expanded(child: _buildEditCanvas()),

                  // 页面缩略图栏
                  if (_showThumbnails && !_isPreviewMode)
                    SizedBox(
                      height: 120,
                      child: PageThumbnailStrip(
                        pages: _controller.state.pages,
                        currentPageIndex: _controller.state.currentPageIndex,
                        onPageSelected: (index) =>
                            _controller.setCurrentPage(index),
                        onAddPage: _controller.addNewPage,
                        onDeletePage: _controller.deletePage,
                        onReorderPages: (oldIndex, newIndex) {
                          _controller.reorderPages(oldIndex, newIndex);
                        },
                      ),
                    ),
                ],
              ),
            ),

            // 右侧属性面板
            if (!_isPreviewMode) _buildRightPanel(),
          ],
        );
      },
    );
  }

  /// 构建内容控件区
  Widget _buildContentToolPanel() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              '内容控件',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildDraggableToolButton(
                icon: Icons.title,
                label: '文本',
                toolName: 'text',
                elementType: 'text',
              ),
              _buildDraggableToolButton(
                icon: Icons.image,
                label: '图片',
                toolName: 'image',
                elementType: 'image',
              ),
              _buildDraggableToolButton(
                icon: Icons.format_shapes,
                label: '集字',
                toolName: 'collection',
                elementType: 'collection',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建控制点手势检测器
  Widget _buildControlPointDetector(
    String elementId,
    int controlPointIndex,
    Offset position,
    Size size, {
    bool isRotation = false,
  }) {
    // 根据控制点类型选择光标
    MouseCursor cursor;
    if (isRotation) {
      cursor = SystemMouseCursors.grab;
    } else {
      switch (controlPointIndex) {
        case 0: // 左上角
        case 4: // 右下角
          cursor = SystemMouseCursors.resizeUpLeft;
          break;
        case 2: // 右上角
        case 6: // 左下角
          cursor = SystemMouseCursors.resizeUpRight;
          break;
        case 1: // 上中
        case 5: // 下中
          cursor = SystemMouseCursors.resizeUpDown;
          break;
        case 3: // 右中
        case 7: // 左中
          cursor = SystemMouseCursors.resizeLeftRight;
          break;
        default:
          cursor = SystemMouseCursors.basic;
      }
    }

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: isRotation
            ? Colors.blue // 旋转控制点使用蓝色
            : Colors.white, // 其他控制点使用白色
        border: Border.all(
          color: isRotation ? Colors.white : Colors.blue,
          width: isRotation ? 1 : 1,
        ),
        shape: isRotation ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: isRotation
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(76), // 0.3 的不透明度
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // 确保手势检测器完全捕获所有事件
          // 添加点击事件处理，阻止事件冒泡
          onTap: () {
            // 阻止点击事件传递到元素上
            debugPrint('Control point $controlPointIndex tapped at $position');
          },
          onPanStart: (details) {
            // 阻止事件冒泡
            // 使用 setState 来标记正在拖动，这将禁用 InteractiveViewer 的平移
            debugPrint('\n=== 开始操作控制点 $controlPointIndex (元素 $elementId) ===');
            debugPrint('控制点类型: ${isRotation ? "旋转控制点" : "大小调整控制点"}');
            debugPrint('开始位置: ${details.localPosition}');

            setState(() {
              _isDragging = true;
              _dragStart = details.localPosition;

              // 如果是旋转控制点，记录元素中心点
              if (isRotation) {
                final element = _controller.state.currentPageElements
                    .firstWhere((e) => e['id'] == elementId);
                final x = (element['x'] as num).toDouble();
                final y = (element['y'] as num).toDouble();
                final width = (element['width'] as num).toDouble();
                final height = (element['height'] as num).toDouble();

                // 计算元素中心点
                _elementStartPosition = Offset(x + width / 2, y + height / 2);
              }
            });

            // 添加防止事件冒泡的处理
            details.sourceTimeStamp; // 访问属性以避免未使用的变量警告
          },
          onPanUpdate: (details) {
            // 阻止事件冒泡
            // 已经在 InteractiveViewer 中禁用了平移

            // 打印控制点更新操作的日志
            debugPrint('控制点 $controlPointIndex 移动: ${details.delta}');

            if (isRotation) {
              // 旋转控制点的处理
              final element = _controller.state.currentPageElements
                  .firstWhere((e) => e['id'] == elementId);
              final currentRotation = (element['rotation'] as num).toDouble();

              // 计算旋转角度
              final center = _elementStartPosition;
              final startPoint = details.globalPosition - details.delta;
              final currentPoint = details.globalPosition;

              final deltaAngle = ControlHandlers.calculateRotation(
                center,
                startPoint,
                currentPoint,
              );

              // 更新旋转角度
              final newRotation = (currentRotation + deltaAngle) % 360;
              _controller.updateElementProperty(
                  elementId, 'rotation', newRotation);
            } else {
              // 大小调整控制点的处理
              final element = _controller.state.currentPageElements
                  .firstWhere((e) => e['id'] == elementId);

              // 计算新的几何属性
              final currentGeometry = {
                'x': (element['x'] as num).toDouble(),
                'y': (element['y'] as num).toDouble(),
                'width': (element['width'] as num).toDouble(),
                'height': (element['height'] as num).toDouble(),
              };

              final newGeometry = ControlHandlers.calculateNewGeometry(
                currentGeometry,
                controlPointIndex,
                details.delta,
              );

              // 更新元素属性
              if (newGeometry.isNotEmpty) {
                // 确保宽高不为负数
                if (newGeometry.containsKey('width') &&
                    (newGeometry['width'] as double) <= 10) {
                  newGeometry['width'] = 10.0;
                }
                if (newGeometry.containsKey('height') &&
                    (newGeometry['height'] as double) <= 10) {
                  newGeometry['height'] = 10.0;
                }

                _controller.updateElementProperties(elementId, newGeometry);
              }
            }

            // 添加防止事件冒泡的处理
            details.sourceTimeStamp; // 访问属性以避免未使用的变量警告
          },
          onPanEnd: (details) {
            // 打印控制点操作结束的日志
            debugPrint('\n=== 结束操作控制点 $controlPointIndex (元素 $elementId) ===');

            // 获取元素的当前状态
            final element = _controller.state.currentPageElements
                .firstWhere((e) => e['id'] == elementId);

            if (isRotation) {
              final rotation = (element['rotation'] as num).toDouble();
              debugPrint('旋转后的角度: $rotation度');
            } else {
              final x = (element['x'] as num).toDouble();
              final y = (element['y'] as num).toDouble();
              final width = (element['width'] as num).toDouble();
              final height = (element['height'] as num).toDouble();
              debugPrint('调整后的尺寸: 宽=$width, 高=$height');
              debugPrint('调整后的位置: x=$x, y=$y');
            }

            setState(() {
              _isDragging = false;
            });

            // 添加防止事件冒泡的处理
            details.primaryVelocity; // 访问属性以避免未使用的变量警告
          },
        ),
      ),
    );
  }

  /// 构建控制点
  Widget _buildControlPoints(String elementId, double width, double height) {
    const controlPointSize = 8.0;
    const rotationHandleDistance = 35.0;

    return Stack(
      clipBehavior: Clip.none, // 关键修改：禁用裁剪，允许控制点超出边界
      children: [
        // 不再添加边框，但仍需要一个容器来确保布局正确
        Container(
          width: width,
          height: height,
          color: Colors.transparent, // 透明容器，仅用于布局
        ),

        // 左上角
        Positioned(
          left: -controlPointSize / 2,
          top: -controlPointSize / 2,
          child: _buildControlPointDetector(
            elementId,
            0,
            const Offset(
                -controlPointSize / 2, -controlPointSize / 2), // 使用实际位置
            const Size(controlPointSize, controlPointSize),
          ),
        ),

        // 上中
        Positioned(
          left: (width - controlPointSize) / 2,
          top: -controlPointSize / 2,
          child: _buildControlPointDetector(
            elementId,
            1,
            Offset((width - controlPointSize) / 2,
                -controlPointSize / 2), // 使用实际位置
            const Size(controlPointSize, controlPointSize),
          ),
        ),

        // 右上角
        Positioned(
          right: -controlPointSize / 2,
          top: -controlPointSize / 2,
          child: _buildControlPointDetector(
            elementId,
            2,
            Offset(
                width + controlPointSize / 2, -controlPointSize / 2), // 使用实际位置
            const Size(controlPointSize, controlPointSize),
          ),
        ),

        // 右中
        Positioned(
          right: -controlPointSize / 2,
          top: (height - controlPointSize) / 2,
          child: _buildControlPointDetector(
            elementId,
            3,
            Offset(width + controlPointSize / 2,
                (height - controlPointSize) / 2), // 使用实际位置
            const Size(controlPointSize, controlPointSize),
          ),
        ),

        // 右下角
        Positioned(
          right: -controlPointSize / 2,
          bottom: -controlPointSize / 2,
          child: _buildControlPointDetector(
            elementId,
            4,
            Offset(width + controlPointSize / 2,
                height + controlPointSize / 2), // 使用实际位置
            const Size(controlPointSize, controlPointSize),
          ),
        ),

        // 下中
        Positioned(
          left: (width - controlPointSize) / 2,
          bottom: -controlPointSize / 2,
          child: _buildControlPointDetector(
            elementId,
            5,
            Offset((width - controlPointSize) / 2,
                height + controlPointSize / 2), // 使用实际位置
            const Size(controlPointSize, controlPointSize),
          ),
        ),

        // 左下角
        Positioned(
          left: -controlPointSize / 2,
          bottom: -controlPointSize / 2,
          child: _buildControlPointDetector(
            elementId,
            6,
            Offset(
                -controlPointSize / 2, height + controlPointSize / 2), // 使用实际位置
            const Size(controlPointSize, controlPointSize),
          ),
        ),

        // 左中
        Positioned(
          left: -controlPointSize / 2,
          top: (height - controlPointSize) / 2,
          child: _buildControlPointDetector(
            elementId,
            7,
            Offset(-controlPointSize / 2,
                (height - controlPointSize) / 2), // 使用实际位置
            const Size(controlPointSize, controlPointSize),
          ),
        ),

        // 旋转控制柄 - 连接线
        // Positioned(
        //   left: width / 2 - 1,
        //   top: -rotationHandleDistance + 14, // 从旋转手柄底部开始
        //   child: Container(
        //     width: 2,
        //     height: rotationHandleDistance - 14, // 连接线高度
        //     color: Colors.blue,
        //   ),
        // ),

        // 旋转控制柄 - 手柄
        Positioned(
          left: width / 2 - 7,
          top: -7,
          child: _buildControlPointDetector(
            elementId,
            8,
            Offset(width / 2 - 7, -7), // 使用实际位置
            const Size(14, 14),
            isRotation: true,
          ),
        ),
      ],
    );
  }

  /// 构建可拖拽的工具按钮
  Widget _buildDraggableToolButton({
    required IconData icon,
    required String label,
    required String toolName,
    required String elementType,
  }) {
    return Draggable<String>(
      // 拖拽的数据是元素类型
      data: elementType,
      // 拖拽时显示的控件
      feedback: Material(
        elevation: 4.0,
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(204), // 0.8 opacity
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24.0),
              const SizedBox(height: 4.0),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
      // 拖拽时原位置显示的控件
      childWhenDragging: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.5,
          child: _buildToolButton(
            icon: icon,
            label: label,
            toolName: toolName,
            onPressed: () {}, // 拖拽时禁用点击
          ),
        ),
      ),
      // 原始控件
      child: _buildToolButton(
        icon: icon,
        label: label,
        toolName: toolName,
        onPressed: () {
          setState(() {
            _currentTool = toolName;
          });
          // 点击时默认添加对应类型的元素
          switch (elementType) {
            case 'text':
              _controller.addTextElement();
              break;
            case 'image':
              // 直接添加空图片元素，不显示对话框
              _controller.addEmptyImageElementAt(100.0, 100.0);
              break;
            case 'collection':
              // 直接添加空集字元素，不显示对话框
              _controller.addEmptyCollectionElementAt(100.0, 100.0);
              break;
          }
        },
      ),
    );
  }

  /// 构建编辑画布
  Widget _buildEditCanvas() {
    if (_controller.state.pages.isEmpty) {
      return const Center(child: Text('没有页面，请添加页面'));
    }

    final currentPage = _controller.state.currentPage;
    if (currentPage == null) {
      return const Center(child: Text('当前页面不存在'));
    }

    final elements = _controller.state.currentPageElements;

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        // 获取放置位置 - 相对于编辑画布的坐标
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);

        // 获取InteractiveViewer的变换矩阵
        // 注意：在实际应用中，你可能需要保存和访问InteractiveViewer的TransformationController
        // 这里简化处理，使用一个估计的位置

        // 计算A4页面中心位置
        final pageWidth = (currentPage['width'] as num?)?.toDouble() ??
            842.0; // A4 宽度 (72dpi)
        final pageHeight = (currentPage['height'] as num?)?.toDouble() ??
            842.0; // A4 高度 (72dpi)

        // 使用相对位置，如果坐标在可见范围内，则使用实际位置
        // 否则默认放在页面中心
        double x = localPosition.dx;
        double y = localPosition.dy;

        // 确保坐标在页面范围内
        x = x.clamp(0.0, pageWidth);
        y = y.clamp(0.0, pageHeight);

        // 根据类型添加不同的元素
        switch (details.data) {
          case 'text':
            _controller.addTextElementAt(x, y);
            break;
          case 'image':
            // 直接添加空图片元素，不显示对话框
            _controller.addEmptyImageElementAt(x, y);
            break;
          case 'collection':
            // 直接添加空集字元素，不显示对话框
            _controller.addEmptyCollectionElementAt(x, y);
            break;
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: Colors.grey.shade200,
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(double.infinity),
            panEnabled: !_isDragging, // 当拖动控件时禁用平移
            scaleEnabled: true,
            minScale: 0.1,
            maxScale: 15.0,
            scaleFactor: 200.0, // 增大缩放因子，减小缩放幅度
            constrained: false, // 添加这一行，使内容不受约束

            child: GestureDetector(
              onTapUp: (details) => _handleTapDown(details, elements),
              onPanStart: (details) {
                // 只在非预览模式下允许拖拽
                if (_isPreviewMode) return;

                // 如果有选中的元素，开始拖拽
                if (_controller.state.selectedElementIds.isNotEmpty) {
                  setState(() {
                    _isDragging = true;
                    _dragStart = details.localPosition;

                    // 记录所有选中元素的起始位置
                    for (final elementId
                        in _controller.state.selectedElementIds) {
                      final element = _controller.state.currentPageElements
                          .firstWhere((e) => e['id'] == elementId);
                      if (element['isLocked'] == true) continue;
                      _elementStartPosition = Offset(
                        (element['x'] as num).toDouble(),
                        (element['y'] as num).toDouble(),
                      );
                    }
                  });
                  debugPrint('开始拖拽: ${details.localPosition}');
                }
              },
              onPanUpdate: (details) {
                // 只在拖拽状态且非预览模式下更新位置
                if (!_isDragging || _isPreviewMode) return;

                if (_controller.state.selectedElementIds.isNotEmpty) {
                  final dx = details.localPosition.dx - _dragStart.dx;
                  final dy = details.localPosition.dy - _dragStart.dy;

                  // 更新所有选中元素的位置
                  for (final elementId
                      in _controller.state.selectedElementIds) {
                    final element = _controller.state.currentPageElements
                        .firstWhere((e) => e['id'] == elementId);
                    final layerId = element['layerId'] as String?;
                    if (layerId != null) {
                      final layer = _controller.state.getLayerById(layerId);
                      if (layer != null) {
                        if (layer['isLocked'] == true) return;
                        if (layer['isVisible'] == false) return;
                      }
                    }

                    // 计算新位置
                    double newX = _elementStartPosition.dx + dx;
                    double newY = _elementStartPosition.dy + dy;

                    // 吸附到网格（如果启用）
                    if (_controller.state.snapEnabled) {
                      newX = (newX / _gridSize).round() * _gridSize;
                      newY = (newY / _gridSize).round() * _gridSize;
                    }

                    // 更新元素位置
                    _controller.updateElementProperties(elementId, {
                      'x': newX,
                      'y': newY,
                    });
                  }
                  debugPrint('拖拽更新: dx=$dx, dy=$dy');
                }
              },
              onPanEnd: (details) {
                if (_isDragging) {
                  setState(() {
                    _isDragging = false;
                  });

                  // 打印结束位置信息
                  for (final elementId
                      in _controller.state.selectedElementIds) {
                    final element = _controller.state.currentPageElements
                        .firstWhere((e) => e['id'] == elementId);
                    debugPrint(
                        '元素 $elementId 结束位置: (${element['x']}, ${element['y']})');
                  }
                }
              },
              child: Stack(
                children: [
                  // 页面背景
                  Container(
                    width: (currentPage['width'] as num?)?.toDouble() ?? 595.0,
                    height:
                        (currentPage['height'] as num?)?.toDouble() ?? 842.0,
                    color: PageOperations.getPageBackgroundColor(currentPage),
                    child: Stack(
                      children: [
                        // 网格
                        if (_controller.state.gridVisible)
                          CustomPaint(
                            size: Size(
                              (currentPage['width'] as num?)?.toDouble() ??
                                  595.0,
                              (currentPage['height'] as num?)?.toDouble() ??
                                  842.0,
                            ),
                            painter: GridPainter(gridSize: _gridSize),
                          ),

                        // 元素
                        // 根据图层顺序排序元素
                        ..._sortElementsByLayerOrder(elements)
                            .map((element) => _buildElement(element)),

                        // 拖拽指示
                        if (candidateData.isNotEmpty)
                          Container(
                            width: (currentPage['width'] as num?)?.toDouble() ??
                                595.0,
                            height:
                                (currentPage['height'] as num?)?.toDouble() ??
                                    842.0,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blue,
                                width: 1,
                                style: BorderStyle.solid,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      onWillAcceptWithDetails: (data) => true,
    );
  }

  /// 构建顶部编辑工具栏
  Widget _buildEditToolbar() {
    return EditToolbar(
      controller: _controller,
      gridVisible: _controller.state.gridVisible,
      snapEnabled: _controller.state.snapEnabled,
      onToggleGrid: () {
        _controller.state.gridVisible = !_controller.state.gridVisible;
        setState(() {});
      },
      onToggleSnap: () {
        _controller.state.snapEnabled = !_controller.state.snapEnabled;
        setState(() {});
      },
      onCopy: _copySelectedElement,
      onPaste: _pasteElement,
      onGroupElements: () {
        if (_controller.state.selectedElementIds.length > 1) {
          _controller.groupSelectedElements();
        }
      },
      onUngroupElements: () {
        if (_controller.state.selectedElementIds.length == 1) {
          final id = _controller.state.selectedElementIds.first;
          final element = ElementOperations.findElementById(
              _controller.state.currentPageElements, id);
          if (element != null && element['type'] == 'group') {
            _controller.ungroupElements(id);
          }
        }
      },
      onBringToFront: _bringElementToFront,
      onSendToBack: _sendElementToBack,
      onMoveUp: _moveElementUp,
      onMoveDown: _moveElementDown,
      onDelete: () {
        if (_controller.state.selectedElementIds.isNotEmpty) {
          // 创建一个副本以避免 ConcurrentModificationError
          final idsToDelete =
              List<String>.from(_controller.state.selectedElementIds);
          for (final id in idsToDelete) {
            _controller.deleteElement(id);
          }
        }
      },
    );
  }

  /// 构建元素
  Widget _buildElement(Map<String, dynamic> element) {
    final id = element['id'] as String;
    final type = element['type'] as String;
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num).toDouble();
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

    // 检查元素是否被选中
    final isSelected = _controller.state.selectedElementIds.contains(id);

    // 检查元素是否被锁定或隐藏
    final isLocked = element['locked'] == true;
    final isHidden = element['hidden'] == true;

    // 检查元素所在图层的锁定和隐藏状态
    final layerId = element['layerId'] as String?;
    bool isLayerLocked = false;
    bool isLayerHidden = false;

    if (layerId != null) {
      final layer = _controller.state.getLayerById(layerId);
      if (layer != null) {
        isLayerLocked = layer['isLocked'] == true;
        isLayerHidden =
            layer['isVisible'] == false; // 注意这里的逻辑：isVisible=false 意味着隐藏
      }
    }

    // 检查元素是否处于错误状态
    final hasError = element['hasError'] == true;

    Widget content;

    // 根据元素类型构建内容
    switch (type) {
      case 'text':
        content = ElementRenderers.buildTextElement(element);
        break;
      case 'image':
        content = ElementRenderers.buildImageElement(element);
        break;
      case 'collection':
        content = ElementRenderers.buildCollectionElement(element);
        break;
      case 'group':
        // 将组合控件的选中状态传递给子元素
        content =
            ElementRenderers.buildGroupElement(element, isSelected: isSelected);
        break;
      default:
        content = Container(
          color: Colors.grey.withAlpha(51), // 0.2 opacity
          child: const Center(child: Text('未知元素')),
        );
    }

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: rotation * 3.1415926 / 180,
        // 添加原点参数，确保旋转以元素中心为原点
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main element widget
            Opacity(
              // 元素或图层隐藏状态下，编辑模式显示半透明，预览模式完全隐藏
              opacity: isHidden || isLayerHidden
                  ? (_isPreviewMode ? 0.0 : 0.5) // 隐藏状态
                  : opacity, // 正常状态
              child: Container(
                width: width,
                height: height,
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  border: Border.all(
                    // 根据规范设置边框颜色和宽度
                    color: hasError
                        ? Colors.red // 错误状态：红色边框
                        : isLocked || isLayerLocked
                            ? Colors.orange // 锁定状态：橙色边框
                            : !_isPreviewMode && isSelected
                                ? Colors.blue // 编辑状态或选中状态：蓝色边框
                                : Colors.grey
                                    .withAlpha(179), // 普通状态：灰色边框，70%不透明度
                    width: 1.0, // 所有状态都是1px
                    style: (isHidden || isLayerHidden) && !_isPreviewMode
                        ? BorderStyle.none // Flutter没有虚线边框，所以使用透明度来模拟
                        : BorderStyle.solid, // 隐藏状态使用半透明
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 元素内容
                    content,

                    // 锁定图标
                    if ((isLocked || isLayerLocked) && !_isPreviewMode)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(179), // 0.7 的不透明度
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Icon(
                            isLayerLocked ? Icons.layers_outlined : Icons.lock,
                            color: Colors.orange,
                            size: 16,
                          ),
                        ),
                      ),

                    // 错误图标
                    if (hasError && !_isPreviewMode)
                      Positioned(
                        right: (isLocked || isLayerLocked)
                            ? 26
                            : 4, // 如果同时有锁定图标，则错开一点
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(179), // 0.7 的不透明度
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 只在编辑状态下显示控制点（单选元素、不在预览模式、非锁定状态）
            if (!_isPreviewMode &&
                isSelected &&
                !isLocked &&
                !isLayerLocked && // 添加图层锁定检查
                _controller.state.selectedElementIds.length == 1)
              _buildControlPoints(id, width, height),
          ],
        ),
      ),
    );
  }

  /// 构建左侧面板
  Widget _buildLeftPanel() {
    return ResizablePanel(
      initialWidth: 250,
      minWidth: 150,
      maxWidth: 400,
      isLeftPanel: true,
      child: Column(
        children: [
          // 内容控件区
          _buildContentToolPanel(),

          const Divider(),

          // 图层管理区
          Expanded(
            child: PracticeLayerPanel(
              controller: _controller,
              onLayerSelect: (layerId) {
                // 处理图层选择
                _controller.selectLayer(layerId);
              },
              onLayerVisibilityToggle: (layerId, isVisible) {
                // 处理图层可见性切换
                _controller.toggleLayerVisibility(layerId, isVisible);
              },
              onLayerLockToggle: (layerId, isLocked) {
                // 处理图层锁定切换
                _controller.toggleLayerLock(layerId, isLocked);
              },
              onAddLayer: _controller.addNewLayer,
              onDeleteLayer: _controller.deleteLayer,
              onReorderLayer: _controller.reorderLayer,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建右侧属性面板
  Widget _buildRightPanel() {
    return AnimatedBuilder(
      animation: _controller, // 关键修改：监听控制器的变化
      builder: (context, _) {
        // 创建一个唯一的key，确保在选择变化时面板能够重新构建
        final selectedKey = _controller.state.selectedElementIds.isEmpty
            ? _controller.state.selectedLayerId != null
                ? 'layer_panel_${_controller.state.selectedLayerId}'
                : 'page_panel'
            : 'element_panel_${_controller.state.selectedElementIds.join('_')}';

        Widget panel;

        // 检查是否选中了图层
        if (_controller.state.selectedLayerId != null) {
          // 选中图层时显示图层属性
          final layerId = _controller.state.selectedLayerId!;
          final layer = _controller.state.getLayerById(layerId);
          if (layer != null) {
            panel = PracticePropertyPanel.forLayer(
              controller: _controller,
              layer: layer,
              onLayerPropertiesChanged: (properties) {
                // 更新图层属性
                _controller.updateLayerProperties(layerId, properties);
              },
            );
            return SizedBox(
              width: 300,
              child: panel,
            );
          }
        }

        // 根据选中元素类型显示不同的属性面板
        if (_controller.state.selectedElementIds.isEmpty) {
          // 未选中元素时显示页面属性
          panel = PracticePropertyPanel.forPage(
            controller: _controller,
            page: _controller.state.currentPage,
            onPagePropertiesChanged: (properties) {
              if (_controller.state.currentPageIndex >= 0) {
                _controller.updatePageProperties(properties);
              }
            },
          );
        } else if (_controller.state.selectedElementIds.length == 1) {
          // 单选元素时根据类型显示属性
          final id = _controller.state.selectedElementIds.first;
          final element = ElementOperations.findElementById(
              _controller.state.currentPageElements, id);

          if (element != null) {
            switch (element['type']) {
              case 'text':
                panel = PracticePropertyPanel.forText(
                  controller: _controller,
                  element: element,
                  onElementPropertiesChanged: (properties) {
                    _controller.updateElementProperties(id, properties);
                  },
                );
                break;
              case 'image':
                panel = PracticePropertyPanel.forImage(
                  controller: _controller,
                  element: element,
                  onElementPropertiesChanged: (properties) {
                    _controller.updateElementProperties(id, properties);
                  },
                  onSelectImage: () async {
                    // 实现选择图片的逻辑
                    await _showImageUrlDialog(context);
                  },
                );
                break;
              case 'collection':
                panel = PracticePropertyPanel.forCollection(
                  controller: _controller,
                  element: element,
                  onElementPropertiesChanged: (properties) {
                    _controller.updateElementProperties(id, properties);
                  },
                  onUpdateChars: (chars) {
                    // Get the current content map
                    final content = Map<String, dynamic>.from(
                        element['content'] as Map<String, dynamic>);
                    // Update the characters property
                    content['characters'] = chars;
                    // Update the element with the modified content map
                    final updatedProps = {'content': content};
                    _controller.updateElementProperties(id, updatedProps);
                  },
                );
                break;
              case 'group':
                panel = PracticePropertyPanel.forGroup(
                  controller: _controller,
                  element: element,
                  onElementPropertiesChanged: (properties) {
                    _controller.updateElementProperties(id, properties);
                  },
                );
                break;
              default:
                panel = const Center(child: Text('不支持的元素类型'));
            }
          } else {
            panel = const Center(child: Text('找不到选中的元素'));
          }
        } else {
          // 多选元素时显示组合属性
          panel = PracticePropertyPanel.forMultiSelection(
            controller: _controller,
            selectedIds: _controller.state.selectedElementIds,
            onElementPropertiesChanged: (properties) {
              // 将属性应用到所有选中的元素
              for (final id in _controller.state.selectedElementIds) {
                _controller.updateElementProperties(id, properties);
              }
            },
          );
        }

        return ResizablePanel(
          initialWidth: 300,
          minWidth: 200,
          maxWidth: 500,
          isLeftPanel: false,
          child: panel,
        );
      },
    );
  }

  /// 构建工具按钮
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required String toolName,
    required VoidCallback onPressed,
  }) {
    final isSelected = _currentTool == toolName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentTool = toolName;
          });
          onPressed();
        },
        borderRadius: BorderRadius.circular(4.0),
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withAlpha(26) : null, // 0.1 opacity
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue : null,
                size: 24.0,
              ),
              const SizedBox(height: 4.0),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : null,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 复制选中的元素
  void _copySelectedElement() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    if (_controller.state.selectedElementIds.length == 1) {
      // 单选复制
      final id = _controller.state.selectedElementIds.first;
      final elements = _controller.state.currentPageElements;
      final element = ElementOperations.findElementById(elements, id);

      if (element != null) {
        _clipboardElement = Map<String, dynamic>.from(element);
      }
    } else {
      // 多选复制暂不支持
    }
  }

  /// 处理键盘事件
  bool _handleKeyEvent(KeyEvent event) {
    setState(() {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
            event.logicalKey == LogicalKeyboardKey.controlRight) {
          _isCtrlPressed = true;
        } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
            event.logicalKey == LogicalKeyboardKey.shiftRight) {
          _isShiftPressed = true;
        }
      } else if (event is KeyUpEvent) {
        if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
            event.logicalKey == LogicalKeyboardKey.controlRight) {
          _isCtrlPressed = false;
        } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
            event.logicalKey == LogicalKeyboardKey.shiftRight) {
          _isShiftPressed = false;
        }
      }
    });

    // 返回false表示不拦截事件，允许其他处理程序处理
    return false;
  }

  /// 处理点击事件
  void _handleTapDown(
      TapUpDetails details, List<Map<String, dynamic>> elements) {
    // 如果点击在空白处，取消选择
    bool hitElement = false;

    // 从后往前检查（后添加的元素在上层）
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      final id = element['id'] as String;
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();
      final isLocked = element['locked'] == true;
      final isHidden = element['hidden'] == true;

      // 如果元素被隐藏且在预览模式下，跳过该元素
      if (isHidden && _isPreviewMode) continue;

      // 注意：旋转角度在简单碰撞检测中暂未使用，但在更复杂的检测中会用到

      // 计算边框宽度，用于边框点击检测
      final isSelected = _controller.state.selectedElementIds.contains(id);
      final borderWidth = !_isPreviewMode && isSelected ? 2.0 : 1.0;

      // 判断是否点击在元素内部
      final bool isInside = details.localPosition.dx >= x &&
          details.localPosition.dx <= x + width &&
          details.localPosition.dy >= y &&
          details.localPosition.dy <= y + height;

      // 判断是否点击在边框上
      // 只在边框附近小范围内扩展点击区域
      final bool isOnBorder = !isInside &&
          (
              // 左边框
              (details.localPosition.dx >= x - borderWidth &&
                      details.localPosition.dx <= x &&
                      details.localPosition.dy >= y &&
                      details.localPosition.dy <= y + height) ||
                  // 右边框
                  (details.localPosition.dx >= x + width &&
                      details.localPosition.dx <= x + width + borderWidth &&
                      details.localPosition.dy >= y &&
                      details.localPosition.dy <= y + height) ||
                  // 上边框
                  (details.localPosition.dy >= y - borderWidth &&
                      details.localPosition.dy <= y &&
                      details.localPosition.dx >= x &&
                      details.localPosition.dx <= x + width) ||
                  // 下边框
                  (details.localPosition.dy >= y + height &&
                      details.localPosition.dy <= y + height + borderWidth &&
                      details.localPosition.dx >= x &&
                      details.localPosition.dx <= x + width));

      // 打印调试信息
      if (isOnBorder) {
        debugPrint(
            'Click on border of element $id at ${details.localPosition}');
      }

      // 如果点击在元素内部或边框上
      if (isInside || isOnBorder) {
        hitElement = true;

        // 如果元素被锁定，只允许选中，不允许编辑
        if (isLocked) {
          // 锁定元素只能选中，不能编辑
          // 清除图层选择，确保属性面板能切换到元素属性
          _controller.state.selectedLayerId = null;

          _controller.selectElement(id,
              isMultiSelect: _isCtrlPressed || _isShiftPressed);

          // 强制触发UI更新，确保属性面板切换
          setState(() {});
        } else {
          // 根据状态图实现状态转换
          final isCurrentlySelected =
              _controller.state.selectedElementIds.contains(id);
          final isMultipleSelected =
              _controller.state.selectedElementIds.length > 1;

          // 打印当前状态信息
          debugPrint('\n=== 点击元素 $id 前的状态 ===');
          debugPrint(
              '当前选中元素数量: ${_controller.state.selectedElementIds.length}');
          debugPrint('当前选中元素IDs: ${_controller.state.selectedElementIds}');
          debugPrint('当前元素是否选中: $isCurrentlySelected');
          debugPrint('当前是否多选状态: $isMultipleSelected');
          debugPrint('是否按下Ctrl或Shift键: ${_isCtrlPressed || _isShiftPressed}');

          if (_isCtrlPressed || _isShiftPressed) {
            // Ctrl+点击：多选状态
            debugPrint('→ 进入多选状态 (按下Ctrl或Shift键)');
            // 清除图层选择，确保属性面板能切换到元素属性
            _controller.state.selectedLayerId = null;

            _controller.selectElement(id, isMultiSelect: true);
            // 强制触发UI更新，确保属性面板切换
            setState(() {});
          } else if (isCurrentlySelected && isMultipleSelected) {
            // 已选中且当前是多选状态：取消其他选择，进入编辑状态
            debugPrint('→ 从多选状态转为编辑状态 (取消其他选择)');
            _controller.state.selectedElementIds = [id];
            _controller.state.selectedElement = element;

            // 关键修改: 无论如何都启用拖拽
            setState(() {
              _isDragging = true;
              _dragStart = details.localPosition;
              _elementStartPosition = Offset(x, y);
              debugPrint('→ 设置拖拽状态，准备移动元素');
            });
          } else if (!isCurrentlySelected) {
            // 未选中：选中并进入编辑状态
            debugPrint('→ 从普通状态转为编辑状态 (选中元素)');
            // 清除图层选择，确保属性面板能切换到元素属性
            _controller.state.selectedLayerId = null;

            _controller.selectElement(id, isMultiSelect: false);
            // 强制触发UI更新，确保属性面板切换
            setState(() {});

            // 关键修改: 同时启用拖拽
            setState(() {
              _isDragging = true;
              _dragStart = details.localPosition;
              _elementStartPosition = Offset(x, y);
              debugPrint('→ 设置拖拽状态，准备移动元素');
            });
          } else {
            // 如果已经在编辑状态，保持不变并启用拖拽
            debugPrint('→ 保持编辑状态不变 (已经选中)');

            // 关键修改：即使元素已经被选中，也设置拖拽状态，以便能够拖动元素
            setState(() {
              _isDragging = true;
              _dragStart = details.localPosition;
              _elementStartPosition = Offset(x, y);

              debugPrint('→ 设置拖拽状态，准备移动元素');
              debugPrint('  拖拽起始点: $_dragStart');
              debugPrint('  元素起始位置: $_elementStartPosition');
            });
          }

          // 打印状态变化后的信息
          Future.microtask(() {
            debugPrint('=== 点击元素 $id 后的状态 ===');
            debugPrint(
                '当前选中元素数量: ${_controller.state.selectedElementIds.length}');
            debugPrint('当前选中元素IDs: ${_controller.state.selectedElementIds}');
            debugPrint('元素起点：${element['x']}, ${element['y']}');
            debugPrint('元素尺寸: ${element['width']}x${element['height']}');
            debugPrint('\n');
          });
        }

        break;
      }
    }

    if (!hitElement) {
      // 打印点击空白区域的状态信息
      debugPrint('\n=== 点击空白区域 ===');
      debugPrint('当前选中元素数量: ${_controller.state.selectedElementIds.length}');
      debugPrint('当前选中元素IDs: ${_controller.state.selectedElementIds}');
      debugPrint('是否按下Ctrl或Shift键: ${_isCtrlPressed || _isShiftPressed}');

      if (!(_isCtrlPressed || _isShiftPressed)) {
        // 点击空白处且没有按下Ctrl或Shift键，取消选择
        debugPrint('→ 取消所有选择，进入普通状态');
        _controller.clearSelection();
        setState(() {
          // 重置拖拽状态
          _isDragging = false;
          debugPrint('→ 重置拖拽状态');
        });

        // 打印状态变化后的信息
        Future.microtask(() {
          debugPrint('=== 点击空白区域后的状态 ===');
          debugPrint(
              '当前选中元素数量: ${_controller.state.selectedElementIds.length}');
          debugPrint('当前选中元素IDs: ${_controller.state.selectedElementIds}');
          debugPrint('\n');
        });
      } else {
        debugPrint('→ 保持当前选择状态 (按下Ctrl或Shift键)');
      }
    }
  }

  // 加载字帖
  Future<void> _loadPractice(String id) async {
    // 这里应该实现实际的加载逻辑
    // 例如，从数据库或文件系统加载数据
  }

  /// 将元素下移一层
  void _moveElementDown() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index > 0) {
      // 交换元素位置
      final temp = elements[index];
      elements[index] = elements[index - 1];
      elements[index - 1] = temp;

      // 更新当前页面的元素
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
  }

  /// 将元素上移一层
  void _moveElementUp() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index < elements.length - 1) {
      // 交换元素位置
      final temp = elements[index];
      elements[index] = elements[index + 1];
      elements[index + 1] = temp;

      // 更新当前页面的元素
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
  }

  /// 粘贴元素
  void _pasteElement() {
    if (_clipboardElement == null) return;

    // 创建新元素ID
    final newId =
        '${_clipboardElement!['type']}_${DateTime.now().millisecondsSinceEpoch}';

    // 复制元素并修改位置（稍微偏移一点）
    final newElement = {
      ..._clipboardElement!,
      'id': newId,
      'x': (_clipboardElement!['x'] as num).toDouble() + 20,
      'y': (_clipboardElement!['y'] as num).toDouble() + 20,
    };

    // 添加到当前页面
    final elements = _controller.state.currentPageElements;
    elements.add(newElement);

    // 更新当前页面的元素
    _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
        elements;

    // 选中新粘贴的元素
    _controller.state.selectedElementIds = [newId];
    _controller.state.selectedElement = newElement;
    _controller.state.hasUnsavedChanges = true;

    setState(() {});
  }

  /// 将元素置于底层
  void _sendElementToBack() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index > 0) {
      // 移除元素
      final element = elements.removeAt(index);
      // 添加到开头（最底层）
      elements.insert(0, element);

      // 更新当前页面的元素
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
  }

  /// 选择本地图片
  Future<void> _showImageUrlDialog(BuildContext context) async {
    // 在实际应用中，这里应该使用文件选择器
    // 例如使用 file_picker 或 image_picker 插件
    // 以下是一个模拟实现，展示文件选择对话框

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择图片'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请选择要添加的图片文件'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, 'file://sample_image.jpg'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open),
                  SizedBox(width: 8),
                  Text('浏览文件...'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (result != null) {
      // 在实际应用中，这里应该处理选择的文件
      // 并将其转换为可用的URL或路径
      _controller.addImageElement(result);
    }
  }

  /// 根据图层顺序排序元素
  List<Map<String, dynamic>> _sortElementsByLayerOrder(
      List<Map<String, dynamic>> elements) {
    // 获取图层列表
    final layers = _controller.state.layers;

    // 创建图层顺序映射
    // 注意：图层在列表中的索引越大，表示越靠上层，应该越后绘制
    final layerOrderMap = <String, int>{};
    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i];
      final layerId = layer['id'] as String;
      layerOrderMap[layerId] = i; // 使用图层在列表中的索引作为排序依据
    }

    // 对元素进行排序
    final sortedElements = List<Map<String, dynamic>>.from(elements);
    sortedElements.sort((a, b) {
      final aLayerId = a['layerId'] as String?;
      final bLayerId = b['layerId'] as String?;

      // 如果元素没有图层ID，则放到最后
      if (aLayerId == null && bLayerId == null) return 0;
      if (aLayerId == null) return 1;
      if (bLayerId == null) return -1;

      // 根据图层顺序排序
      // 图层索引越大（越靠上层），应该越后绘制
      final aOrder = layerOrderMap[aLayerId] ?? 0;
      final bOrder = layerOrderMap[bLayerId] ?? 0;
      return aOrder.compareTo(bOrder); // 索引小的先绘制，索引大的后绘制
    });

    return sortedElements;
  }
}
