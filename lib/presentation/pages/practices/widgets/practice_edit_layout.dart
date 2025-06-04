import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../canvas/integration/practice_edit_canvas_adapter.dart';
import '../../../widgets/common/persistent_resizable_panel.dart';
import '../../../widgets/common/persistent_sidebar_toggle.dart';
import '../../../widgets/practice/m3_practice_layer_panel.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import '../services/unified_service_manager.dart';
import '../state/practice_edit_state_manager.dart';
import 'enhanced_thumbnail_strip.dart';
import 'unified_property_panel.dart';

/// 字帖编辑页面布局组件 - 完全修复版
/// 负责管理页面的布局结构，集成统一服务管理器
class PracticeEditLayout extends StatefulWidget {
  final PracticeEditController controller;
  final PracticeEditStateManager stateManager;

  const PracticeEditLayout({
    super.key,
    required this.controller,
    required this.stateManager,
  });

  @override
  State<PracticeEditLayout> createState() => _PracticeEditLayoutState();
}

class _PracticeEditLayoutState extends State<PracticeEditLayout>
    with TickerProviderStateMixin {
  /// 统一服务管理器实例
  late final UnifiedServiceManager _serviceManager;

  /// 快捷键监听器
  late final FocusNode _shortcutFocusNode;

  /// 格式刷模式控制器
  late final AnimationController _formatBrushAnimationController;

  /// 剪贴板内容指示器动画
  late final AnimationController _clipboardIndicatorController;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _shortcutFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          widget.controller,
          widget.stateManager,
          _serviceManager,
        ]),
        builder: (context, child) {
          return Column(
            children: [
              // 顶部工具栏
              if (!widget.stateManager.isPreviewMode) _buildSimpleToolbar(),

              // 主要内容区域
              Expanded(
                child: Row(
                  children: [
                    // Left panel
                    if (!widget.stateManager.isPreviewMode &&
                        widget.stateManager.isLeftPanelOpen)
                      _buildLeftPanel(),

                    // Left panel toggle
                    if (!widget.stateManager.isPreviewMode)
                      PersistentSidebarToggle(
                        sidebarId: 'practice_edit_left_panel',
                        defaultIsOpen: false,
                        onToggle: widget.stateManager.setLeftPanelOpen,
                        alignRight: false,
                      ),

                    // Central edit area
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Edit canvas
                          Expanded(
                            child: _buildCanvasArea(),
                          ),

                          // 页面缩略图条
                          if (!widget.stateManager.isPreviewMode &&
                              widget.stateManager.showThumbnails)
                            _buildEnhancedThumbnailStrip(),
                        ],
                      ),
                    ),

                    // Right panel toggle
                    if (!widget.stateManager.isPreviewMode)
                      PersistentSidebarToggle(
                        sidebarId: 'practice_edit_right_panel',
                        defaultIsOpen: true,
                        onToggle: widget.stateManager.setRightPanelOpen,
                        alignRight: true,
                      ),

                    // Right properties panel
                    if (!widget.stateManager.isPreviewMode &&
                        widget.stateManager.isRightPanelOpen)
                      _buildRightPanel(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _serviceManager.removeListener(_onServiceManagerChanged);
    _shortcutFocusNode.dispose();
    _formatBrushAnimationController.dispose();
    _clipboardIndicatorController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // 初始化服务管理器
    _serviceManager = UnifiedServiceManager.instance;
    _serviceManager.initialize();
    _serviceManager.setController(widget.controller);

    // 初始化快捷键监听
    _shortcutFocusNode = FocusNode();

    // 初始化动画控制器
    _formatBrushAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _clipboardIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // 监听服务状态变化
    _serviceManager.addListener(_onServiceManagerChanged);
  }

  /// 添加集字元素
  void _addCollectionElement() {
    widget.controller.addCollectionElementAt(100, 100, '练习');
  }

  /// 添加图片元素
  void _addImageElement() {
    widget.controller.addImageElementAt(100, 100, '');
  }

  /// 添加页面
  void _addPage() {
    widget.controller.addNewPage();
  }

  /// 添加文本元素
  void _addTextElement() {
    widget.controller.addTextElementAt(100, 100);
  }

  /// 底部对齐
  void _alignBottom() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    if (selectedIds.length > 1) {
      widget.controller.alignElements(selectedIds, 'bottom');
    }
  }

  /// 水平居中对齐
  void _alignCenterHorizontal() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    if (selectedIds.length > 1) {
      widget.controller.alignElements(selectedIds, 'center-horizontal');
    }
  }

  /// 垂直居中对齐
  void _alignCenterVertical() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    if (selectedIds.length > 1) {
      widget.controller.alignElements(selectedIds, 'center-vertical');
    }
  }

  /// 左对齐
  void _alignLeft() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    if (selectedIds.length > 1) {
      widget.controller.alignElements(selectedIds, 'left');
    }
  }

  /// 右对齐
  void _alignRight() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    if (selectedIds.length > 1) {
      widget.controller.alignElements(selectedIds, 'right');
    }
  }

  /// 顶部对齐
  void _alignTop() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    if (selectedIds.length > 1) {
      widget.controller.alignElements(selectedIds, 'top');
    }
  }

  /// 上移一层
  void _bringForward() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    for (final id in selectedIds) {
      widget.stateManager.moveElementUp(widget.controller);
    }
  }

  /// 置于顶层
  void _bringToFront() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    for (final id in selectedIds) {
      widget.stateManager.bringElementToFront(widget.controller);
    }
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    bool enabled = true,
    bool isActive = false,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: enabled ? onPressed : null,
        style: IconButton.styleFrom(
          backgroundColor: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : null,
          foregroundColor:
              isActive ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
    );
  }

  /// 构建画布区域
  Widget _buildCanvasArea() {
    return PracticeEditCanvasAdapter(
      controller: widget.controller,
      isPreviewMode: widget.stateManager.isPreviewMode,
      transformationController: widget.stateManager.transformationController,
    );
  }

  /// 构建增强的缩略图条
  Widget _buildEnhancedThumbnailStrip() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: EnhancedThumbnailStrip(
        pages: widget.controller.state.pages,
        currentPageIndex: widget.controller.state.currentPageIndex,
        onPageSelected: (pageIndex) =>
            widget.controller.setCurrentPage(pageIndex),
        onAddPage: _addPage,
        onDeletePage: _deletePage,
        onReorderPages: _reorderPage,
        controller: widget.controller,
      ),
    );
  }

  /// 构建左侧面板
  Widget _buildLeftPanel() {
    return PersistentResizablePanel(
      panelId: 'practice_edit_left_panel',
      initialWidth: 300.0,
      minWidth: 200.0,
      maxWidth: 400.0,
      child: M3PracticeLayerPanel(
        controller: widget.controller,
        onLayerSelect: (layerId) => widget.controller.selectLayer(layerId),
        onLayerVisibilityToggle: (layerId, isVisible) =>
            widget.controller.toggleLayerVisibility(layerId, isVisible),
        onLayerLockToggle: (layerId, isLocked) =>
            widget.controller.toggleLayerLock(layerId, isLocked),
        onAddLayer: () => widget.controller.addLayer(),
        onDeleteLayer: (layerId) => widget.controller.deleteLayer(layerId),
        onReorderLayer: (oldIndex, newIndex) =>
            widget.controller.reorderLayers(oldIndex, newIndex),
      ),
    );
  }

  /// 构建右侧面板
  Widget _buildRightPanel() {
    return PersistentResizablePanel(
      panelId: 'practice_edit_right_panel',
      initialWidth: 320.0,
      minWidth: 250.0,
      maxWidth: 500.0,
      isLeftPanel: false,
      child: UnifiedPropertyPanel(
        selectedElements: widget.controller.state.getSelectedElements(),
        onPropertyChanged: (elementId, property, value) {
          widget.controller
              .updateElementProperties(elementId, {property: value});
        },
      ),
    );
  }

  /// 构建服务状态指示器
  Widget _buildServiceStatusChips() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 剪贴板状态
        if (_serviceManager.hasClipboardContent)
          AnimatedBuilder(
            animation: _clipboardIndicatorController,
            builder: (context, child) {
              return Opacity(
                opacity: _clipboardIndicatorController.value,
                child: Chip(
                  avatar: const Icon(Icons.content_paste, size: 16),
                  label:
                      Text('剪贴板: ${_serviceManager.clipboardHistory.length}'),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ),
              );
            },
          ),

        const SizedBox(width: 8),

        // 格式刷状态
        if (_serviceManager.hasFormat)
          AnimatedBuilder(
            animation: _formatBrushAnimationController,
            builder: (context, child) {
              return Chip(
                avatar: const Icon(Icons.format_paint, size: 16),
                label: const Text('格式刷已激活'),
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(
                          0.1 + (_formatBrushAnimationController.value * 0.05),
                        ),
              );
            },
          ),
      ],
    );
  }

  /// 构建增强的工具栏
  Widget _buildSimpleToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 基础编辑操作
            _buildActionButton(
              icon: Icons.undo,
              tooltip: '撤销 (Ctrl+Z)',
              enabled: _serviceManager.canUndo,
              onPressed: _undo,
            ),
            _buildActionButton(
              icon: Icons.redo,
              tooltip: '重做 (Ctrl+Y)',
              enabled: _serviceManager.canRedo,
              onPressed: _redo,
            ),

            const VerticalDivider(),

            // 元素添加操作
            _buildActionButton(
              icon: Icons.text_fields,
              tooltip: '添加文本',
              onPressed: _addTextElement,
            ),
            _buildActionButton(
              icon: Icons.image,
              tooltip: '添加图片',
              onPressed: _addImageElement,
            ),
            _buildActionButton(
              icon: Icons.auto_awesome,
              tooltip: '添加集字',
              onPressed: _addCollectionElement,
            ),
            _buildActionButton(
              icon: Icons.group_work,
              tooltip: '创建组合',
              onPressed: _createGroup,
            ),

            const VerticalDivider(),

            // 剪贴板操作
            _buildActionButton(
              icon: Icons.copy,
              tooltip: '复制 (Ctrl+C)',
              onPressed: _copyElements,
            ),
            _buildActionButton(
              icon: Icons.paste,
              tooltip: '粘贴 (Ctrl+V)',
              enabled: _serviceManager.hasClipboardContent,
              onPressed: _pasteElements,
            ),
            _buildActionButton(
              icon: Icons.content_cut,
              tooltip: '剪切 (Ctrl+X)',
              onPressed: _cutElements,
            ),

            const VerticalDivider(),

            // 选择操作
            _buildActionButton(
              icon: Icons.select_all,
              tooltip: '全选 (Ctrl+A)',
              onPressed: _selectAllElements,
            ),
            _buildActionButton(
              icon: Icons.deselect,
              tooltip: '取消选择 (Esc)',
              onPressed: _deselectAllElements,
            ),

            const VerticalDivider(),

            // 排列操作
            _buildActionButton(
              icon: Icons.flip_to_front,
              tooltip: '置于顶层',
              onPressed: _bringToFront,
            ),
            _buildActionButton(
              icon: Icons.flip_to_back,
              tooltip: '置于底层',
              onPressed: _sendToBack,
            ),
            _buildActionButton(
              icon: Icons.keyboard_arrow_up,
              tooltip: '上移一层',
              onPressed: _bringForward,
            ),
            _buildActionButton(
              icon: Icons.keyboard_arrow_down,
              tooltip: '下移一层',
              onPressed: _sendBackward,
            ),

            const VerticalDivider(),

            // 对齐操作
            _buildActionButton(
              icon: Icons.align_horizontal_left,
              tooltip: '左对齐',
              onPressed: _alignLeft,
            ),
            _buildActionButton(
              icon: Icons.align_horizontal_center,
              tooltip: '水平居中',
              onPressed: _alignCenterHorizontal,
            ),
            _buildActionButton(
              icon: Icons.align_horizontal_right,
              tooltip: '右对齐',
              onPressed: _alignRight,
            ),
            _buildActionButton(
              icon: Icons.align_vertical_top,
              tooltip: '顶部对齐',
              onPressed: _alignTop,
            ),
            _buildActionButton(
              icon: Icons.align_vertical_center,
              tooltip: '垂直居中',
              onPressed: _alignCenterVertical,
            ),
            _buildActionButton(
              icon: Icons.align_vertical_bottom,
              tooltip: '底部对齐',
              onPressed: _alignBottom,
            ),

            const VerticalDivider(),

            // 分布操作
            _buildActionButton(
              icon: Icons.format_line_spacing, // Changed from Icons.distribute which doesn't exist
              tooltip: '水平分布',
              onPressed: _distributeHorizontally,
            ),
            _buildActionButton(
              icon: Icons.vertical_distribute,
              tooltip: '垂直分布',
              onPressed: _distributeVertically,
            ),

            const VerticalDivider(),

            // 锁定和可见性
            _buildActionButton(
              icon: widget.controller.state.selectedElementIds.any((id) {
                final element =
                    widget.controller.state.currentPageElements.firstWhere(
                  (e) => e['id'] == id,
                  orElse: () => <String, dynamic>{},
                );
                return element['locked'] == true;
              })
                  ? Icons.lock
                  : Icons.lock_open,
              tooltip: '锁定/解锁元素',
              onPressed: _toggleLockSelected,
            ),
            _buildActionButton(
              icon: widget.controller.state.selectedElementIds.any((id) {
                final element =
                    widget.controller.state.currentPageElements.firstWhere(
                  (e) => e['id'] == id,
                  orElse: () => <String, dynamic>{},
                );
                return element['hidden'] == true;
              })
                  ? Icons.visibility_off
                  : Icons.visibility,
              tooltip: '显示/隐藏元素',
              onPressed: _toggleVisibilitySelected,
            ),

            const VerticalDivider(),

            // 格式操作
            _buildActionButton(
              icon: Icons.format_paint,
              tooltip: '复制格式',
              isActive: _serviceManager.hasFormat,
              onPressed: _copyFormatting,
            ),
            _buildActionButton(
              icon: Icons.format_color_fill,
              tooltip: '粘贴格式',
              enabled: _serviceManager.hasFormat,
              onPressed: _pasteFormatting,
            ),

            const VerticalDivider(),

            // 网格和吸附
            _buildActionButton(
              icon: Icons.grid_on,
              tooltip: '显示/隐藏网格',
              isActive: widget.controller.state.showGrid,
              onPressed: _toggleGrid,
            ),
            _buildActionButton(
              icon: Icons.radio_button_checked,
              tooltip: '网格吸附',
              isActive: widget.controller.state.snapEnabled,
              onPressed: _toggleSnap,
            ),

            const VerticalDivider(),

            // 视图操作
            _buildActionButton(
              icon: Icons.zoom_in,
              tooltip: '放大',
              onPressed: _zoomIn,
            ),
            _buildActionButton(
              icon: Icons.zoom_out,
              tooltip: '缩小',
              onPressed: _zoomOut,
            ),
            _buildActionButton(
              icon: Icons.fit_screen,
              tooltip: '适合屏幕',
              onPressed: _fitToScreen,
            ),
            _buildActionButton(
              icon: Icons.zoom_out_map,
              tooltip: '100%缩放',
              onPressed: _resetZoom,
            ),

            const VerticalDivider(),

            // 删除操作
            _buildActionButton(
              icon: Icons.delete,
              tooltip: '删除 (Delete)',
              onPressed: _deleteSelectedElements,
            ),

            const SizedBox(width: 16),

            // 服务状态指示器
            _buildServiceStatusChips(),
          ],
        ),
      ),
    );
  }

  /// 复制元素
  void _copyElements() {
    // 使用服务管理器复制选中的元素
    final selectedElements = widget.controller.state.getSelectedElements();
    if (selectedElements.isNotEmpty) {
      _serviceManager.copyElements(selectedElements);
    }
  }

  /// 复制格式
  void _copyFormatting() {
    // 使用服务管理器复制选中元素的格式
    final selectedElements = widget.controller.state.getSelectedElements();
    if (selectedElements.isNotEmpty) {
      _serviceManager.copyFormat(selectedElements);
    }
  }

  /// 创建组合
  void _createGroup() {
    final selectedElements = widget.controller.state.getSelectedElements();
    if (selectedElements.length > 1) {
      widget.controller.groupElements(
        widget.controller.state.selectedElementIds.toList(),
      );
    }
  }

  /// 剪切元素
  void _cutElements() {
    final selectedElements = widget.controller.state.getSelectedElements();
    if (selectedElements.isNotEmpty) {
      _serviceManager.copyElements(selectedElements);
      widget.controller.deleteSelectedElements();
    }
  }

  /// 删除页面
  void _deletePage(int pageIndex) {
    if (widget.controller.state.pages.length > 1) {
      widget.controller.deletePage(pageIndex);
    }
  }

  /// 删除选中元素
  void _deleteSelectedElements() {
    widget.controller.deleteSelectedElements();
  }

  /// 取消选择所有元素
  void _deselectAllElements() {
    widget.controller.clearSelection();
  }

  /// 水平分布
  void _distributeHorizontally() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    if (selectedIds.length > 2) {
      widget.controller.distributeElements(selectedIds, 'horizontal');
    }
  }

  /// 垂直分布
  void _distributeVertically() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    if (selectedIds.length > 2) {
      widget.controller.distributeElements(selectedIds, 'vertical');
    }
  }

  /// 适合屏幕
  void _fitToScreen() {
    // 调用Canvas的适合屏幕功能
    // 暂时使用重置变换的方式
    widget.stateManager.transformationController.value = Matrix4.identity();
  }

  /// 处理键盘事件
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed =
          event.logicalKey == LogicalKeyboardKey.controlLeft ||
              event.logicalKey == LogicalKeyboardKey.controlRight ||
              HardwareKeyboard.instance.isControlPressed;

      if (isCtrlPressed) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.keyZ:
            _undo();
            break;
          case LogicalKeyboardKey.keyY:
            _redo();
            break;
          case LogicalKeyboardKey.keyC:
            _copyElements();
            break;
          case LogicalKeyboardKey.keyV:
            _pasteElements();
            break;
          case LogicalKeyboardKey.keyX:
            _cutElements();
            break;
          case LogicalKeyboardKey.keyA:
            _selectAllElements();
            break;
        }
      } else {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.delete:
            _deleteSelectedElements();
            break;
          case LogicalKeyboardKey.escape:
            _deselectAllElements();
            break;
        }
      }
    }
  }

  /// 服务管理器状态变化处理
  void _onServiceManagerChanged() {
    if (mounted) {
      setState(() {
        // 格式刷状态变化
        if (_serviceManager.hasFormat) {
          if (!_formatBrushAnimationController.isAnimating) {
            _formatBrushAnimationController.repeat(reverse: true);
          }
        } else {
          _formatBrushAnimationController.stop();
          _formatBrushAnimationController.reset();
        }

        // 剪贴板状态变化
        if (_serviceManager.hasClipboardContent) {
          _clipboardIndicatorController.forward();
        } else {
          _clipboardIndicatorController.reverse();
        }
      });
    }
  }

  /// 粘贴元素
  void _pasteElements() {
    // 使用服务管理器粘贴元素
    final elements = _serviceManager.pasteElements();
    if (elements != null && elements.isNotEmpty) {
      // 添加粘贴的元素到当前页面
      for (final element in elements) {
        // 根据元素类型使用对应的添加方法
        final elementType = element['type'] as String? ?? '';
        final x = element['x'] as double? ?? 100.0;
        final y = element['y'] as double? ?? 100.0;

        if (elementType == 'collection') {
          final content = element['content'] as Map<String, dynamic>? ?? {};
          final characters = content['characters'] as String? ?? '';
          widget.controller.addCollectionElementAt(x, y, characters);
        } else if (elementType == 'image') {
          final content = element['content'] as Map<String, dynamic>? ?? {};
          final imageUrl = content['url'] as String? ?? '';
          widget.controller.addImageElementAt(x, y, imageUrl);
        } else if (elementType == 'text') {
          widget.controller.addTextElementAt(x, y);
        }
      }
    }
  }

  /// 粘贴格式
  void _pasteFormatting() {
    // 应用格式刷到选中元素
    final selectedElements = widget.controller.state.getSelectedElements();
    if (selectedElements.isNotEmpty) {
      _serviceManager.applyFormatBrush(selectedElements);
    }
  }

  /// 重做操作
  void _redo() {
    _serviceManager.redo();
  }

  /// 重新排序页面
  void _reorderPage(int oldIndex, int newIndex) {
    widget.controller.reorderPages(oldIndex, newIndex);
  }

  /// 重置缩放到100%
  void _resetZoom() {
    widget.controller.zoomTo(1.0);
  }

  /// 选择所有元素
  void _selectAllElements() {
    widget.controller.selectAll();
  }

  /// 下移一层
  void _sendBackward() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    for (final id in selectedIds) {
      widget.controller.sendElementBackward(id);
    }
  }

  /// 置于底层
  void _sendToBack() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    for (final id in selectedIds) {
      widget.controller.sendElementToBack(id);
    }
  }

  /// 切换网格显示
  void _toggleGrid() {
    // 暂时禁用，需要在state中添加showGrid属性
    // widget.controller.toggleGrid();
  }

  /// 切换选中元素的锁定状态
  void _toggleLockSelected() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    for (final id in selectedIds) {
      final element = widget.controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (element.isNotEmpty) {
        final isLocked = element['locked'] as bool? ?? false;
        widget.controller.updateElementProperties(id, {'locked': !isLocked});
      }
    }
  }

  /// 切换网格吸附
  void _toggleSnap() {
    widget.controller.toggleSnap();
  }

  /// 切换选中元素的可见性
  void _toggleVisibilitySelected() {
    final selectedIds = widget.controller.state.selectedElementIds.toList();
    for (final id in selectedIds) {
      final element = widget.controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (element.isNotEmpty) {
        final isHidden = element['hidden'] as bool? ?? false;
        widget.controller.updateElementProperties(id, {'hidden': !isHidden});
      }
    }
  }

  /// 撤销操作
  void _undo() {
    _serviceManager.undo();
  }

  /// 放大
  void _zoomIn() {
    final currentScale =
        widget.stateManager.transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(0.1, 5.0);
    widget.controller.zoomTo(newScale);
  }

  /// 缩小
  void _zoomOut() {
    final currentScale =
        widget.stateManager.transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(0.1, 5.0);
    widget.controller.zoomTo(newScale);
  }
}
