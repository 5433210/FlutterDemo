import 'package:intl/intl.dart';

/// 文件工具类
class FileUtils {
  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes == 0) ? 0 : (bytes.bitLength - 1) ~/ 10;

    if (i >= suffixes.length) {
      return '${(bytes / (1 << ((suffixes.length - 1) * 10))).toStringAsFixed(2)} ${suffixes.last}';
    }

    return '${(bytes / (1 << (i * 10))).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }
  }

  /// 格式化完整日期时间
  static String formatFullDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  /// 格式化日期
  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// 格式化时间
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  /// 获取文件扩展名
  static String getFileExtension(String filename) {
    final lastDotIndex = filename.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == filename.length - 1) {
      return '';
    }
    return filename.substring(lastDotIndex + 1).toLowerCase();
  }

  /// 获取文件名（不包含扩展名）
  static String getFileNameWithoutExtension(String filename) {
    final lastDotIndex = filename.lastIndexOf('.');
    if (lastDotIndex == -1) {
      return filename;
    }
    return filename.substring(0, lastDotIndex);
  }

  /// 验证文件名是否有效
  static bool isValidFileName(String filename) {
    if (filename.isEmpty) return false;

    // Windows不允许的字符
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(filename)) return false;

    // Windows保留名称
    final reservedNames = [
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9'
    ];

    final nameWithoutExt = getFileNameWithoutExtension(filename).toUpperCase();
    if (reservedNames.contains(nameWithoutExt)) return false;

    return true;
  }

  /// 清理文件名，移除无效字符
  static String sanitizeFileName(String filename) {
    if (filename.isEmpty) return 'unnamed';

    // 替换无效字符
    String sanitized = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    // 移除开头和结尾的空格和点
    sanitized = sanitized.trim().replaceAll(RegExp(r'^\.+|\.+$'), '');

    if (sanitized.isEmpty) return 'unnamed';

    return sanitized;
  }

  /// 生成唯一文件名
  static String generateUniqueFileName(String baseName, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanBaseName = sanitizeFileName(baseName);
    final cleanExtension =
        extension.startsWith('.') ? extension : '.$extension';

    return '${cleanBaseName}_$timestamp$cleanExtension';
  }
}
