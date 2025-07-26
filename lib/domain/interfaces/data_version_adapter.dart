/// 数据版本适配器接口
library data_version_adapter;

/// 数据版本适配器接口
abstract class DataVersionAdapter {
  /// 源数据版本
  String get sourceDataVersion;
  
  /// 目标数据版本
  String get targetDataVersion;
  
  /// 预处理阶段
  /// 在应用重启前执行的数据处理
  Future<PreProcessResult> preProcess(String dataPath);
  
  /// 后处理阶段（重启后执行）
  /// 在应用重启后执行的数据处理
  Future<PostProcessResult> postProcess(String dataPath);
  
  /// 验证适配结果
  /// 验证数据适配是否成功
  Future<bool> validateAdaptation(String dataPath);
  
  /// 与现有数据库迁移集成
  /// 执行数据库相关的迁移操作
  Future<void> integrateDatabaseMigration(String dataPath);
  
  /// 获取适配器描述
  String get description => '从 $sourceDataVersion 升级到 $targetDataVersion';
  
  /// 获取预估处理时间（秒）
  int get estimatedProcessingTime => 30;
  
  /// 是否需要重启应用
  bool get requiresRestart => true;
}

/// 预处理结果
class PreProcessResult {
  /// 处理是否成功
  final bool success;
  
  /// 是否需要重启应用
  final bool needsRestart;
  
  /// 状态数据，用于在重启后恢复状态
  final Map<String, dynamic> stateData;
  
  /// 错误消息
  final String? errorMessage;
  
  /// 处理的文件数量
  final int processedFiles;
  
  /// 跳过的文件数量
  final int skippedFiles;
  
  /// 处理时间（毫秒）
  final int processingTimeMs;

  const PreProcessResult({
    required this.success,
    this.needsRestart = false,
    this.stateData = const {},
    this.errorMessage,
    this.processedFiles = 0,
    this.skippedFiles = 0,
    this.processingTimeMs = 0,
  });

  /// 创建成功结果
  factory PreProcessResult.success({
    bool needsRestart = false,
    Map<String, dynamic> stateData = const {},
    int processedFiles = 0,
    int skippedFiles = 0,
    int processingTimeMs = 0,
  }) {
    return PreProcessResult(
      success: true,
      needsRestart: needsRestart,
      stateData: stateData,
      processedFiles: processedFiles,
      skippedFiles: skippedFiles,
      processingTimeMs: processingTimeMs,
    );
  }

  /// 创建失败结果
  factory PreProcessResult.failure(String errorMessage) {
    return PreProcessResult(
      success: false,
      errorMessage: errorMessage,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'needsRestart': needsRestart,
      'stateData': stateData,
      'errorMessage': errorMessage,
      'processedFiles': processedFiles,
      'skippedFiles': skippedFiles,
      'processingTimeMs': processingTimeMs,
    };
  }

  /// 从Map创建实例
  factory PreProcessResult.fromMap(Map<String, dynamic> map) {
    return PreProcessResult(
      success: map['success'] as bool,
      needsRestart: map['needsRestart'] as bool? ?? false,
      stateData: Map<String, dynamic>.from(map['stateData'] ?? {}),
      errorMessage: map['errorMessage'] as String?,
      processedFiles: map['processedFiles'] as int? ?? 0,
      skippedFiles: map['skippedFiles'] as int? ?? 0,
      processingTimeMs: map['processingTimeMs'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'PreProcessResult(success: $success, needsRestart: $needsRestart, processedFiles: $processedFiles)';
  }
}

/// 后处理结果
class PostProcessResult {
  /// 处理是否成功
  final bool success;
  
  /// 执行的步骤列表
  final List<String> executedSteps;
  
  /// 错误消息
  final String? errorMessage;
  
  /// 处理的记录数量
  final int processedRecords;
  
  /// 更新的记录数量
  final int updatedRecords;
  
  /// 处理时间（毫秒）
  final int processingTimeMs;

  const PostProcessResult({
    required this.success,
    this.executedSteps = const [],
    this.errorMessage,
    this.processedRecords = 0,
    this.updatedRecords = 0,
    this.processingTimeMs = 0,
  });

  /// 创建成功结果
  factory PostProcessResult.success({
    List<String> executedSteps = const [],
    int processedRecords = 0,
    int updatedRecords = 0,
    int processingTimeMs = 0,
  }) {
    return PostProcessResult(
      success: true,
      executedSteps: executedSteps,
      processedRecords: processedRecords,
      updatedRecords: updatedRecords,
      processingTimeMs: processingTimeMs,
    );
  }

  /// 创建失败结果
  factory PostProcessResult.failure(String errorMessage, {
    List<String> executedSteps = const [],
  }) {
    return PostProcessResult(
      success: false,
      errorMessage: errorMessage,
      executedSteps: executedSteps,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'executedSteps': executedSteps,
      'errorMessage': errorMessage,
      'processedRecords': processedRecords,
      'updatedRecords': updatedRecords,
      'processingTimeMs': processingTimeMs,
    };
  }

  /// 从Map创建实例
  factory PostProcessResult.fromMap(Map<String, dynamic> map) {
    return PostProcessResult(
      success: map['success'] as bool,
      executedSteps: List<String>.from(map['executedSteps'] ?? []),
      errorMessage: map['errorMessage'] as String?,
      processedRecords: map['processedRecords'] as int? ?? 0,
      updatedRecords: map['updatedRecords'] as int? ?? 0,
      processingTimeMs: map['processingTimeMs'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'PostProcessResult(success: $success, executedSteps: ${executedSteps.length}, processedRecords: $processedRecords)';
  }
}

/// 适配器执行状态
enum AdapterExecutionStatus {
  /// 未开始
  notStarted,
  
  /// 预处理中
  preProcessing,
  
  /// 等待重启
  waitingForRestart,
  
  /// 后处理中
  postProcessing,
  
  /// 已完成
  completed,
  
  /// 失败
  failed;
  
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case AdapterExecutionStatus.notStarted:
        return '未开始';
      case AdapterExecutionStatus.preProcessing:
        return '预处理中';
      case AdapterExecutionStatus.waitingForRestart:
        return '等待重启';
      case AdapterExecutionStatus.postProcessing:
        return '后处理中';
      case AdapterExecutionStatus.completed:
        return '已完成';
      case AdapterExecutionStatus.failed:
        return '失败';
    }
  }
}
