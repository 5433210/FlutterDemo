import 'package:demo/presentation/widgets/page_layout.dart';
import 'package:demo/presentation/widgets/practice/top_navigation_bar.dart';
import 'package:flutter/gestures.dart';
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
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (details) {
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
        },
        onPanUpdate: (details) {
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
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: Container(
          width: size.width,
          height: size.height,
          color: Colors.transparent,
        ),
      ),
    );
  }

  /// 构建控制点
  Widget _buildControlPoints(String elementId, double width, double height) {
    return GestureDetector(
      // 阻止点击事件传递到元素上
      onTap: () {},
      child: Stack(
        children: [
          // 使用现有的控制点渲染器
          ControlHandlers.buildTransformControls(width, height),

          // 添加对各个控制点的手势检测
          // 左上角
          _buildControlPointDetector(
            elementId,
            0,
            const Offset(-4, -4),
            const Size(8, 8),
          ),
          // 上中
          _buildControlPointDetector(
            elementId,
            1,
            Offset(width / 2 - 4, -4),
            const Size(8, 8),
          ),
          // 右上角
          _buildControlPointDetector(
            elementId,
            2,
            Offset(width - 4, -4),
            const Size(8, 8),
          ),
          // 右中
          _buildControlPointDetector(
            elementId,
            3,
            Offset(width - 4, height / 2 - 4),
            const Size(8, 8),
          ),
          // 右下角
          _buildControlPointDetector(
            elementId,
            4,
            Offset(width - 4, height - 4),
            const Size(8, 8),
          ),
          // 下中
          _buildControlPointDetector(
            elementId,
            5,
            Offset(width / 2 - 4, height - 4),
            const Size(8, 8),
          ),
          // 左下角
          _buildControlPointDetector(
            elementId,
            6,
            Offset(-4, height - 4),
            const Size(8, 8),
          ),
          // 左中
          _buildControlPointDetector(
            elementId,
            7,
            Offset(-4, height / 2 - 4),
            const Size(8, 8),
          ),
          // 旋转控制点
          _buildControlPointDetector(
            elementId,
            8,
            Offset(width / 2 - 5, -30),
            const Size(10, 10),
            isRotation: true,
          ),
        ],
      ),
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
        const pageWidth = 595.0; // A4 宽度 (72dpi)
        const pageHeight = 842.0; // A4 高度 (72dpi)

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
        return GestureDetector(
          onTapDown: (details) => _handleTapDown(details, elements),
          child: Container(
            color: Colors.grey.shade200,
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(double.infinity),
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.1,
              maxScale: 15.0,
              scaleFactor: 200.0, // 增大缩放因子，减小缩放幅度
              constrained: false, // 添加这一行，使内容不受约束
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
                        for (final element in elements) _buildElement(element),

                        // 拖拽指示
                        if (candidateData.isNotEmpty)
                          Container(
                            width: 595,
                            height: 842,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blue,
                                width: 2,
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
          for (final id in _controller.state.selectedElementIds) {
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
        content = ElementRenderers.buildGroupElement(element);
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
      child: GestureDetector(
        onTap: _isPreviewMode
            ? null // 预览模式下禁用选择
            : () => _controller.selectElement(id,
                isMultiSelect: _isCtrlPressed || _isShiftPressed),
        onPanStart: _isPreviewMode
            ? null // 预览模式下禁用拖动
            : (details) {
                // 如果元素未选中，先选中它
                if (!isSelected) {
                  _controller.selectElement(id,
                      isMultiSelect: _isCtrlPressed || _isShiftPressed);
                }

                setState(() {
                  _isDragging = true;
                  _dragStart = details.localPosition;
                  _elementStartPosition = Offset(x, y);
                });
              },
        onPanUpdate: _isPreviewMode || !_isDragging
            ? null
            : (details) {
                final dx = details.localPosition.dx - _dragStart.dx;
                final dy = details.localPosition.dy - _dragStart.dy;
                final newX = _elementStartPosition.dx + dx;
                final newY = _elementStartPosition.dy + dy;

                _controller.updateElementProperties(id, {
                  'x': newX,
                  'y': newY,
                });
              },
        onPanEnd: _isPreviewMode || !_isDragging
            ? null
            : (details) {
                setState(() {
                  _isDragging = false;
                });
              },
        child: Transform.rotate(
          angle: rotation * 3.1415926 / 180,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: width,
              height: height,
              decoration: !_isPreviewMode && isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                    )
                  : null,
              child: Stack(
                children: [
                  // 元素内容
                  content,

                  // 如果选中且不在预览模式，显示控制点
                  if (!_isPreviewMode && isSelected)
                    _buildControlPoints(id, width, height),
                ],
              ),
            ),
          ),
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

  /// 处理鼠标滚轮事件
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // 计算缩放增量，使用更小的值来减小缩放幅度
      final double delta = event.scrollDelta.dy * 0.003;

      // 获取当前缩放比例
      final double currentScale =
          _transformationController.value.getMaxScaleOnAxis();

      // 计算新的缩放比例，并限制在最小和最大缩放比例之间
      final double newScale = (currentScale - delta).clamp(0.1, 15.0);

      // 获取鼠标在屏幕上的位置
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final Offset localFocalPoint = renderBox.globalToLocal(event.position);

      // 使用更简单的方法实现以鼠标位置为中心的缩放
      final Matrix4 zoomMatrix = Matrix4.identity()
        ..translate(localFocalPoint.dx, localFocalPoint.dy)
        ..scale(newScale / currentScale)
        ..translate(-localFocalPoint.dx, -localFocalPoint.dy);

      // 将缩放矩阵与当前变换矩阵相乘
      final Matrix4 newMatrix = zoomMatrix * _transformationController.value;

      // 应用新的变换矩阵
      _transformationController.value = newMatrix;
    }
  }

  /// 处理点击事件
  void _handleTapDown(
      TapDownDetails details, List<Map<String, dynamic>> elements) {
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
      // 注意：旋转角度在简单碰撞检测中暂未使用，但在更复杂的检测中会用到

      // 简单的矩形碰撞检测
      // 注意：对于旋转的元素，这种检测不是完全准确的
      // 实际应用中应该使用更复杂的旋转矩形检测
      if (details.localPosition.dx >= x &&
          details.localPosition.dx <= x + width &&
          details.localPosition.dy >= y &&
          details.localPosition.dy <= y + height) {
        hitElement = true;

        // 使用Ctrl或Shift键进行多选
        _controller.selectElement(id,
            isMultiSelect: _isCtrlPressed || _isShiftPressed);
        break;
      }
    }

    if (!hitElement && !(_isCtrlPressed || _isShiftPressed)) {
      // 点击空白处且没有按下Ctrl或Shift键，取消选择
      _controller.clearSelection();
      setState(() {});
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
}
