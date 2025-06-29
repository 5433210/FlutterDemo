import 'dart:io';

/// 图像验证和处理工具类
class ImageValidationUtils {
  /// 支持的图像格式
  static const Set<String> supportedFormats = {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'bmp',
    'webp',
    'svg',
  };

  /// 检查文件扩展名是否为支持的图像格式
  static bool isSupportedImageFormat(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return supportedFormats.contains(extension);
  }

  /// 检查是否为SVG格式
  static bool isSvgFormat(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return extension == 'svg';
  }

  /// 验证图像文件是否有效
  static Future<ImageValidationResult> validateImageFile(
      String filePath) async {
    try {
      final file = File(filePath);

      // 检查文件是否存在
      if (!await file.exists()) {
        return ImageValidationResult.error('文件不存在: $filePath');
      }

      // 检查文件大小
      final size = await file.length();
      if (size == 0) {
        return ImageValidationResult.error('文件为空');
      }

      // 检查格式支持
      if (!isSupportedImageFormat(filePath)) {
        final extension = filePath.split('.').last;
        return ImageValidationResult.error('不支持的图像格式: $extension');
      }

      // 对SVG文件进行特殊验证
      if (isSvgFormat(filePath)) {
        return await _validateSvgFile(file);
      }

      // 对其他图像格式进行基本验证
      return await _validateBinaryImage(file);
    } catch (e) {
      return ImageValidationResult.error('文件验证失败: $e');
    }
  }

  /// 验证SVG文件
  static Future<ImageValidationResult> _validateSvgFile(File file) async {
    try {
      final content = await file.readAsString();

      if (content.trim().isEmpty) {
        return ImageValidationResult.error('SVG文件内容为空');
      }

      final lowerContent = content.toLowerCase();
      if (!lowerContent.contains('<svg')) {
        return ImageValidationResult.error('文件不包含有效的SVG标签');
      }

      if (!lowerContent.contains('</svg>')) {
        return ImageValidationResult.error('SVG文件格式不完整，缺少结束标签');
      }

      return ImageValidationResult.success('SVG文件验证通过');
    } catch (e) {
      return ImageValidationResult.error('SVG文件读取失败: $e');
    }
  }

  /// 验证二进制图像文件
  static Future<ImageValidationResult> _validateBinaryImage(File file) async {
    try {
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        return ImageValidationResult.error('图像文件数据为空');
      }

      // 检查常见的图像文件头
      if (_hasValidImageHeader(bytes)) {
        return ImageValidationResult.success('图像文件验证通过');
      }

      return ImageValidationResult.error('图像文件头无效，可能文件已损坏');
    } catch (e) {
      return ImageValidationResult.error('图像文件读取失败: $e');
    }
  }

  /// 检查是否有有效的图像文件头
  static bool _hasValidImageHeader(List<int> bytes) {
    if (bytes.length < 4) return false;

    // PNG文件头
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    // JPEG文件头
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return true;
    }

    // GIF文件头
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return true;
    }

    // BMP文件头
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return true;
    }

    // WebP文件头
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }

    return false;
  }

  /// 获取友好的错误消息
  static String getFriendlyErrorMessage(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('invalid image data')) {
      return '图像数据无效。可能的原因：\n• 文件已损坏\n• 文件格式不受支持\n• 文件不是有效的图像文件';
    }

    if (lowerError.contains('file not found')) {
      return '找不到图像文件，可能文件已被移动或删除';
    }

    if (lowerError.contains('permission denied')) {
      return '没有权限访问图像文件，请检查文件权限';
    }

    if (lowerError.contains('svg')) {
      return 'SVG文件处理失败。请确保：\n• 文件是有效的SVG格式\n• 文件内容完整\n• 文件编码正确';
    }

    return error;
  }
}

/// 图像验证结果
class ImageValidationResult {
  final bool isValid;
  final String message;

  const ImageValidationResult._({
    required this.isValid,
    required this.message,
  });

  factory ImageValidationResult.success(String message) {
    return ImageValidationResult._(isValid: true, message: message);
  }

  factory ImageValidationResult.error(String message) {
    return ImageValidationResult._(isValid: false, message: message);
  }
}
