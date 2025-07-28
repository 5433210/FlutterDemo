import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../logging/logger.dart';

/// 文件完整性校验结果
class IntegrityVerificationResult {
  /// 是否通过校验
  final bool isValid;
  
  /// 错误信息列表
  final List<String> errors;
  
  /// 警告信息列表
  final List<String> warnings;
  
  /// 校验详情
  final Map<String, dynamic> details;
  
  /// 校验耗时
  final Duration verificationTime;

  const IntegrityVerificationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.details = const {},
    required this.verificationTime,
  });
}

/// 文件完整性校验服务
class FileIntegrityService {
  static const String _tag = 'FileIntegrityService';

  /// 验证文件完整性
  static Future<IntegrityVerificationResult> verifyFileIntegrity(
      String filePath) async {
    final startTime = DateTime.now();
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      AppLogger.info('开始文件完整性校验', 
          data: {'filePath': filePath}, tag: _tag);

      // 1. 基础文件检查
      final file = File(filePath);
      if (!await file.exists()) {
        errors.add('文件不存在: $filePath');
        return IntegrityVerificationResult(
          isValid: false,
          errors: errors,
          verificationTime: DateTime.now().difference(startTime),
        );
      }

      final fileSize = await file.length();
      details['fileSize'] = fileSize;
      details['fileName'] = path.basename(filePath);

      // 2. 检查文件大小
      if (fileSize == 0) {
        errors.add('文件为空');
        return IntegrityVerificationResult(
          isValid: false,
          errors: errors,
          details: details,
          verificationTime: DateTime.now().difference(startTime),
        );
      }

      // 3. 计算文件哈希
      final bytes = await file.readAsBytes();
      final sha256Hash = sha256.convert(bytes);
      final md5Hash = md5.convert(bytes);
      
      details['sha256'] = sha256Hash.toString();
      details['md5'] = md5Hash.toString();

      // 4. 根据文件扩展名进行特定检查
      final extension = path.extension(filePath).toLowerCase();
      switch (extension) {
        case '.cgw':
        case '.cgc':
        case '.cgb':
          // 检查7zip文件头
          if (!_is7zipFormat(bytes)) {
            warnings.add('文件扩展名为7zip格式但文件头不匹配');
          }
          break;
        case '.zip':
          // 检查ZIP文件头
          if (!_isZipFormat(bytes)) {
            warnings.add('文件扩展名为ZIP格式但文件头不匹配');
          }
          break;
        default:
          warnings.add('未知文件格式: $extension');
      }

      AppLogger.info('文件完整性校验完成', 
          data: {
            'size': fileSize,
            'sha256': sha256Hash.toString(),
            'extension': extension,
            'warningCount': warnings.length,
          }, tag: _tag);

    } catch (e, stackTrace) {
      AppLogger.error('文件完整性校验失败', 
          error: e, stackTrace: stackTrace, tag: _tag);
      errors.add('校验过程出错: ${e.toString()}');
    }

    return IntegrityVerificationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: details,
      verificationTime: DateTime.now().difference(startTime),
    );
  }

  /// 检查是否为7zip格式
  static bool _is7zipFormat(List<int> bytes) {
    if (bytes.length < 6) return false;
    
    // 7zip文件头: 37 7A BC AF 27 1C
    return bytes[0] == 0x37 && 
           bytes[1] == 0x7A && 
           bytes[2] == 0xBC && 
           bytes[3] == 0xAF && 
           bytes[4] == 0x27 && 
           bytes[5] == 0x1C;
  }

  /// 检查是否为ZIP格式
  static bool _isZipFormat(List<int> bytes) {
    if (bytes.length < 4) return false;
    
    // ZIP文件头: 50 4B 03 04 或 50 4B 05 06 或 50 4B 07 08
    return bytes[0] == 0x50 && 
           bytes[1] == 0x4B && 
           (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07);
  }
}
