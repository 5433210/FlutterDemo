import '../models/import_export/import_data_model.dart';
import '../models/import_export/export_data_model.dart';
import '../models/import_export/import_export_exceptions.dart';

/// 导入进度回调
typedef ImportProgressCallback = void Function(
  double progress,
  String currentOperation,
  Map<String, dynamic>? details,
);

/// 冲突解决回调
typedef ConflictResolutionCallback = Future<ConflictResolution> Function(
  ImportConflictInfo conflict,
);

/// 导入服务抽象接口
abstract class ImportService {
  /// 验证导入文件
  /// 
  /// [filePath] 导入文件路径
  /// [options] 导入选项
  /// 
  /// 返回验证结果
  Future<ImportValidationResult> validateImportFile(
    String filePath,
    ImportOptions options,
  );

  /// 解析导入数据
  /// 
  /// [filePath] 导入文件路径
  /// [options] 导入选项
  /// 
  /// 返回解析的导入数据模型
  Future<ImportDataModel> parseImportData(
    String filePath,
    ImportOptions options,
  );

  /// 检查数据冲突
  /// 
  /// [importData] 导入数据模型
  /// 
  /// 返回冲突信息列表
  Future<List<ImportConflictInfo>> checkConflicts(ImportDataModel importData);

  /// 执行导入操作
  /// 
  /// [importData] 导入数据模型
  /// [sourceFilePath] 源文件路径（用于提取图片文件）
  /// [progressCallback] 进度回调
  /// [conflictCallback] 冲突解决回调
  /// 
  /// 返回导入结果
  Future<ImportResult> performImport(
    ImportDataModel importData, {
    String? sourceFilePath,
    ImportProgressCallback? progressCallback,
    ConflictResolutionCallback? conflictCallback,
  });

  /// 回滚导入操作
  /// 
  /// [transactionId] 事务ID
  /// [progressCallback] 进度回调
  /// 
  /// 返回回滚结果
  Future<RollbackResult> rollbackImport(
    String transactionId, {
    ImportProgressCallback? progressCallback,
  });

  /// 预览导入结果
  /// 
  /// [importData] 导入数据模型
  /// 
  /// 返回预览信息
  Future<ImportPreview> previewImport(ImportDataModel importData);

  /// 估算导入时间
  /// 
  /// [importData] 导入数据模型
  /// 
  /// 返回预估时间（秒）
  Future<int> estimateImportTime(ImportDataModel importData);

  /// 检查导入要求
  /// 
  /// [importData] 导入数据模型
  /// 
  /// 返回要求检查结果
  Future<ImportRequirements> checkImportRequirements(ImportDataModel importData);

  /// 取消正在进行的导入操作
  /// 
  /// [operationId] 操作ID（可选，用于识别特定操作）
  Future<void> cancelImport([String? operationId]);

  /// 获取导入历史记录
  /// 
  /// [limit] 限制数量
  /// [offset] 偏移量
  /// 
  /// 返回导入历史列表
  Future<List<ImportHistoryRecord>> getImportHistory({
    int limit = 50,
    int offset = 0,
  });

  /// 清理导入临时文件
  /// 
  /// [olderThanDays] 清理多少天前的文件
  Future<void> cleanupTempFiles([int olderThanDays = 7]);

  /// 获取支持的导入格式
  /// 
  /// 返回支持的格式列表
  List<String> getSupportedFormats();

  /// 获取默认导入选项
  /// 
  /// 返回默认选项配置
  ImportOptions getDefaultOptions();
}

/// 导入结果
class ImportResult {
  /// 是否成功
  final bool success;
  
  /// 事务ID
  final String transactionId;
  
  /// 导入的作品数量
  final int importedWorks;
  
  /// 导入的集字数量
  final int importedCharacters;
  
  /// 导入的图片数量
  final int importedImages;
  
  /// 跳过的项目数量
  final int skippedItems;
  
  /// 错误信息
  final List<String> errors;
  
  /// 警告信息
  final List<String> warnings;
  
  /// 导入耗时（毫秒）
  final int duration;
  
  /// 导入详情
  final Map<String, dynamic> details;

  const ImportResult({
    required this.success,
    required this.transactionId,
    this.importedWorks = 0,
    this.importedCharacters = 0,
    this.importedImages = 0,
    this.skippedItems = 0,
    this.errors = const [],
    this.warnings = const [],
    this.duration = 0,
    this.details = const {},
  });
}

/// 回滚结果
class RollbackResult {
  /// 是否成功
  final bool success;
  
  /// 回滚的作品数量
  final int rolledBackWorks;
  
  /// 回滚的集字数量
  final int rolledBackCharacters;
  
  /// 回滚的图片数量
  final int rolledBackImages;
  
  /// 错误信息
  final List<String> errors;
  
  /// 回滚耗时（毫秒）
  final int duration;

  const RollbackResult({
    required this.success,
    this.rolledBackWorks = 0,
    this.rolledBackCharacters = 0,
    this.rolledBackImages = 0,
    this.errors = const [],
    this.duration = 0,
  });
}

/// 导入预览
class ImportPreview {
  /// 将要导入的作品列表
  final List<ImportPreviewItem> works;
  
  /// 将要导入的集字列表
  final List<ImportPreviewItem> characters;
  
  /// 将要导入的图片列表
  final List<ImportPreviewItem> images;
  
  /// 冲突项目列表
  final List<ImportConflictInfo> conflicts;
  
  /// 总计信息
  final ImportPreviewSummary summary;

  const ImportPreview({
    this.works = const [],
    this.characters = const [],
    this.images = const [],
    this.conflicts = const [],
    required this.summary,
  });
}

/// 导入预览项目
class ImportPreviewItem {
  /// 项目ID
  final String id;
  
  /// 项目标题/名称
  final String title;
  
  /// 项目类型
  final EntityType type;
  
  /// 操作类型
  final ImportAction action;
  
  /// 项目大小（字节）
  final int size;
  
  /// 预览信息
  final Map<String, dynamic> preview;

  const ImportPreviewItem({
    required this.id,
    required this.title,
    required this.type,
    required this.action,
    this.size = 0,
    this.preview = const {},
  });
}

/// 导入预览汇总
class ImportPreviewSummary {
  /// 总项目数
  final int totalItems;
  
  /// 新增项目数
  final int newItems;
  
  /// 更新项目数
  final int updateItems;
  
  /// 跳过项目数
  final int skipItems;
  
  /// 冲突项目数
  final int conflictItems;
  
  /// 预估导入时间（秒）
  final int estimatedTime;
  
  /// 预估存储空间（字节）
  final int estimatedStorage;

  const ImportPreviewSummary({
    this.totalItems = 0,
    this.newItems = 0,
    this.updateItems = 0,
    this.skipItems = 0,
    this.conflictItems = 0,
    this.estimatedTime = 0,
    this.estimatedStorage = 0,
  });
}

/// 导入要求检查结果
class ImportRequirements {
  /// 是否满足要求
  final bool satisfied;
  
  /// 最小应用版本要求
  final String? minAppVersion;
  
  /// 需要的存储空间（字节）
  final int requiredStorage;
  
  /// 可用存储空间（字节）
  final int availableStorage;
  
  /// 需要的权限列表
  final List<String> requiredPermissions;
  
  /// 缺失的权限列表
  final List<String> missingPermissions;
  
  /// 要求说明
  final List<String> requirements;
  
  /// 不满足的要求
  final List<String> unmetRequirements;

  const ImportRequirements({
    required this.satisfied,
    this.minAppVersion,
    this.requiredStorage = 0,
    this.availableStorage = 0,
    this.requiredPermissions = const [],
    this.missingPermissions = const [],
    this.requirements = const [],
    this.unmetRequirements = const [],
  });
}

/// 导入历史记录
class ImportHistoryRecord {
  /// 记录ID
  final String id;
  
  /// 导入时间
  final DateTime importTime;
  
  /// 导入文件名
  final String fileName;
  
  /// 导入文件大小
  final int fileSize;
  
  /// 导入结果
  final bool success;
  
  /// 导入的项目数量
  final int importedItems;
  
  /// 错误数量
  final int errorCount;
  
  /// 导入耗时（毫秒）
  final int duration;
  
  /// 事务ID
  final String? transactionId;

  const ImportHistoryRecord({
    required this.id,
    required this.importTime,
    required this.fileName,
    this.fileSize = 0,
    this.success = false,
    this.importedItems = 0,
    this.errorCount = 0,
    this.duration = 0,
    this.transactionId,
  });
}

/// 导入操作类型枚举
enum ImportAction {
  /// 新增
  create,
  /// 更新
  update,
  /// 跳过
  skip,
  /// 合并
  merge,
} 