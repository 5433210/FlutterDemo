/// 字帖仓库接口
abstract class PracticeRepository {
  /// 创建新的字帖
  Future<String> createPractice(Map<String, dynamic> data);

  /// 删除字帖
  Future<bool> deletePractice(String id);

  /// 获取单个字帖
  Future<Map<String, dynamic>?> getPractice(String id);

  /// 获取多个字帖
  Future<List<Map<String, dynamic>>> getPractices({
    String? title,
    int? limit,
    int? offset,
  });

  /// 更新字帖
  Future<bool> updatePractice(String id, Map<String, dynamic> data);
}
