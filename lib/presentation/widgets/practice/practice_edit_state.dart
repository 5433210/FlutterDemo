import 'package:flutter/services.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'guideline_alignment/guideline_types.dart';

/// 字帖编辑状态类
class PracticeEditState {
  // 字帖基本信息
  String? practiceId;
  String? practiceTitle;

  // 画布相关
  double canvasScale = 1.0;
  bool isDragging = false; // 添加拖拽状态跟踪

  // 页面相关
  List<Map<String, dynamic>> pages = [];

  int currentPageIndex = -1;

  // 当前工具
  String currentTool = '';

  bool isPageThumbnailsVisible = false; // 将默认值设为false，隐藏页面缩略图
  // 图层相关
  String? selectedLayerId;
  // 元素选择相关
  List<String> selectedElementIds = [];

  Map<String, dynamic>? selectedElement;
  // 辅助功能相关
  bool gridVisible = false;
  bool snapEnabled = false; // 保留兼容性，但逐步迁移到alignmentMode
  AlignmentMode alignmentMode = AlignmentMode.none; // 新的对齐模式
  double snapThreshold = 5.0; // 参考线对齐阈值

  double gridSize = 10.0; // 🔧 更密集的网格，更适合精确设计

  // 参考线相关状态
  List<Guideline> activeGuidelines = [];
  bool isGuidelinePreviewActive = false;
  // 状态标志
  bool hasUnsavedChanges = false;
  bool isPreviewMode = false;

  bool isDisposed = false; // 标记控制器是否已销毁
  // 撤销/重做状态
  bool canUndo = false;
  bool canRedo = false;

  // Canvas scale is directly exposed as a field
  /// 获取当前页面
  Map<String, dynamic>? get currentPage {
    if (currentPageIndex >= 0 && currentPageIndex < pages.length) {
      final page = pages[currentPageIndex];

      return page;
    }

    EditPageLogger.editPageWarning('无有效的当前页面');
    return null;
  }

  /// 获取当前页面的元素列表
  List<Map<String, dynamic>> get currentPageElements {
    final page = currentPage;
    if (page != null) {
      if (page.containsKey('elements')) {
        final elements = page['elements'] as List<dynamic>;
        return List<Map<String, dynamic>>.from(elements);
      } else {
        EditPageLogger.editPageWarning('页面缺少elements键');
      }
    } else {
      EditPageLogger.editPageWarning('当前无有效页面');
    }
    return [];
  }

  /// 获取对齐阈值（优先使用snapThreshold，回退到gridSize的一半）
  double get effectiveSnapThreshold {
    if (alignmentMode == AlignmentMode.guideline) {
      return snapThreshold;
    } else if (alignmentMode == AlignmentMode.gridSnap) {
      return gridSize / 2.0;
    }
    return 0.0;
  }

  /// 检查是否有未保存的更改
  bool get hasChanges => hasUnsavedChanges;

  /// 检查是否按下了 Ctrl 或 Shift 键
  bool get isCtrlOrShiftPressed {
    final instance = HardwareKeyboard.instance;
    return instance.isControlPressed || instance.isShiftPressed;
  }

  /// 检查是否启用网格贴附
  bool get isGridSnapEnabled {
    return alignmentMode == AlignmentMode.gridSnap || snapEnabled;
  }

  /// 检查是否启用参考线对齐
  bool get isGuidelineAlignmentEnabled {
    return alignmentMode == AlignmentMode.guideline;
  }

  /// 获取当前页面的图层列表
  List<Map<String, dynamic>> get layers {
    if (currentPage != null && currentPage!.containsKey('layers')) {
      final layersList = currentPage!['layers'] as List<dynamic>;
      return List<Map<String, dynamic>>.from(layersList);
    }
    return [];
  }

  /// 根据ID查找元素
  Map<String, dynamic>? getElementById(String id) {
    if (currentPage == null) return null;

    final elements = currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);
    if (index >= 0) {
      return elements[index];
    }

    // 检查组合元素内的子元素
    for (final element in elements) {
      if (element['type'] == 'group') {
        final content = element['content'] as Map<String, dynamic>;
        final children = content['children'] as List<dynamic>;
        for (final child in children) {
          final childMap = child as Map<String, dynamic>;
          if (childMap['id'] == id) {
            return childMap;
          }
        }
      }
    }

    return null;
  }

  /// 获取指定ID的图层
  Map<String, dynamic>? getLayerById(String id) {
    final index = layers.indexWhere((l) => l['id'] == id);
    if (index >= 0) {
      return layers[index];
    }
    return null;
  }

  /// 获取选中的元素列表
  List<Map<String, dynamic>> getSelectedElements() {
    final result = <Map<String, dynamic>>[];
    if (currentPage == null) return result;

    final elements = currentPageElements;
    for (final id in selectedElementIds) {
      final element = elements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (element.isNotEmpty) {
        result.add(element);
      }
    }

    return result;
  }

  /// 检查指定图层是否锁定
  bool isLayerLocked(String layerId) {
    final layer = getLayerById(layerId);
    return layer != null && (layer['isLocked'] as bool? ?? false);
  }

  /// 检查指定图层是否可见
  bool isLayerVisible(String layerId) {
    final layer = getLayerById(layerId);
    return layer != null && (layer['isVisible'] as bool? ?? true);
  }

  /// 标记已保存
  void markSaved() {
    hasUnsavedChanges = false;
  }

  /// 标记有未保存的更改
  void markUnsaved() {
    hasUnsavedChanges = true;
  }

  /// 设置特定的对齐模式
  void setAlignmentMode(AlignmentMode mode) {
    if (alignmentMode != mode) {
      alignmentMode = mode;
      snapEnabled = mode == AlignmentMode.gridSnap; // 兼容性

      EditPageLogger.editPageInfo('设置对齐模式', data: {
        'alignmentMode': mode.name,
        'operation': 'alignment_mode_set',
      });
    }
  }

  /// 切换对齐模式
  void toggleAlignmentMode() {
    switch (alignmentMode) {
      case AlignmentMode.none:
        alignmentMode = AlignmentMode.gridSnap;
        snapEnabled = true; // 兼容性
        EditPageLogger.editPageInfo('切换到网格贴附模式', data: {
          'alignmentMode': alignmentMode.name,
          'operation': 'alignment_mode_toggle',
        });
        break;
      case AlignmentMode.gridSnap:
        alignmentMode = AlignmentMode.guideline;
        snapEnabled = false; // 兼容性
        EditPageLogger.editPageInfo('切换到参考线对齐模式', data: {
          'alignmentMode': alignmentMode.name,
          'operation': 'alignment_mode_toggle',
        });
        break;
      case AlignmentMode.guideline:
        alignmentMode = AlignmentMode.none;
        snapEnabled = false; // 兼容性
        EditPageLogger.editPageInfo('切换到无辅助模式', data: {
          'alignmentMode': alignmentMode.name,
          'operation': 'alignment_mode_toggle',
        });
        break;
    }
  }
}
