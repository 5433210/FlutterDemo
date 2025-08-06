/// 压缩服务接口
abstract class CompressionService {
  /// 压缩文件或目录
  Future<CompressionResult> compress({
    required String sourcePath,
    required String targetPath,
    CompressionOptions? options,
  });

  /// 解压文件
  Future<DecompressionResult> decompress({
    required String sourcePath,
    required String targetPath,
    DecompressionOptions? options,
  });

  /// 验证文件完整性
  Future<bool> verifyIntegrity(String filePath);

  /// 获取支持的压缩格式
  List<CompressionFormat> getSupportedFormats();
}

/// 压缩选项
class CompressionOptions {
  /// 压缩级别 (0-9)
  final int compressionLevel;

  /// 是否包含隐藏文件
  final bool includeHiddenFiles;

  /// 文件过滤器
  final bool Function(String path)? fileFilter;

  /// 自定义选项
  final Map<String, dynamic> customOptions;

  const CompressionOptions({
    this.compressionLevel = 6,
    this.includeHiddenFiles = false,
    this.fileFilter,
    this.customOptions = const {},
  });
}

/// 解压选项
class DecompressionOptions {
  /// 是否验证完整性
  final bool verifyIntegrity;

  /// 是否覆盖现有文件
  final bool overwriteExisting;

  /// 文件过滤器
  final bool Function(String path)? fileFilter;

  /// 自定义选项
  final Map<String, dynamic> customOptions;

  const DecompressionOptions({
    this.verifyIntegrity = true,
    this.overwriteExisting = false,
    this.fileFilter,
    this.customOptions = const {},
  });
}

/// 压缩结果
class CompressionResult {
  /// 是否成功
  final bool success;

  /// 输出文件路径
  final String? outputPath;

  /// 原始大小（字节）
  final int originalSize;

  /// 压缩后大小（字节）
  final int compressedSize;

  /// 压缩率 (0.0-1.0)
  final double compressionRatio;

  /// 文件校验和
  final String? checksum;

  /// 处理时间
  final Duration duration;

  /// 压缩格式
  final CompressionFormat format;

  /// 错误信息
  final String? errorMessage;

  /// 额外信息
  final Map<String, dynamic> metadata;

  const CompressionResult({
    required this.success,
    this.outputPath,
    this.originalSize = 0,
    this.compressedSize = 0,
    this.compressionRatio = 0.0,
    this.checksum,
    required this.duration,
    required this.format,
    this.errorMessage,
    this.metadata = const {},
  });

  /// 获取压缩率百分比
  double get compressionPercentage => compressionRatio * 100;

  /// 获取节省的空间
  int get savedBytes => originalSize - compressedSize;
}

/// 解压结果
class DecompressionResult {
  /// 是否成功
  final bool success;

  /// 输出目录路径
  final String? outputPath;

  /// 解压的文件数量
  final int extractedFiles;

  /// 总大小（字节）
  final int totalSize;

  /// 处理时间
  final Duration duration;

  /// 压缩格式
  final CompressionFormat format;

  /// 错误信息
  final String? errorMessage;

  /// 额外信息
  final Map<String, dynamic> metadata;

  const DecompressionResult({
    required this.success,
    this.outputPath,
    this.extractedFiles = 0,
    this.totalSize = 0,
    required this.duration,
    required this.format,
    this.errorMessage,
    this.metadata = const {},
  });
}

/// 压缩格式枚举
enum CompressionFormat {
  /// ZIP格式
  zip,

  /// 7zip格式
  sevenZip,

  /// TAR格式
  tar,

  /// GZIP格式
  gzip,
}

/// 压缩格式扩展
extension CompressionFormatExtension on CompressionFormat {
  /// 获取文件扩展名
  String get extension {
    switch (this) {
      case CompressionFormat.zip:
        return 'zip';
      case CompressionFormat.sevenZip:
        return '7z';
      case CompressionFormat.tar:
        return 'tar';
      case CompressionFormat.gzip:
        return 'gz';
    }
  }

  /// 获取MIME类型
  String get mimeType {
    switch (this) {
      case CompressionFormat.zip:
        return 'application/zip';
      case CompressionFormat.sevenZip:
        return 'application/x-7z-compressed';
      case CompressionFormat.tar:
        return 'application/x-tar';
      case CompressionFormat.gzip:
        return 'application/gzip';
    }
  }

  /// 获取格式描述
  String get description {
    switch (this) {
      case CompressionFormat.zip:
        return 'ZIP Archive';
      case CompressionFormat.sevenZip:
        return '7-Zip Archive';
      case CompressionFormat.tar:
        return 'TAR Archive';
      case CompressionFormat.gzip:
        return 'GZIP Archive';
    }
  }
}

/// 文件完整性验证结果
class IntegrityVerificationResult {
  /// 是否有效
  final bool isValid;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 验证详情
  final Map<String, dynamic> details;

  /// 验证时间
  final Duration verificationTime;

  const IntegrityVerificationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.details = const {},
    required this.verificationTime,
  });

  /// 是否有错误
  bool get hasErrors => errors.isNotEmpty;

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;

  /// 获取所有问题
  List<String> get allIssues => [...errors, ...warnings];
}
