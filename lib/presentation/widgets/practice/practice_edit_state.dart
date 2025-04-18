import 'package:flutter/material.dart';
import '../../../domain/models/practice/practice_element.dart';
import '../../../domain/models/practice/practice_page.dart';

/// 编辑状态数据类
class PracticeEditState {
  // 基本状态
  bool hasUnsavedChanges;
  List<Map<String, dynamic>> layers;
  Map<String, dynamic>? selectedElement;
  bool isPageThumbnailsVisible;
  List<Map<String, dynamic>> pages;
  int currentPageIndex;
  double currentZoom;

  // 工具状态
  bool gridVisible;
  bool snapEnabled;
  
  // 选中元素状态
  List<String> selectedElementIds;

  // 构造函数
  PracticeEditState({
    this.hasUnsavedChanges = false,
    List<Map<String, dynamic>>? layers,
    this.selectedElement,
    this.isPageThumbnailsVisible = true,
    List<Map<String, dynamic>>? pages,
    this.currentPageIndex = 0,
    this.currentZoom = 1.0,
    this.gridVisible = false,
    this.snapEnabled = true,
    List<String>? selectedElementIds,
  }) : 
    layers = layers ?? [],
    pages = pages ?? [],
    selectedElementIds = selectedElementIds ?? [];

  // 获取当前页面
  Map<String, dynamic>? get currentPage {
    return currentPageIndex < pages.length ? pages[currentPageIndex] : null;
  }

  // 获取当前页面的元素列表
  List<Map<String, dynamic>> get currentPageElements {
    if (currentPage == null) return [];
    
    final elements = currentPage!['elements'] as List<dynamic>? ?? [];
    return elements.map((e) => e as Map<String, dynamic>).toList();
  }

  // 创建副本
  PracticeEditState copy() {
    return PracticeEditState(
      hasUnsavedChanges: hasUnsavedChanges,
      layers: List.from(layers),
      selectedElement: selectedElement != null 
          ? Map<String, dynamic>.from(selectedElement!) 
          : null,
      isPageThumbnailsVisible: isPageThumbnailsVisible,
      pages: List.from(pages),
      currentPageIndex: currentPageIndex,
      currentZoom: currentZoom,
      gridVisible: gridVisible,
      snapEnabled: snapEnabled,
      selectedElementIds: List.from(selectedElementIds),
    );
  }

  // 将 PracticeElement 转换为 Map
  static Map<String, dynamic>? practiceElementToMap(PracticeElement? element) {
    if (element == null) return null;
    return element.toMap();
  }

  // 将 Map 转换为 PracticeElement
  static PracticeElement? mapToPracticeElement(Map<String, dynamic>? map) {
    if (map == null) return null;
    
    try {
      return PracticeElement.fromMap(map);
    } catch (e) {
      debugPrint('Error converting element: $e');
      return null;
    }
  }

  // 将 PracticePage 转换为 Map
  static Map<String, dynamic> practicePageToMap(PracticePage page) {
    return {
      'id': page.id,
      'name': page.name,
      'index': page.index,
      'width': page.width,
      'height': page.height,
      'backgroundType': page.backgroundType,
      'backgroundImage': page.backgroundImage,
      'backgroundColor': page.backgroundColor,
      'backgroundTexture': page.backgroundTexture,
      'backgroundOpacity': page.backgroundOpacity,
    };
  }

  // 将 Map 转换为 PracticePage
  static PracticePage mapToPracticePage(Map<String, dynamic> map) {
    try {
      return PracticePage(
        id: map['id'] as String? ?? 'default',
        name: map['name'] as String? ?? '',
        index: (map['index'] as int?) ?? 0,
        width: (map['width'] as num?)?.toDouble() ?? 210.0,
        height: (map['height'] as num?)?.toDouble() ?? 297.0,
        backgroundType: map['backgroundType'] as String? ?? 'color',
        backgroundImage: map['backgroundImage'] as String?,
        backgroundColor: map['backgroundColor'] as String? ?? '#FFFFFF',
        backgroundTexture: map['backgroundTexture'] as String?,
        backgroundOpacity: (map['backgroundOpacity'] as num?)?.toDouble() ?? 1.0,
      );
    } catch (e) {
      debugPrint('Error converting page: $e');
      return PracticePage.defaultPage();
    }
  }
}
