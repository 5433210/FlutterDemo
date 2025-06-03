import 'package:flutter/material.dart';

import '../../../widgets/common/persistent_resizable_panel.dart';
import '../../../widgets/common/persistent_sidebar_toggle.dart';
import '../../../widgets/practice/m3_edit_toolbar.dart';
import '../../../widgets/practice/m3_page_thumbnail_strip.dart';
import '../../../widgets/practice/m3_practice_layer_panel.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import '../state/practice_edit_state_manager.dart';
import 'm3_practice_edit_canvas.dart';

/// 字帖编辑页面布局组件
/// 负责管理页面的布局结构，分离关注点
class PracticeEditLayout extends StatelessWidget {
  final PracticeEditController controller;
  final PracticeEditStateManager stateManager;

  const PracticeEditLayout({
    super.key,
    required this.controller,
    required this.stateManager,
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, stateManager]),
      builder: (context, child) {
        return Column(
          children: [
            // 顶部工具栏
            if (!stateManager.isPreviewMode) _buildToolbar(),

            // 主要内容区域
            Expanded(
              child: Row(
                children: [
                  // Left panel
                  if (!stateManager.isPreviewMode &&
                      stateManager.isLeftPanelOpen)
                    _buildLeftPanel(),
                  // Left panel toggle
                  if (!stateManager.isPreviewMode)
                    PersistentSidebarToggle(
                      sidebarId: 'practice_edit_left_panel',
                      defaultIsOpen: false,
                      onToggle: stateManager.setLeftPanelOpen,
                      alignRight: false,
                    ),

                  // Central edit area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Edit canvas
                        Expanded(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height - 200,
                            child: M3PracticeEditCanvas(
                              key: stateManager.canvasKey,
                              controller: controller,
                              isPreviewMode: stateManager.isPreviewMode,
                              transformationController:
                                  stateManager.transformationController,
                            ),
                          ),
                        ),

                        // 页面缩略图条
                        if (!stateManager.isPreviewMode &&
                            stateManager.showThumbnails)
                          _buildThumbnailStrip(),
                      ],
                    ),
                  ),

                  // Right panel toggle
                  if (!stateManager.isPreviewMode)
                    PersistentSidebarToggle(
                      sidebarId: 'practice_edit_right_panel',
                      defaultIsOpen: true,
                      onToggle: stateManager.setRightPanelOpen,
                      alignRight: true,
                    ),

                  // Right properties panel
                  if (!stateManager.isPreviewMode &&
                      stateManager.isRightPanelOpen)
                    _buildRightPanel(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建左侧面板
  Widget _buildLeftPanel() {
    return PersistentResizablePanel(
      panelId: 'practice_edit_left_panel',
      minWidth: 250.0,
      maxWidth: 500.0,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: M3PracticeLayerPanel(
          controller: controller,
          onLayerSelect: (layerId) {
            // 设置当前图层
            controller.state.selectedLayerId = layerId;
            controller.notifyListeners();
          },
          onLayerVisibilityToggle: controller.toggleLayerVisibility,
          onLayerLockToggle: controller.toggleLayerLock,
          onAddLayer: controller.addLayer,
          onDeleteLayer: controller.deleteLayer,
          onReorderLayer: controller.reorderLayers,
        ),
      ),
    );
  }

  /// 构建属性面板
  Widget _buildPropertyPanels() {
    // 使用selectedElementIds而不是selectedElements
    final selectedElementIds = controller.state.selectedElementIds;

    if (selectedElementIds.isEmpty) {
      // 显示页面属性面板
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text('Page Properties'),
        ),
      );
    } else if (selectedElementIds.length == 1) {
      // 显示单个元素属性面板
      final element = controller.state.getElementById(selectedElementIds.first);
      if (element == null) {
        return const Center(child: Text('Element not found'));
      }

      final elementType = element['type'] as String?;

      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text('${elementType ?? 'Unknown'} Element Properties'),
        ),
      );
    } else {
      // 显示多选属性面板
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child:
              Text('Multiple Elements Selected (${selectedElementIds.length})'),
        ),
      );
    }
  }

  /// 构建右侧面板
  Widget _buildRightPanel() {
    return PersistentResizablePanel(
      panelId: 'practice_edit_right_panel',
      minWidth: 250.0,
      maxWidth: 500.0,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: _buildPropertyPanels(),
      ),
    );
  }

  /// 构建属性面板

  /// 构建页面缩略图条
  Widget _buildThumbnailStrip() {
    return M3PageThumbnailStrip(
      pages: controller.state.pages,
      currentPageIndex: controller.state.currentPageIndex,
      onPageSelected: controller.setCurrentPage,
      onAddPage: () => controller.addPage({}),
      onDeletePage: (pageIndex) {
        controller.deletePage(pageIndex);
      },
      onReorderPages: controller.reorderPages,
    );
  }

  Widget _buildToolbar() {
    return M3EditToolbar(
      controller: controller,
      gridVisible: controller.state.gridVisible,
      snapEnabled: controller.state.snapEnabled,
      canPaste: stateManager.clipboardHasContent,
      onToggleGrid: () {
        // 切换网格显示
        controller.state.gridVisible = !controller.state.gridVisible;
        controller.notifyListeners();
      },
      onToggleSnap: () {
        // 切换吸附功能
        controller.state.snapEnabled = !controller.state.snapEnabled;
        controller.notifyListeners();
      },
      onCopy: () => stateManager.copySelectedElements(controller),
      onPaste: () => stateManager.paste(controller),
      onGroupElements: () {
        // 组合选中的元素 - 占位符实现
        debugPrint('Group elements functionality');
      },
      onUngroupElements: () {
        // 取消组合选中的元素 - 占位符实现
        debugPrint('Ungroup elements functionality');
      },
      onBringToFront: () => stateManager.bringElementToFront(controller),
      onSendToBack: () => stateManager.sendElementToBack(controller),
      onMoveUp: () => stateManager.moveElementUp(controller),
      onMoveDown: () => stateManager.moveElementDown(controller),
      onDelete: () {
        // 删除选中的元素 - 占位符实现
        debugPrint('Delete elements functionality');
      },
      onCopyFormatting: () => stateManager.copyFormatting(controller),
      onApplyFormatBrush: () => stateManager.applyFormatBrush(controller),
      currentTool: stateManager.currentTool,
      onSelectTool: stateManager.setCurrentTool,
      onSelectAll: () {
        // 选中所有元素
        final allElementIds = controller.state.currentPageElements
            .map((e) => e['id'] as String)
            .toList();
        controller.state.selectedElementIds = allElementIds;
        controller.notifyListeners();
      },
      onDeselectAll: () {
        // 取消所有选择
        controller.state.selectedElementIds.clear();
        controller.notifyListeners();
      },
    );
  }
}
