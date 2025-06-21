/// 导入导出异常基类
abstract class ImportExportException implements Exception {
  /// 错误消息
  final String message;
  
  /// 错误代码
  final String errorCode;
  
  /// 详细信息
  final Map<String, dynamic>? details;
  
  /// 内部异常
  final Exception? innerException;
  
  const ImportExportException(
    this.message,
    this.errorCode, {
    this.details,
    this.innerException,
  });

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message (Code: $errorCode)');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    if (innerException != null) {
      buffer.write('\nInner Exception: $innerException');
    }
    return buffer.toString();
  }
}

/// 导出异常
class ExportException extends ImportExportException {
  const ExportException(
    super.message,
    super.errorCode, {
    super.details,
    super.innerException,
  });
}

/// 导入异常
class ImportException extends ImportExportException {
  const ImportException(
    super.message,
    super.errorCode, {
    super.details,
    super.innerException,
  });
}

/// 文件操作异常
class FileOperationException extends ImportExportException {
  /// 文件路径
  final String filePath;
  
  const FileOperationException(
    super.message,
    super.errorCode,
    this.filePath, {
    super.details,
    super.innerException,
  });
  
  @override
  String toString() {
    return '${super.toString()}\nFile Path: $filePath';
  }
}

/// 数据验证异常
class DataValidationException extends ImportExportException {
  /// 验证失败的实体类型
  final String entityType;
  
  /// 验证失败的实体ID
  final String? entityId;
  
  /// 验证失败的字段
  final List<String> failedFields;
  
  const DataValidationException(
    super.message,
    super.errorCode,
    this.entityType, {
    this.entityId,
    this.failedFields = const [],
    super.details,
    super.innerException,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    buffer.write('\nEntity Type: $entityType');
    if (entityId != null) {
      buffer.write('\nEntity ID: $entityId');
    }
    if (failedFields.isNotEmpty) {
      buffer.write('\nFailed Fields: ${failedFields.join(', ')}');
    }
    return buffer.toString();
  }
}

/// 兼容性异常
class CompatibilityException extends ImportExportException {
  /// 当前版本
  final String currentVersion;
  
  /// 要求的版本
  final String requiredVersion;
  
  /// 不兼容的功能
  final List<String> incompatibleFeatures;
  
  const CompatibilityException(
    super.message,
    super.errorCode,
    this.currentVersion,
    this.requiredVersion, {
    this.incompatibleFeatures = const [],
    super.details,
    super.innerException,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    buffer.write('\nCurrent Version: $currentVersion');
    buffer.write('\nRequired Version: $requiredVersion');
    if (incompatibleFeatures.isNotEmpty) {
      buffer.write('\nIncompatible Features: ${incompatibleFeatures.join(', ')}');
    }
    return buffer.toString();
  }
}

/// 存储空间不足异常
class InsufficientStorageException extends ImportExportException {
  /// 需要的空间（字节）
  final int requiredSpace;
  
  /// 可用空间（字节）
  final int availableSpace;
  
  const InsufficientStorageException(
    super.message,
    super.errorCode,
    this.requiredSpace,
    this.availableSpace, {
    super.details,
    super.innerException,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    buffer.write('\nRequired Space: ${_formatBytes(requiredSpace)}');
    buffer.write('\nAvailable Space: ${_formatBytes(availableSpace)}');
    buffer.write('\nShortfall: ${_formatBytes(requiredSpace - availableSpace)}');
    return buffer.toString();
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// 文件损坏异常
class FileCorruptionException extends FileOperationException {
  /// 损坏类型
  final String corruptionType;
  
  /// 校验和不匹配信息
  final Map<String, String>? checksumInfo;
  
  const FileCorruptionException(
    super.message,
    super.errorCode,
    super.filePath,
    this.corruptionType, {
    this.checksumInfo,
    super.details,
    super.innerException,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    buffer.write('\nCorruption Type: $corruptionType');
    if (checksumInfo != null) {
      buffer.write('\nChecksum Info: $checksumInfo');
    }
    return buffer.toString();
  }
}

/// 权限异常
class PermissionException extends ImportExportException {
  /// 操作类型
  final String operationType;
  
  /// 资源路径
  final String resourcePath;
  
  const PermissionException(
    super.message,
    super.errorCode,
    this.operationType,
    this.resourcePath, {
    super.details,
    super.innerException,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    buffer.write('\nOperation Type: $operationType');
    buffer.write('\nResource Path: $resourcePath');
    return buffer.toString();
  }
}

/// 网络异常
class NetworkException extends ImportExportException {
  /// 网络操作类型
  final String operationType;
  
  /// URL
  final String? url;
  
  /// HTTP状态码
  final int? statusCode;
  
  const NetworkException(
    super.message,
    super.errorCode,
    this.operationType, {
    this.url,
    this.statusCode,
    super.details,
    super.innerException,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    buffer.write('\nOperation Type: $operationType');
    if (url != null) {
      buffer.write('\nURL: $url');
    }
    if (statusCode != null) {
      buffer.write('\nStatus Code: $statusCode');
    }
    return buffer.toString();
  }
}

/// 用户取消异常
class UserCancelledException extends ImportExportException {
  /// 取消的操作
  final String operation;
  
  /// 取消时的进度
  final double progress;
  
  const UserCancelledException(
    super.message,
    super.errorCode,
    this.operation,
    this.progress, {
    super.details,
    super.innerException,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    buffer.write('\nOperation: $operation');
    buffer.write('\nProgress: ${(progress * 100).toStringAsFixed(1)}%');
    return buffer.toString();
  }
}

/// 超时异常
class TimeoutException extends ImportExportException {
  /// 操作类型
  final String operationType;
  
  /// 超时时间（秒）
  final int timeoutSeconds;
  
  const TimeoutException(
    super.message,
    super.errorCode,
    this.operationType,
    this.timeoutSeconds, {
    super.details,
    super.innerException,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    buffer.write('\nOperation Type: $operationType');
    buffer.write('\nTimeout: ${timeoutSeconds}s');
    return buffer.toString();
  }
}

/// 并发异常
class ConcurrencyException extends ImportExportException {
  /// 冲突的操作
  final String conflictingOperation;
  
  /// 资源标识
  final String resourceId;
  
  const ConcurrencyException(
    super.message,
    super.errorCode,
    this.conflictingOperation,
    this.resourceId, {
    super.details,
    super.innerException,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    buffer.write('\nConflicting Operation: $conflictingOperation');
    buffer.write('\nResource ID: $resourceId');
    return buffer.toString();
  }
}

/// 配置异常
class ConfigurationException extends ImportExportException {
  /// 配置键
  final String configKey;
  
  /// 配置值
  final String? configValue;
  
  const ConfigurationException(
    super.message,
    super.errorCode,
    this.configKey, {
    this.configValue,
    super.details,
    super.innerException,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    buffer.write('\nConfig Key: $configKey');
    if (configValue != null) {
      buffer.write('\nConfig Value: $configValue');
    }
    return buffer.toString();
  }
}

/// 常用错误代码
class ImportExportErrorCodes {
  // 导出错误
  static const String exportDataQueryFailed = 'EXPORT_DATA_QUERY_FAILED';
  static const String exportFileCreationFailed = 'EXPORT_FILE_CREATION_FAILED';
  static const String exportCompressionFailed = 'EXPORT_COMPRESSION_FAILED';
  static const String exportInsufficientStorage = 'EXPORT_INSUFFICIENT_STORAGE';
  static const String exportPermissionDenied = 'EXPORT_PERMISSION_DENIED';
  
  // 导入错误
  static const String importFileNotFound = 'IMPORT_FILE_NOT_FOUND';
  static const String importFileCorrupted = 'IMPORT_FILE_CORRUPTED';
  static const String importDataValidationFailed = 'IMPORT_DATA_VALIDATION_FAILED';
  static const String importCompatibilityFailed = 'IMPORT_COMPATIBILITY_FAILED';
  static const String importDatabaseWriteFailed = 'IMPORT_DATABASE_WRITE_FAILED';
  static const String importRollbackFailed = 'IMPORT_ROLLBACK_FAILED';
  
  // 文件操作错误
  static const String fileReadFailed = 'FILE_READ_FAILED';
  static const String fileWriteFailed = 'FILE_WRITE_FAILED';
  static const String fileDeleteFailed = 'FILE_DELETE_FAILED';
  static const String fileCopyFailed = 'FILE_COPY_FAILED';
  static const String fileMoveFailed = 'FILE_MOVE_FAILED';
  static const String fileChecksumMismatch = 'FILE_CHECKSUM_MISMATCH';
  
  // 网络错误
  static const String networkConnectionFailed = 'NETWORK_CONNECTION_FAILED';
  static const String networkTimeoutFailed = 'NETWORK_TIMEOUT_FAILED';
  static const String networkDownloadFailed = 'NETWORK_DOWNLOAD_FAILED';
  static const String networkUploadFailed = 'NETWORK_UPLOAD_FAILED';
  
  // 用户操作错误
  static const String userCancelledOperation = 'USER_CANCELLED_OPERATION';
  static const String userInvalidInput = 'USER_INVALID_INPUT';
  
  // 系统错误
  static const String systemResourceExhausted = 'SYSTEM_RESOURCE_EXHAUSTED';
  static const String systemOperationTimeout = 'SYSTEM_OPERATION_TIMEOUT';
  static const String systemConcurrencyConflict = 'SYSTEM_CONCURRENCY_CONFLICT';
  static const String systemConfigurationError = 'SYSTEM_CONFIGURATION_ERROR';
} 