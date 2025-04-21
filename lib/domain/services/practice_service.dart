import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../infrastructure/persistence/database_interface.dart';

/// 字帖服务类 - 处理字帖的保存和加载操作
class PracticeService {
  // 字帖表名
  static const String _tableName = 'practices';
  final DatabaseInterface _database;

  final Uuid _uuid = const Uuid();

  /// 构造函数
  PracticeService(this._database);

  /// 删除字帖
  Future<void> deletePractice(String id) async {
    await _database.delete(_tableName, id);
  }

  /// 获取所有字帖列表（不包含pages详情）
  Future<List<Map<String, dynamic>>> getAllPractices() async {
    final practices = await _database.getAll(_tableName);
    return practices;
  }

  /// 检查标题是否存在
  Future<bool> isTitleExists(String title) async {
    final results = await _database.query(
      _tableName,
      {
        'conditions': [
          {
            'field': 'title',
            'operator': '=',
            'value': title,
          }
        ],
      },
    );

    return results.isNotEmpty;
  }

  /// 根据ID加载字帖
  Future<Map<String, dynamic>?> loadPractice(String id) async {
    final practice = await _database.get(_tableName, id);
    if (practice == null) return null;

    // 解析JSON字符串为页面列表
    if (practice['pages'] != null) {
      try {
        final pagesJson = practice['pages'] as String;
        final pages = (jsonDecode(pagesJson) as List)
            .map((page) => Map<String, dynamic>.from(page))
            .toList();
        practice['pages'] = pages;
      } catch (e) {
        // 处理JSON解析错误
        print('解析字帖页面数据失败: $e');
        practice['pages'] = <Map<String, dynamic>>[];
      }
    } else {
      practice['pages'] = <Map<String, dynamic>>[];
    }

    return practice;
  }

  /// 保存字帖
  /// 如果id为null，则创建新的字帖
  /// 如果id存在，则更新已有字帖
  Future<Map<String, dynamic>> savePractice({
    String? id,
    required String title,
    required List<Map<String, dynamic>> pages,
    List<String>? tags,
  }) async {
    final now = DateTime.now().toIso8601String();
    final practiceId = id ?? _uuid.v4();

    // 将页面数据转换为JSON字符串
    final pagesJson = jsonEncode(pages);

    final practice = {
      'title': title,
      'pages': pagesJson,
      'tags': tags?.join(','),
      'updateTime': now,
    };

    if (id == null) {
      // 新建字帖
      practice['createTime'] = now;
      await _database.set(_tableName, practiceId, practice);
    } else {
      // 更新现有字帖
      await _database.save(_tableName, practiceId, practice);
    }

    return {
      'id': practiceId,
      ...practice,
    };
  }
}
