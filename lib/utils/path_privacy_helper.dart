import 'package:path/path.dart' as path;

/// 路径隐私保护工具
///
/// 用于在数据库存储时将绝对路径转换为相对路径，保护用户隐私信息
class PathPrivacyHelper {
  /// 应用数据目录的标识符
  static const String _appDataMarker = 'storage';

  /// 将绝对路径转换为相对路径
  ///
  /// 例如：
  /// - 输入：C:\Users\username\Documents\storage\works\123\images\456\original.png
  /// - 输出：works/123/images/456/original.png
  static String toRelativePath(String absolutePath) {
    if (absolutePath.isEmpty) return absolutePath;

    // 查找存储目录标识符
    final normalizedPath = path.normalize(absolutePath);
    final segments = normalizedPath.split(path.separator);

    // 找到 storage 目录的位置
    int storageIndex = -1;
    for (int i = 0; i < segments.length; i++) {
      if (segments[i] == _appDataMarker) {
        storageIndex = i;
        break;
      }
    }

    if (storageIndex == -1) {
      // 如果找不到 storage 标识符，尝试其他标识符
      final fallbackMarkers = ['works', 'characters', 'library', 'practices'];
      for (final marker in fallbackMarkers) {
        for (int i = 0; i < segments.length; i++) {
          if (segments[i] == marker) {
            storageIndex = i;
            break;
          }
        }
        if (storageIndex != -1) break;
      }
    }

    if (storageIndex == -1) {
      // 如果仍然找不到，返回文件名
      return path.basename(absolutePath);
    }

    // 返回从 storage 目录之后的相对路径
    final relativeParts = segments.sublist(storageIndex + 1);
    return relativeParts.join('/'); // 使用正斜杠确保跨平台兼容性
  }

  /// 将相对路径转换为绝对路径
  ///
  /// 需要提供存储根目录路径
  static String toAbsolutePath(String relativePath, String storageBasePath) {
    if (relativePath.isEmpty) return relativePath;

    // 如果已经是绝对路径，直接返回
    if (path.isAbsolute(relativePath)) {
      return relativePath;
    }

    // 将相对路径中的正斜杠转换为当前平台的路径分隔符
    final normalizedRelativePath = relativePath.replaceAll('/', path.separator);

    // 组合存储根目录和相对路径
    return path.join(storageBasePath, normalizedRelativePath);
  }

  /// 检查路径是否包含隐私信息
  ///
  /// 返回 true 表示路径包含用户名或其他隐私信息
  static bool containsPrivacyInfo(String filePath) {
    if (filePath.isEmpty) return false;

    final normalizedPath = filePath.toLowerCase();

    // 检查是否包含常见的隐私路径模式
    final privacyPatterns = [
      'users',
      'user',
      'home',
      '\\c:',
      '/home/',
      'documents',
      'desktop',
      'downloads',
    ];

    for (final pattern in privacyPatterns) {
      if (normalizedPath.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  /// 批量转换路径
  static Map<String, String> batchToRelativePaths(
      Map<String, String> absolutePaths) {
    final result = <String, String>{};

    for (final entry in absolutePaths.entries) {
      result[entry.key] = toRelativePath(entry.value);
    }

    return result;
  }

  /// 验证相对路径的安全性
  ///
  /// 确保相对路径不会导致目录遍历攻击
  static bool isRelativePathSafe(String relativePath) {
    if (relativePath.isEmpty) return true;

    // 检查是否包含危险的路径遍历模式
    final dangerousPatterns = [
      '..',
      '~',
      '\\',
      '//',
    ];

    for (final pattern in dangerousPatterns) {
      if (relativePath.contains(pattern)) {
        return false;
      }
    }

    return true;
  }

  /// 清理路径中的隐私信息（用于日志记录）
  ///
  /// 将路径中的用户名等敏感信息替换为占位符
  static String sanitizePathForLogging(String filePath) {
    if (filePath.isEmpty) return filePath;

    String sanitized = filePath;

    // 替换用户名
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'[/\\]Users[/\\]([^/\\]+)[/\\]', caseSensitive: false),
      (match) =>
          '${match.group(0)!.substring(0, match.group(0)!.length - match.group(1)!.length - 1)}[USER]/',
    );

    // 替换其他敏感路径
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'[/\\]home[/\\]([^/\\]+)[/\\]', caseSensitive: false),
      (match) =>
          '${match.group(0)!.substring(0, match.group(0)!.length - match.group(1)!.length - 1)}[USER]/',
    );

    return sanitized;
  }
}

/// WorkImage 扩展，用于路径隐私保护
extension WorkImagePrivacyExtension on String {
  /// 转换为相对路径
  String toRelativePath() => PathPrivacyHelper.toRelativePath(this);

  /// 转换为绝对路径
  String toAbsolutePath(String storageBasePath) =>
      PathPrivacyHelper.toAbsolutePath(this, storageBasePath);

  /// 检查是否包含隐私信息
  bool get containsPrivacyInfo => PathPrivacyHelper.containsPrivacyInfo(this);

  /// 清理用于日志记录
  String get sanitizedForLogging =>
      PathPrivacyHelper.sanitizePathForLogging(this);
}
