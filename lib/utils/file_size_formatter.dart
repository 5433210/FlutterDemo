import 'dart:math' as math;

/// 文件大小格式化工具
class FileSizeFormatter {
  /// 格式化文件大小
  ///
  /// [bytes] 字节数
  /// [decimals] 小数位数
  static String format(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = (math.log(bytes) / math.log(1024)).floor();
    i = i < suffixes.length ? i : suffixes.length - 1;

    return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// 以字节为单位格式化
  static String formatBytes(int bytes) => '$bytes B';

  /// 以GB为单位格式化
  static String formatGB(int bytes) =>
      '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';

  /// 以KB为单位格式化
  static String formatKB(int bytes) =>
      '${(bytes / 1024).toStringAsFixed(2)} KB';

  /// 以MB为单位格式化
  static String formatMB(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
