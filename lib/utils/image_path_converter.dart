import 'dart:io';

import 'package:path/path.dart' as path;

import '../application/services/unified_path_config_service.dart';
import '../infrastructure/logging/logger.dart';

/// 图像路径转换工具
/// 负责绝对路径与相对路径之间的转换，优化数据库存储
class ImagePathConverter {
  static const String _tag = 'ImagePathConverter';
  
  /// 将绝对路径转换为相对路径（用于保存到数据库）
  /// 
  /// 转换规则：
  /// - file://C:/Users/.../charasgem/storage/library/xxx/original.png
  /// - 转换为: library/xxx/original.png
  static String toRelativePath(String absolutePath) {
    try {
      // 如果已经是相对路径，直接返回
      if (isRelativePath(absolutePath)) {
        AppLogger.debug('路径已是相对路径，直接返回', 
            tag: _tag, 
            data: {'path': absolutePath});
        return absolutePath;
      }
      
      // 移除file://前缀
      String cleanPath = absolutePath;
      if (cleanPath.startsWith('file://')) {
        cleanPath = cleanPath.substring(7);
      }
      
      // 标准化路径分隔符
      cleanPath = cleanPath.replaceAll('\\', '/');
      
      // 查找storage目录的位置
      final storageIndex = cleanPath.indexOf('/storage/');
      if (storageIndex == -1) {
        AppLogger.warning('无法找到storage目录，保持原路径', 
            tag: _tag, 
            data: {'path': absolutePath});
        return absolutePath;
      }
      
      // 提取storage之后的相对路径
      final relativePath = cleanPath.substring(storageIndex + 9); // 9 = '/storage/'.length
      
      AppLogger.debug('绝对路径转换为相对路径', 
          tag: _tag, 
          data: {
            'original': absolutePath,
            'relative': relativePath,
          });
      
      return relativePath;
    } catch (e) {
      AppLogger.error('绝对路径转换失败，保持原路径', 
          error: e, 
          tag: _tag, 
          data: {'path': absolutePath});
      return absolutePath;
    }
  }
  
  /// 将相对路径转换为绝对路径（用于从数据库加载）
  /// 
  /// 转换规则：
  /// - library/xxx/original.png 
  /// - 转换为: file://C:/Users/.../charasgem/storage/library/xxx/original.png
  static Future<String> toAbsolutePath(String relativePath) async {
    try {
      // 如果已经是绝对路径，直接返回
      if (relativePath.startsWith('file://') || 
          relativePath.startsWith('/') ||
          (relativePath.length > 1 && relativePath[1] == ':')) {
        return relativePath;
      }
      
      // 获取当前数据路径
      final config = await UnifiedPathConfigService.readConfig();
      final dataPath = await config.dataPath.getActualDataPath();
      
      // 构建完整的存储路径
      final storagePath = path.join(dataPath, 'storage', relativePath);
      
      // 标准化路径分隔符，并确保正确的文件URI格式
      final normalizedPath = storagePath.replaceAll('\\', '/');
      
      // 根据平台构建正确的文件URI
      String fileUri;
      if (normalizedPath.startsWith('/')) {
        // Unix-style路径
        fileUri = 'file://$normalizedPath';
      } else {
        // Windows路径，需要额外的斜杠
        fileUri = 'file:///$normalizedPath';
      }
      
      AppLogger.debug('相对路径转换为绝对路径', 
          tag: _tag, 
          data: {
            'relative': relativePath,
            'dataPath': dataPath,
            'absolute': fileUri,
          });
      
      return fileUri;
    } catch (e) {
      AppLogger.error('相对路径转换失败，保持原路径', 
          error: e, 
          tag: _tag, 
          data: {'path': relativePath});
      return relativePath;
    }
  }
  
  /// 检查路径是否为相对路径
  static bool isRelativePath(String imagePath) {
    return !imagePath.startsWith('file://') && 
           !imagePath.startsWith('/') &&
           !(imagePath.length > 1 && imagePath[1] == ':');
  }
  
  /// 批量转换路径（用于数据迁移）
  static Future<Map<String, String>> batchConvertToRelative(
      List<String> absolutePaths) async {
    final Map<String, String> conversions = {};
    
    for (final absolutePath in absolutePaths) {
      conversions[absolutePath] = toRelativePath(absolutePath);
    }
    
    AppLogger.info('批量转换完成', 
        tag: _tag, 
        data: {
          'totalPaths': absolutePaths.length,
          'conversions': conversions.length,
        });
    
    return conversions;
  }
  
  /// 批量转换路径为绝对路径
  static Future<Map<String, String>> batchConvertToAbsolute(
      List<String> relativePaths) async {
    final Map<String, String> conversions = {};
    
    for (final relativePath in relativePaths) {
      conversions[relativePath] = await toAbsolutePath(relativePath);
    }
    
    AppLogger.info('批量转换完成', 
        tag: _tag, 
        data: {
          'totalPaths': relativePaths.length,
          'conversions': conversions.length,
        });
    
    return conversions;
  }
  
  /// 验证转换后的路径是否有效
  static Future<bool> validatePath(String imagePath) async {
    try {
      String pathToCheck = imagePath;
      
      // 如果是相对路径，先转换为绝对路径
      if (isRelativePath(imagePath)) {
        pathToCheck = await toAbsolutePath(imagePath);
      }
      
      // 移除file://前缀进行文件检查
      if (pathToCheck.startsWith('file://')) {
        pathToCheck = pathToCheck.substring(7);
      }
      
      final file = File(pathToCheck);
      final exists = await file.exists();
      
      AppLogger.debug('路径验证结果', 
          tag: _tag, 
          data: {
            'originalPath': imagePath,
            'checkPath': pathToCheck,
            'exists': exists,
          });
      
      return exists;
    } catch (e) {
      AppLogger.error('路径验证失败', 
          error: e, 
          tag: _tag, 
          data: {'path': imagePath});
      return false;
    }
  }
  
  /// 迁移数据库中的绝对路径到相对路径
  /// 
  /// 扫描数据库中的Practice记录，将其中的绝对图像路径转换为相对路径
  static Future<PathMigrationResult> migrateAbsolutePathsInDatabase({
    void Function(int processed, int total)? onProgress,
  }) async {
    try {
      AppLogger.info('开始迁移数据库中的图像路径', tag: _tag);
      
      // 这里需要实际的数据库操作
      // 由于我们不能直接访问数据库层，这个方法需要在适当的服务中调用
      // 这里提供一个框架，实际实现需要在PracticeRepositoryImpl中
      
      AppLogger.warning('路径迁移需要在Repository层实现', tag: _tag, data: {
        'reason': '需要访问数据库进行批量更新',
        'suggestedLocation': 'PracticeRepositoryImpl',
      });
      
      return PathMigrationResult(
        success: false,
        processedCount: 0,
        totalCount: 0,
        errorMessage: '需要在Repository层实现具体的数据库迁移逻辑',
      );
      
    } catch (e) {
      AppLogger.error('路径迁移失败', error: e, tag: _tag);
      return PathMigrationResult(
        success: false,
        processedCount: 0,
        totalCount: 0,
        errorMessage: e.toString(),
      );
    }
  }
}

/// 路径迁移结果
class PathMigrationResult {
  final bool success;
  final int processedCount;
  final int totalCount;
  final String? errorMessage;
  final List<String> failedPaths;

  PathMigrationResult({
    required this.success,
    required this.processedCount,
    required this.totalCount,
    this.errorMessage,
    this.failedPaths = const [],
  });

  /// 创建成功结果
  factory PathMigrationResult.success({
    required int processedCount,
    required int totalCount,
    List<String> failedPaths = const [],
  }) =>
      PathMigrationResult(
        success: true,
        processedCount: processedCount,
        totalCount: totalCount,
        failedPaths: failedPaths,
      );

  /// 创建失败结果
  factory PathMigrationResult.failure({
    required String errorMessage,
    int processedCount = 0,
    int totalCount = 0,
  }) =>
      PathMigrationResult(
        success: false,
        processedCount: processedCount,
        totalCount: totalCount,
        errorMessage: errorMessage,
      );

  /// 迁移是否完全成功
  bool get isComplete => success && failedPaths.isEmpty;

  /// 成功率
  double get successRate {
    if (totalCount == 0) return 0.0;
    return (processedCount - failedPaths.length) / totalCount;
  }
}