import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../infrastructure/persistence/database_interface.dart';

/// 字帖服务类，负责处理字帖的存储和读取
class PracticeService {
  final DatabaseInterface _database;
  final Uuid _uuid = const Uuid();

  /// 构造函数
  PracticeService(this._database);

  /// 删除字帖
  Future<void> deletePractice(String id) async {
    await _database.delete('practices', id);
  }

  /// 获取所有字帖
  Future<List<Map<String, dynamic>>> getAllPractices() async {
    return _database.getAll('practices');
  }

  /// 检查标题是否已存在
  Future<bool> isTitleExists(String title) async {
    final results = await query('title', '=', title);
    return results.isNotEmpty;
  }

  /// 加载字帖
  Future<Map<String, dynamic>?> loadPractice(String id) async {
    final practice = await _database.get('practices', id);
    if (practice == null) return null;

    // 解析页面数据
    final pagesJson = practice['pages'] as String;
    final pages = List<Map<String, dynamic>>.from(
      jsonDecode(pagesJson) as List<dynamic>,
    );

    // 返回包含解析后页面数据的字帖信息
    return {
      'id': practice['id'],
      'title': practice['title'],
      'pages': pages,
      'tags': practice['tags'],
      'createTime': practice['createTime'],
      'updateTime': practice['updateTime'],
    };
  }

  /// 查询字帖记录
  Future<List<Map<String, dynamic>>> query(
    String field,
    String operator,
    dynamic value,
  ) async {
    final filter = {
      'conditions': [
        {
          'field': field,
          'operator': operator,
          'value': value,
        },
      ],
    };
    return _database.query('practices', filter);
  }

  /// 保存字帖
  ///
  /// 参数:
  /// - id: 字帖ID，为null时创建新字帖
  /// - title: 字帖标题
  /// - pages: 字帖页面数据
  ///
  /// 返回包含id的Map
  Future<Map<String, dynamic>> savePractice({
    String? id,
    required String title,
    required List<Map<String, dynamic>> pages,
  }) async {
    final now = DateTime.now().toIso8601String();
    final practiceId = id ?? _uuid.v4();

    // 将页面数据转换为JSON字符串
    final pagesJson = jsonEncode(pages);

    // 准备要保存的数据
    final data = {
      'id': practiceId,
      'title': title,
      'pages': pagesJson,
      'updateTime': now,
    };

    // 如果是新建的字帖，添加创建时间
    if (id == null) {
      data['createTime'] = now;
    } else {
      // 对于现有记录，需要获取原有的createTime
      final existingPractice = await _database.get('practices', id);
      if (existingPractice != null && existingPractice['createTime'] != null) {
        data['createTime'] = existingPractice['createTime'];
      } else {
        // 如果无法获取原有createTime，使用当前时间作为fallback
        data['createTime'] = now;
      }
    }

    // 保存到数据库
    await _database.set('practices', practiceId, data);

    // 返回保存结果
    return {
      'id': practiceId,
      'title': title,
      'createTime': data['createTime'],
      'updateTime': now,
    };
  }
}
