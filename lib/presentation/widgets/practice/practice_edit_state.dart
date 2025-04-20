/// 字帖编辑状态类
class PracticeEditState {
  // 页面相关
  List<Map<String, dynamic>> pages = [];
  int currentPageIndex = -1;
  bool isPageThumbnailsVisible = true;

  // 图层相关
  String? selectedLayerId;

  // 元素选择相关
  List<String> selectedElementIds = [];
  Map<String, dynamic>? selectedElement;

  // 辅助功能相关
  bool gridVisible = false;
  bool snapEnabled = false;
  double gridSize = 20.0;

  // 状态标志
  bool hasUnsavedChanges = false;

  // 撤销/重做状态
  bool canUndo = false;
  bool canRedo = false;

  /// 获取当前页面
  Map<String, dynamic>? get currentPage {
    if (currentPageIndex >= 0 && currentPageIndex < pages.length) {
      return pages[currentPageIndex];
    }
    return null;
  }

  /// 获取当前页面的元素列表
  List<Map<String, dynamic>> get currentPageElements {
    if (currentPage != null) {
      final elements = currentPage!['elements'] as List<dynamic>;
      return List<Map<String, dynamic>>.from(elements);
    }
    return [];
  }

  /// 检查是否有未保存的更改
  bool get hasChanges => hasUnsavedChanges;

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
}
