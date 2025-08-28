import '../../../../../infrastructure/logging/logger.dart';
import '../../../../../utils/image_path_converter.dart';

/// 智能图像数据保存策略
/// 根据处理状态确定要保存的最终结果数据，避免存储冗余
class ImageDataSaveStrategy {
  /// 根据处理状态确定要保存的最终结果数据
  static Map<String, dynamic> prepareImageDataForSave(
      Map<String, dynamic> content) {
    try {
      final result = Map<String, dynamic>.from(content);

      // 🔄 路径转换：将绝对路径转换为相对路径（用于数据库存储）
      _convertImagePathToRelative(result);

      // 🎯 核心逻辑：确定最终结果数据
      String? finalResultKey;
      dynamic finalResultData;
      Map<String, dynamic> processingMetadata = {};

      AppLogger.info('开始分析图像数据保存策略',
          tag: 'ImageDataSaveStrategy',
          data: {
            'contentKeys': content.keys.toList(),
            'isBinarizationEnabled': content['isBinarizationEnabled'],
            'isTransformApplied': content['isTransformApplied'],
            'hasBinarizedData': content['binarizedImageData'] != null,
            'hasTransformedData': content['transformedImageData'] != null,
            'hasRawData': content['rawImageData'] != null,
            'hasBase64Data': content['base64ImageData'] != null,
          });

      // 优先级1：二值化数据（最终处理结果）
      if (content['isBinarizationEnabled'] == true &&
          content['binarizedImageData'] != null) {
        finalResultKey = 'binarizedImageData';
        finalResultData = content['binarizedImageData'];

        // 保存二值化相关参数
        processingMetadata.addAll({
          'hasTransformApplied': content['isTransformApplied'] == true,
          'hasBinarizationApplied': true,
          'binaryThreshold': content['binaryThreshold'] ?? 128,
          'isNoiseReductionEnabled':
              content['isNoiseReductionEnabled'] ?? false,
          'noiseReductionLevel': content['noiseReductionLevel'] ?? 1,
        });

        // 如果有变换，也保存变换参数（用于编辑恢复）
        if (content['isTransformApplied'] == true) {
          processingMetadata.addAll({
            'cropX': content['cropX'] ?? 0,
            'cropY': content['cropY'] ?? 0,
            'cropWidth': content['cropWidth'],
            'cropHeight': content['cropHeight'],
            'rotation': content['rotation'] ?? 0,
          });
        }

        AppLogger.info('保存策略：使用二值化数据作为最终结果',
            tag: 'ImageDataSaveStrategy',
            data: {
              'threshold': processingMetadata['binaryThreshold'],
              'hasTransform': processingMetadata['hasTransformApplied'],
              'dataSize': finalResultData is List ? finalResultData.length : 'unknown',
            });
      }
      // 优先级2：变换数据（中间处理结果）
      else if (content['isTransformApplied'] == true &&
               content['transformedImageData'] != null) {
        finalResultKey = 'transformedImageData';
        finalResultData = content['transformedImageData'];

        // 保存变换相关参数
        processingMetadata.addAll({
          'hasTransformApplied': true,
          'hasBinarizationApplied': false,
          'cropX': content['cropX'] ?? 0,
          'cropY': content['cropY'] ?? 0,
          'cropWidth': content['cropWidth'],
          'cropHeight': content['cropHeight'],
          'rotation': content['rotation'] ?? 0,
        });

        AppLogger.info('保存策略：使用变换数据作为最终结果',
            tag: 'ImageDataSaveStrategy',
            data: {
              'cropRect': '(${processingMetadata['cropX']}, ${processingMetadata['cropY']}, ${processingMetadata['cropWidth']}, ${processingMetadata['cropHeight']})',
              'rotation': processingMetadata['rotation'],
              'dataSize': finalResultData is List ? finalResultData.length : 'unknown',
            });
      }
      // 优先级3：原始数据（无处理）
      else if (content['rawImageData'] != null) {
        finalResultKey = 'rawImageData';
        finalResultData = content['rawImageData'];

        processingMetadata.addAll({
          'hasTransformApplied': false,
          'hasBinarizationApplied': false,
        });

        AppLogger.info('保存策略：使用原始数据作为最终结果',
            tag: 'ImageDataSaveStrategy',
            data: {
              'dataSource': 'rawImageData',
              'dataSize': finalResultData is List ? finalResultData.length : 'unknown',
            });
      } else if (content['base64ImageData'] != null) {
        finalResultKey = 'base64ImageData';
        finalResultData = content['base64ImageData'];

        processingMetadata.addAll({
          'hasTransformApplied': false,
          'hasBinarizationApplied': false,
        });

        AppLogger.info('保存策略：使用Base64数据作为最终结果',
            tag: 'ImageDataSaveStrategy',
            data: {
              'dataSource': 'base64ImageData',
              'dataLength': finalResultData is String ? finalResultData.length : 'unknown',
            });
      } else {
        // 无有效图像数据
        AppLogger.warning('没有找到有效的图像数据进行保存',
            tag: 'ImageDataSaveStrategy',
            data: {'availableKeys': content.keys.toList()});
        
        // 保留原始内容，不做优化
        return result;
      }

      // 🧹 清理所有中间数据，只保留最终结果
      _cleanupIntermediateData(result);

      // 📦 保存最终结果和必要的元数据
      if (finalResultKey != null && finalResultData != null) {
        result['finalImageData'] = finalResultData;
        result['finalImageDataSource'] = finalResultKey;

        // 添加通用元数据
        processingMetadata.addAll({
          'originalImageUrl': ImagePathConverter.toRelativePath(content['imageUrl'] ?? ''), // 保存相对路径
          'savedAt': DateTime.now().toIso8601String(),
          'version': '1.0', // 数据格式版本
        });

        result['processingMetadata'] = processingMetadata;

        AppLogger.info('图像数据保存策略完成',
            tag: 'ImageDataSaveStrategy',
            data: {
              'finalDataSource': finalResultKey,
              'hasMetadata': true,
              'metadataKeys': processingMetadata.keys.toList(),
              'originalContentSize': content.length,
              'optimizedContentSize': result.length,
            });
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('图像数据保存策略失败',
          tag: 'ImageDataSaveStrategy',
          error: e,
          stackTrace: stackTrace);
      
      // 发生错误时返回原始内容，确保数据不丢失
      return Map<String, dynamic>.from(content);
    }
  }

  /// 清理中间处理数据
  static void _cleanupIntermediateData(Map<String, dynamic> content) {
    // 🗑️ 移除所有中间数据
    final keysToRemove = [
      'rawImageData',
      'base64ImageData',
      'transformedImageData',
      'binarizedImageData',
      // 保留 imageUrl，可能仍需要作为备用加载源
    ];

    int removedCount = 0;
    for (final key in keysToRemove) {
      if (content.remove(key) != null) {
        removedCount++;
      }
    }

    AppLogger.debug('清理中间数据完成',
        tag: 'ImageDataSaveStrategy',
        data: {
          'removedCount': removedCount,
          'removedKeys': keysToRemove,
          'remainingKeys': content.keys.toList(),
        });
  }

  /// 验证保存数据的完整性
  static bool validateSaveData(Map<String, dynamic> content) {
    try {
      final finalImageData = content['finalImageData'];
      final finalImageDataSource = content['finalImageDataSource'];
      final processingMetadata = content['processingMetadata'];

      if (finalImageData == null) {
        AppLogger.warning('保存数据验证失败：缺少最终图像数据',
            tag: 'ImageDataSaveStrategy');
        return false;
      }

      if (finalImageDataSource == null || finalImageDataSource.isEmpty) {
        AppLogger.warning('保存数据验证失败：缺少数据源标识',
            tag: 'ImageDataSaveStrategy');
        return false;
      }

      if (processingMetadata == null) {
        AppLogger.warning('保存数据验证失败：缺少处理元数据',
            tag: 'ImageDataSaveStrategy');
        return false;
      }

      // 验证数据类型和大小
      if (finalImageData is List && finalImageData.length == 0) {
        AppLogger.warning('保存数据验证失败：图像数据为空',
            tag: 'ImageDataSaveStrategy');
        return false;
      }

      if (finalImageData is String && finalImageData.isEmpty) {
        AppLogger.warning('保存数据验证失败：Base64数据为空',
            tag: 'ImageDataSaveStrategy');
        return false;
      }

      AppLogger.debug('保存数据验证通过',
          tag: 'ImageDataSaveStrategy',
          data: {
            'dataSource': finalImageDataSource,
            'dataSize': finalImageData is List ? finalImageData.length : finalImageData is String ? finalImageData.length : 'unknown',
            'hasMetadata': true,
          });

      return true;
    } catch (e) {
      AppLogger.error('保存数据验证异常',
          tag: 'ImageDataSaveStrategy',
          error: e);
      return false;
    }
  }

  /// 将content中的imageUrl从绝对路径转换为相对路径
  static void _convertImagePathToRelative(Map<String, dynamic> content) {
    final imageUrl = content['imageUrl'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      content['imageUrl'] = ImagePathConverter.toRelativePath(imageUrl);
      
      AppLogger.debug('图像URL路径转换', 
          tag: 'ImageDataSaveStrategy', 
          data: {
            'original': imageUrl,
            'relative': content['imageUrl'],
          });
    }
  }
}