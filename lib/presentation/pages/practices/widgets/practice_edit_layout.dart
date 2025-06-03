import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/common/persistent_resizable_panel.dart';
import '../../../widgets/common/persistent_sidebar_toggle.dart';
import '../../../widgets/practice/m3_practice_layer_panel.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import '../services/unified_service_manager.dart';
import '../state/practice_edit_state_manager.dart';
import 'enhanced_thumbnail_strip.dart';
import 'm3_practice_edit_canvas.dart';
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

  /// 添加页面
  void _addPage() {
    widget.controller.addNewPage();
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
    return M3PracticeEditCanvas(
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

  /// 构建简化的工具栏
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

          // 删除操作
          _buildActionButton(
            icon: Icons.delete,
            tooltip: '删除 (Delete)',
            onPressed: _deleteSelectedElements,
          ),

          const Spacer(),

          // 服务状态指示器
          _buildServiceStatusChips(),
        ],
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

  /// 处理键盘事件
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

      // 基础快捷键处理
      if (isCtrlPressed) {
        switch (key) {
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
          case LogicalKeyboardKey.keyA:
            _selectAllElements();
            break;
        }
      } else {
        switch (key) {
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

  /// 选择所有元素
  void _selectAllElements() {
    widget.controller.selectAll();
  }

  /// 撤销操作
  void _undo() {
    _serviceManager.undo();
  }
}
