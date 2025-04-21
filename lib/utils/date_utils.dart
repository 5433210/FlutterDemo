import 'package:intl/intl.dart';

/// 日期工具类
class DateUtils {
  /// 格式化日期时间为字符串，格式：yyyy-MM-dd HH:mm:ss
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  /// 格式化日期为友好的显示形式
  static String formatFriendlyDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        } else {
          return '${difference.inMinutes}分钟前';
        }
      } else {
        return '${difference.inHours}小时前';
      }
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return formatDateTime(dateTime);
    }
  }

  /// 将字符串解析为日期时间
  static DateTime? parseDateTime(String dateTimeStr) {
    try {
      final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      return formatter.parse(dateTimeStr);
    } catch (e) {
      return null;
    }
  }
}
