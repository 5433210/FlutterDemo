import 'package:flutter/material.dart';

/// 集字管理器
class CollectionManager {
  /// 获取集字内容
  Future<List<Map<String, dynamic>>> getCollectionItems(
    String query, {
    String? style,
    String? tool,
    int limit = 20,
    int offset = 0,
  }) async {
    // 模拟从服务器获取集字内容
    // 实际应用中，这里应该调用API获取数据
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 模拟数据
    final items = <Map<String, dynamic>>[];
    
    // 生成一些示例数据
    final characters = query.split('');
    for (final char in characters) {
      // 为每个字符生成多种风格
      for (int i = 0; i < 5; i++) {
        items.add({
          'id': '${char}_style_$i',
          'character': char,
          'style': _getRandomStyle(i),
          'tool': _getRandomTool(i),
          'author': _getRandomAuthor(i),
          'dynasty': _getRandomDynasty(i),
          'imageUrl': 'assets/images/collections/${char}_$i.png',
          'thumbnailUrl': 'assets/images/collections/thumbnails/${char}_$i.png',
        });
      }
    }
    
    // 应用筛选
    var filteredItems = items;
    
    if (style != null) {
      filteredItems = filteredItems.where((item) => item['style'] == style).toList();
    }
    
    if (tool != null) {
      filteredItems = filteredItems.where((item) => item['tool'] == tool).toList();
    }
    
    // 应用分页
    final start = offset;
    final end = offset + limit;
    
    if (start >= filteredItems.length) {
      return [];
    }
    
    return filteredItems.sublist(
      start,
      end > filteredItems.length ? filteredItems.length : end,
    );
  }
  
  /// 获取集字风格列表
  List<String> getCollectionStyles() {
    return [
      '楷书',
      '行书',
      '草书',
      '隶书',
      '篆书',
    ];
  }
  
  /// 获取集字工具列表
  List<String> getCollectionTools() {
    return [
      '毛笔',
      '硬笔',
      '钢笔',
      '铅笔',
      '软笔',
    ];
  }
  
  /// 获取随机风格
  String _getRandomStyle(int index) {
    final styles = getCollectionStyles();
    return styles[index % styles.length];
  }
  
  /// 获取随机工具
  String _getRandomTool(int index) {
    final tools = getCollectionTools();
    return tools[index % tools.length];
  }
  
  /// 获取随机作者
  String _getRandomAuthor(int index) {
    final authors = [
      '王羲之',
      '颜真卿',
      '柳公权',
      '欧阳询',
      '赵孟頫',
    ];
    return authors[index % authors.length];
  }
  
  /// 获取随机朝代
  String _getRandomDynasty(int index) {
    final dynasties = [
      '晋',
      '唐',
      '宋',
      '元',
      '明',
    ];
    return dynasties[index % dynasties.length];
  }
}
