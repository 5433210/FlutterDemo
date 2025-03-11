/// UTC日期时间处理工具类
class DateTimeHelper {
  /// 格式化日期范围查询条件
  static Map<String, String> formatDateRange(DateTime start, DateTime end) {
    return {
      'start': toStorageFormat(start)!,
      'end': toStorageFormat(end)!,
    };
  }

  /// 从存储格式解析
  static DateTime? fromStorageFormat(String? utcString) {
    if (utcString == null) return null;
    return DateTime.parse(utcString).toLocal();
  }

  /// 获取当前UTC时间字符串
  static String getCurrentUtc() {
    return DateTime.now().toUtc().toIso8601String();
  }

  /// 检查是否为有效的UTC ISO8601字符串
  static bool isValidUtcString(String? value) {
    if (value == null) return false;
    try {
      DateTime.parse(value);
      return value.endsWith('Z');
    } catch (e) {
      return false;
    }
  }

  /// 时间戳转UTC字符串
  static String? timestampToUtc(int? timestamp) {
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp)
        .toUtc()
        .toIso8601String();
  }

  /// 转换为存储格式(UTC ISO8601)
  static String? toStorageFormat(DateTime? dateTime) {
    if (dateTime == null) return null;
    return dateTime.toUtc().toIso8601String();
  }

  /// UTC字符串转时间戳
  static int? utcToTimestamp(String? utcString) {
    if (utcString == null) return null;
    return DateTime.parse(utcString).millisecondsSinceEpoch;
  }
}
