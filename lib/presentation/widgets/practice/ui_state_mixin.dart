import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'practice_edit_state.dart';

/// UI状态管理 Mixin
/// 负责UI相关的状态管理，如预览模式、网格显示、吸附等
mixin UIStateMixin on ChangeNotifier {
  GlobalKey? get canvasKey;
  set canvasKey(GlobalKey? key);
  dynamic get editCanvas;
  Function(bool)? get previewModeCallback;

  set previewModeCallback(Function(bool)? callback);
  // 抽象接口
  PracticeEditState get state;
  void checkDisposed();

  /// 退出选择模式
  void exitSelectMode() {
    final oldTool = state.currentTool;
    state.currentTool = '';
    EditPageLogger.controllerInfo('退出选择模式', 
      data: {'previousTool': oldTool});
    notifyListeners();
  }

  /// 重置视图位置到默认状态
  void resetViewPosition() {
    if (editCanvas != null && editCanvas.resetCanvasPosition != null) {
      try {
        editCanvas.resetCanvasPosition();
        EditPageLogger.controllerDebug('重置视图位置成功');
      } catch (e) {
        EditPageLogger.controllerError('重置视图位置失败', error: e);
      }
    }
  }

  /// 重置画布缩放
  void resetZoom() {
    final oldScale = state.canvasScale;
    state.canvasScale = 1.0;
    EditPageLogger.controllerDebug('重置画布缩放', 
      data: {'oldScale': oldScale, 'newScale': 1.0});
    notifyListeners();
  }

  /// 选择所有元素
  void selectAll() {
    // 获取当前页面上的所有元素
    if (state.currentPageIndex >= 0 &&
        state.currentPageIndex < state.pages.length) {
      final page = state.pages[state.currentPageIndex];
      final elements = page['elements'] as List<dynamic>;

      // 清除当前选择
      state.selectedElementIds.clear();

      // 选择所有非隐藏元素
      for (final element in elements) {
        // 检查元素是否隐藏
        final isHidden =
            element['hidden'] == true || element['isHidden'] == true;
        if (!isHidden) {
          // 检查元素所在图层是否隐藏
          final layerId = element['layerId'] as String?;
          bool isLayerHidden = false;
          if (layerId != null) {
            final layer = state.getLayerById(layerId);
            if (layer != null) {
              isLayerHidden = layer['isVisible'] == false;
            }
          }

          // 如果元素和其所在图层都可见，就选择它
          if (!isLayerHidden) {
            final id = element['id'] as String;
            state.selectedElementIds.add(id);
          }
        }
      }

      // 如果选中了多个元素，设置为空，否则使用第一个元素
      state.selectedElement = state.selectedElementIds.length == 1
          ? elements
              .firstWhere((e) => e['id'] == state.selectedElementIds.first)
          : null;
      
      EditPageLogger.controllerInfo('全选操作完成', 
        data: {'selectedCount': state.selectedElementIds.length});
    }

    notifyListeners();
  }

  /// 选择页面
  void selectPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < state.pages.length) {
      final oldIndex = state.currentPageIndex;
      state.currentPageIndex = pageIndex;
      // Clear element and layer selections to show page properties
      state.selectedElementIds.clear();
      state.selectedElement = null;
      state.selectedLayerId = null;
      
      EditPageLogger.controllerInfo('选择页面', 
        data: {'oldIndex': oldIndex, 'newIndex': pageIndex});
      notifyListeners();
    }
  }

  /// 设置画布 GlobalKey
  void setCanvasKey(GlobalKey key) {
    checkDisposed();
    canvasKey = key;
  }

  /// 设置当前页面
  void setCurrentPage(int index) {
    if (index >= 0 && index < state.pages.length) {
      final oldIndex = state.currentPageIndex;
      state.currentPageIndex = index;
      // Clear element and layer selections to show page properties
      state.selectedElementIds.clear();
      state.selectedElement = null;
      state.selectedLayerId = null;

      // 确保图层面板显示当前页面的图层
      // 这里我们可以添加页面特定的图层加载逻辑
      // 目前我们使用全局图层，但将来可能需要每个页面有自己的图层

      EditPageLogger.controllerInfo('设置当前页面', 
        data: {'oldIndex': oldIndex, 'newIndex': index});
      notifyListeners();
    }
  }

  /// 设置预览模式回调函数
  void setPreviewModeCallback(Function(bool) callback) {
    checkDisposed();
    previewModeCallback = callback;
  }

  /// 切换网格显示
  void toggleGrid() {
    final newState = !state.gridVisible;
    state.gridVisible = newState;
    EditPageLogger.controllerDebug('切换网格显示', 
      data: {'visible': newState});
    notifyListeners();
  }

  /// 切换预览模式
  void togglePreviewMode(bool isPreviewMode) {
    final oldMode = state.isPreviewMode;
    state.isPreviewMode = isPreviewMode;

    // 自动重置视图位置
    resetViewPosition();

    // 调用预览模式回调函数
    if (previewModeCallback != null) {
      previewModeCallback!(isPreviewMode);
    }

    EditPageLogger.controllerInfo('切换预览模式', 
      data: {'oldMode': oldMode, 'newMode': isPreviewMode});
    notifyListeners();
  }

  /// 切换吸附功能
  void toggleSnap() {
    final newState = !state.snapEnabled;
    state.snapEnabled = newState;
    EditPageLogger.controllerDebug('切换吸附功能', 
      data: {'enabled': newState});
    notifyListeners();
  }

  /// 设置画布缩放值
  void zoomTo(double scale) {
    checkDisposed();
    final oldScale = state.canvasScale;
    final newScale = scale.clamp(0.1, 10.0); // 限制缩放范围
    
    // 🚀 性能优化：避免无效的缩放设置
    if ((oldScale - newScale).abs() < 0.001) {
      EditPageLogger.performanceInfo('跳过相同缩放值设置', 
        data: {
          'oldScale': oldScale, 
          'requestedScale': scale, 
          'optimization': 'skip_identical_zoom'
        });
      return;
    }
    
    state.canvasScale = newScale;
    
    EditPageLogger.controllerDebug('设置画布缩放', 
      data: {'oldScale': oldScale, 'newScale': newScale, 'requestedScale': scale});
    notifyListeners();
  }
}
