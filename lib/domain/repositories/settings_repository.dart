/// 设置仓储接口
abstract class SettingsRepository {
  /// 删除设置值
  Future<void> deleteValue(String key);

  /// 获取设置值
  Future<String?> getValue(String key);

  /// 批量获取设置值
  Future<Map<String, String>> getValues(List<String> keys);

  /// 保存设置值
  Future<void> setValue(String key, String value);

  /// 批量保存设置值
  Future<void> setValues(Map<String, String> values);
}
