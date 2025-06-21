import '../models/import_export/export_data_model.dart';
import '../models/import_export/import_export_exceptions.dart';

/// 导出进度回调
typedef ExportProgressCallback = void Function(
  double progress,
  String currentOperation,
  Map<String, dynamic>? details,
);

/// 导出服务抽象接口
abstract class ExportService {
  /// 导出作品数据
  /// 
  /// [workIds] 要导出的作品ID列表
  /// [exportType] 导出类型
  /// [options] 导出选项
  /// [targetPath] 目标文件路径
  /// [progressCallback] 进度回调
  /// 
  /// 返回导出清单信息
  Future<ExportManifest> exportWorks(
    List<String> workIds,
    ExportType exportType,
    ExportOptions options,
    String targetPath, {
    ExportProgressCallback? progressCallback,
  });

  /// 导出集字数据
  /// 
  /// [characterIds] 要导出的集字ID列表
  /// [exportType] 导出类型
  /// [options] 导出选项
  /// [targetPath] 目标文件路径
  /// [progressCallback] 进度回调
  /// 
  /// 返回导出清单信息
  Future<ExportManifest> exportCharacters(
    List<String> characterIds,
    ExportType exportType,
    ExportOptions options,
    String targetPath, {
    ExportProgressCallback? progressCallback,
  });

  /// 导出完整数据
  /// 
  /// [workIds] 要导出的作品ID列表（可选）
  /// [characterIds] 要导出的集字ID列表（可选）
  /// [options] 导出选项
  /// [targetPath] 目标文件路径
  /// [progressCallback] 进度回调
  /// 
  /// 返回导出清单信息
  Future<ExportManifest> exportFullData(
    ExportOptions options,
    String targetPath, {
    List<String>? workIds,
    List<String>? characterIds,
    ExportProgressCallback? progressCallback,
  });

  /// 验证导出数据
  /// 
  /// [exportData] 要验证的导出数据
  /// 
  /// 返回验证结果
  Future<List<ExportValidation>> validateExportData(ExportDataModel exportData);

  /// 估算导出大小
  /// 
  /// [workIds] 作品ID列表
  /// [characterIds] 集字ID列表
  /// [options] 导出选项
  /// 
  /// 返回预估大小（字节）
  Future<int> estimateExportSize(
    List<String> workIds,
    List<String> characterIds,
    ExportOptions options,
  );

  /// 检查存储空间
  /// 
  /// [targetPath] 目标路径
  /// [requiredSize] 需要的空间大小
  /// 
  /// 返回是否有足够空间
  Future<bool> checkStorageSpace(String targetPath, int requiredSize);

  /// 取消正在进行的导出操作
  /// 
  /// [operationId] 操作ID（可选，用于识别特定操作）
  Future<void> cancelExport([String? operationId]);

  /// 获取支持的导出格式
  /// 
  /// 返回支持的格式列表
  List<String> getSupportedFormats();

  /// 获取默认导出选项
  /// 
  /// 返回默认选项配置
  ExportOptions getDefaultOptions();
} 