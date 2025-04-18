import 'package:flutter/material.dart';
import '../../../domain/models/practice/practice_page.dart';

/// 页面操作类
/// 包含页面操作相关的方法
class PageOperations {
  /// 创建新页面
  static Map<String, dynamic> createPage() {
    final pageId = 'page_${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'id': pageId,
      'backgroundColor': '#FFFFFF',
      'elements': [],
    };
  }

  /// 初始化默认页面
  static List<Map<String, dynamic>> createDefaultPages() {
    return [
      {
        'id': 'page_1',
        'backgroundColor': '#FFFFFF',
        'elements': [],
      }
    ];
  }

  /// 添加页面
  static void addPage(List<Map<String, dynamic>> pages) {
    pages.add(createPage());
  }

  /// 删除页面
  static void deletePage(List<Map<String, dynamic>> pages, int index) {
    if (index >= 0 && index < pages.length) {
      pages.removeAt(index);
    }
  }

  /// 获取页面背景颜色
  static Color getPageBackgroundColor(Map<String, dynamic> page) {
    final backgroundColor = page['backgroundColor'] as String? ?? '#FFFFFF';
    return Color(int.parse(backgroundColor.substring(1), radix: 16) + 0xFF000000);
  }

  /// 将Map转换为PracticePage
  static PracticePage mapToPracticePage(Map<String, dynamic> map) {
    try {
      // 创建临时的基本PracticePage对象
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

  /// 更新页面属性
  static void updatePageProperties(
    List<Map<String, dynamic>> pages,
    int pageIndex,
    PracticePage updatedPage,
  ) {
    if (pageIndex >= 0 && pageIndex < pages.length) {
      // 提取页面属性并更新
      final updatedMap = {
        'id': updatedPage.id,
        'name': updatedPage.name,
        'index': updatedPage.index,
        'width': updatedPage.width,
        'height': updatedPage.height,
        'backgroundType': updatedPage.backgroundType,
        'backgroundImage': updatedPage.backgroundImage,
        'backgroundColor': updatedPage.backgroundColor,
        'backgroundTexture': updatedPage.backgroundTexture,
        'backgroundOpacity': updatedPage.backgroundOpacity,
      };

      pages[pageIndex] = {
        ...pages[pageIndex],
        ...updatedMap,
      };
    }
  }
}
