import 'package:uuid/uuid.dart';

import '../../infrastructure/persistence/database_interface.dart';
import '../../utils/date_utils.dart';

/// 字帖服务类，用于处理字帖的存储和检索
class PracticeService {
  static const String tableName = 'practices';
  final DatabaseInterface _database;

  PracticeService(this._database);

  /// 删除字帖
  Future<void> deletePractice(String id) async {
    await _database.delete(tableName, id);
  }

  /// 获取所有字帖
  Future<List<Map<String, dynamic>>> getAllPractices() async {
    return _database.getAll(tableName);
  }

  /// 根据ID获取字帖
  Future<Map<String, dynamic>?> getPractice(String id) async {
    return _database.get(tableName, id);
  }

  /// 根据标题获取字帖
  Future<Map<String, dynamic>?> getPracticeByTitle(String title) async {
    final results = await _database.query(
      tableName,
      {
        'conditions': [
          {
            'field': 'title',
            'operator': '=',
            'value': title,
          }
        ],
        'limit': 1,
      },
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// 保存字帖
  /// 如果id为null，则创建新的字帖
  /// 如果id不为null，则更新已有字帖
  Future<String> savePractice({
    String? id,
    required String title,
    required List<Map<String, dynamic>> pages,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final timestamp = DateUtils.formatDateTime(now);
    final practiceId = id ?? const Uuid().v4();

    final data = {
      'title': title,
      'pages': pages,
      'tags': tags,
      'updateTime': timestamp,
    };

    if (id == null) {
      // 新建字帖，添加创建时间
      data['createTime'] = timestamp;
    }

    // 将pages转换为JSON字符串
    data['pages'] = pages;

    await _database.set(tableName, practiceId, data);
    return practiceId;
  }

  /// 检查指定标题的字帖是否已存在
  Future<bool> titleExists(String title) async {
    final result = await _database.count(
      tableName,
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
    return result > 0;
  }
}
