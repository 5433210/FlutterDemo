import '../../../../../infrastructure/logging/logger.dart';

/// 智能图像数据加载策略
/// 从保存的数据恢复完整的图像处理状态
class ImageDataLoadStrategy {
  /// 从保存的数据恢复完整的图像处理状态
  static Map<String, dynamic> restoreImageDataFromSave(
      Map<String, dynamic> savedContent) {
    try {
      final content = Map<String, dynamic>.from(savedContent);

      // 🔍 检查保存的数据结构
      final finalImageData = content['finalImageData'];
      final dataSource = content['finalImageDataSource'] as String?;
      final processingMetadata = content['processingMetadata'] != null
          ? Map<String, dynamic>.from(content['processingMetadata'] as Map)
          : null;

      AppLogger.info('开始恢复图像数据', tag: 'ImageDataLoadStrategy', data: {
        'dataSource': dataSource,
        'hasProcessingMetadata': processingMetadata != null,
        'dataSize': finalImageData is List
            ? finalImageData.length
            : finalImageData is String
                ? finalImageData.length
                : 'unknown',
        'contentKeys': content.keys.toList(),
      });

      if (finalImageData == null) {
        throw Exception('图像数据缺失：无法恢复图像元素');
      }

      if (dataSource == null || dataSource.isEmpty) {
        throw Exception('数据源标识缺失：无法确定恢复方式');
      }

      // 🔄 根据数据来源恢复到对应的处理状态
      Map<String, dynamic> restoredContent;

      switch (dataSource) {
        case 'binarizedImageData':
          restoredContent =
              _restoreBinarizedState(finalImageData, processingMetadata);
          break;

        case 'transformedImageData':
          restoredContent =
              _restoreTransformState(finalImageData, processingMetadata);
          break;

        case 'rawImageData':
          restoredContent = _restoreRawState(
              finalImageData, 'rawImageData', processingMetadata);
          break;

        case 'base64ImageData':
          restoredContent = _restoreRawState(
              finalImageData, 'base64ImageData', processingMetadata);
          break;

        default:
          throw Exception('未知的图像数据源：$dataSource');
      }

      // 🔗 尝试恢复原图链接（如果存在）
      _tryRestoreOriginalImageUrl(restoredContent, processingMetadata);

      // 📋 保留非图像数据的属性
      _preserveNonImageProperties(content, restoredContent);

      // 🏗️ 设置编辑模式状态
      _setupEditingCapabilities(restoredContent, processingMetadata);

      // 清理临时数据
      _cleanupTemporaryData(restoredContent);

      AppLogger.info('图像数据恢复完成', tag: 'ImageDataLoadStrategy', data: {
        'restoredDataSource': dataSource,
        'hasOriginalUrl': restoredContent['imageUrl'] != null,
        'canReprocess': restoredContent['canReprocess'] ?? false,
        'currentDataSources':
            restoredContent.keys.where((k) => k.contains('ImageData')).toList(),
        'editingCapabilities': {
          'canAdjustBinarization':
              restoredContent['canAdjustBinarization'] ?? false,
          'canAdjustTransform': restoredContent['canAdjustTransform'] ?? false,
          'canRevertToOriginal':
              restoredContent['canRevertToOriginal'] ?? false,
        },
      });

      return restoredContent;
    } catch (e, stackTrace) {
      AppLogger.error('图像数据恢复失败',
          tag: 'ImageDataLoadStrategy',
          error: e,
          stackTrace: stackTrace,
          data: {
            'savedContentKeys': savedContent.keys.toList(),
            'hasImageData': savedContent['finalImageData'] != null,
            'hasDataSource': savedContent['finalImageDataSource'] != null,
            'hasMetadata': savedContent['processingMetadata'] != null,
          });
      rethrow;
    }
  }

  /// 恢复二值化状态
  static Map<String, dynamic> _restoreBinarizedState(
      dynamic finalImageData, Map<String, dynamic>? metadata) {
    final content = <String, dynamic>{};

    // 数据恢复
    content['binarizedImageData'] = finalImageData;
    content['isBinarizationEnabled'] = true;

    // 参数恢复 - 安全的类型转换
    content['binaryThreshold'] =
        (metadata?['binaryThreshold'] as num?)?.toInt() ?? 128;
    content['isNoiseReductionEnabled'] =
        metadata?['isNoiseReductionEnabled'] as bool? ?? false;
    content['noiseReductionLevel'] =
        (metadata?['noiseReductionLevel'] as num?)?.toInt() ?? 1;

    // 如果原本有变换，也恢复变换状态
    if (metadata?['hasTransformApplied'] == true) {
      content['isTransformApplied'] = true;
      content['cropX'] = (metadata?['cropX'] as num?)?.toDouble() ?? 0.0;
      content['cropY'] = (metadata?['cropY'] as num?)?.toDouble() ?? 0.0;
      content['cropWidth'] =
          (metadata?['cropWidth'] as num?)?.toDouble() ?? 0.0;
      content['cropHeight'] =
          (metadata?['cropHeight'] as num?)?.toDouble() ?? 0.0;
      content['rotation'] = (metadata?['rotation'] as num?)?.toDouble() ?? 0.0;

      // 🔧 关键修复：当isTransformApplied=true时，渲染器期望有transformedImageData
      // 我们将二值化数据作为变换数据提供，这是合理的，因为二值化是基于变换后的图像
      content['transformedImageData'] = finalImageData;

      AppLogger.debug('恢复变换数据用于渲染器兼容', tag: 'ImageDataLoadStrategy', data: {
        'reason':
            'renderer expects transformedImageData when isTransformApplied=true',
        'providedDataSize':
            finalImageData is List ? finalImageData.length : 'unknown',
      });
    }

    // 编辑能力设置
    content['canAdjustBinarization'] = true;
    content['canRevertToTransform'] = metadata?['hasTransformApplied'] == true;
    content['canRevertToOriginal'] = true;

    AppLogger.debug('恢复二值化状态完成', tag: 'ImageDataLoadStrategy', data: {
      'threshold': content['binaryThreshold'],
      'noiseReduction': content['isNoiseReductionEnabled'],
      'hasTransform': metadata?['hasTransformApplied'] == true,
      'dataSize': finalImageData is List ? finalImageData.length : 'unknown',
    });

    return content;
  }

  /// 恢复变换状态
  static Map<String, dynamic> _restoreTransformState(
      dynamic finalImageData, Map<String, dynamic>? metadata) {
    final content = <String, dynamic>{};

    // 数据恢复
    content['transformedImageData'] = finalImageData;
    content['isTransformApplied'] = true;

    // 参数恢复 - 安全的类型转换
    content['cropX'] = (metadata?['cropX'] as num?)?.toDouble() ?? 0.0;
    content['cropY'] = (metadata?['cropY'] as num?)?.toDouble() ?? 0.0;
    content['cropWidth'] = (metadata?['cropWidth'] as num?)?.toDouble() ?? 0.0;
    content['cropHeight'] =
        (metadata?['cropHeight'] as num?)?.toDouble() ?? 0.0;
    content['rotation'] = (metadata?['rotation'] as num?)?.toDouble() ?? 0.0;

    // 编辑能力设置
    content['canAdjustTransform'] = true;
    content['canApplyBinarization'] = true;
    content['canRevertToOriginal'] = true;

    AppLogger.debug('恢复变换状态完成', tag: 'ImageDataLoadStrategy', data: {
      'cropRect':
          '(${content['cropX']}, ${content['cropY']}, ${content['cropWidth']}, ${content['cropHeight']})',
      'rotation': content['rotation'],
      'dataSize': finalImageData is List ? finalImageData.length : 'unknown',
    });

    return content;
  }

  /// 恢复原始状态
  static Map<String, dynamic> _restoreRawState(dynamic finalImageData,
      String dataSourceType, Map<String, dynamic>? metadata) {
    final content = <String, dynamic>{};

    // 数据恢复
    content[dataSourceType] = finalImageData;

    // 编辑能力设置（完全可编辑）
    content['canAdjustTransform'] = true;
    content['canApplyBinarization'] = true;
    content['canRevertToOriginal'] = true;

    AppLogger.debug('恢复原始状态完成', tag: 'ImageDataLoadStrategy', data: {
      'sourceType': dataSourceType,
      'dataSize': finalImageData is List
          ? finalImageData.length
          : finalImageData is String
              ? finalImageData.length
              : 'unknown',
    });

    return content;
  }

  /// 尝试恢复原图URL链接
  static void _tryRestoreOriginalImageUrl(
      Map<String, dynamic> content, Map<String, dynamic>? metadata) {
    final originalUrl = metadata?['originalImageUrl'] as String?;
    content['imageUrl'] = originalUrl;
    content['originalImageAvailable'] = true;
    content['canReprocess'] = true;
    // if (originalUrl != null && originalUrl.isNotEmpty) {
    //   // 检查原图文件是否仍然存在
    //   final filePath = originalUrl.startsWith('file://')
    //       ? originalUrl.substring(7)
    //       : originalUrl;

    //   final file = File(filePath);
    //   file.exists().then((exists) {
    //     if (exists) {
    //       content['imageUrl'] = originalUrl;
    //       content['originalImageAvailable'] = true;
    //       content['canReprocess'] = true;
    //       AppLogger.info('原图文件仍然存在，恢复URL链接',
    //           tag: 'ImageDataLoadStrategy',
    //           data: {'url': originalUrl});
    //     } else {
    //       content['originalImageAvailable'] = false;
    //       content['canReprocess'] = false;
    //       content['fallbackMode'] = true;
    //       AppLogger.warning('原图文件已不存在，启用降级模式',
    //           tag: 'ImageDataLoadStrategy',
    //           data: {
    //             'originalUrl': originalUrl,
    //             'fallbackAvailable': true,
    //           });
    //     }
    //   }).catchError((e) {
    //     AppLogger.warning('检查原图文件存在性时出错',
    //         tag: 'ImageDataLoadStrategy',
    //         error: e,
    //         data: {'originalUrl': originalUrl});
    //     content['originalImageAvailable'] = false;
    //     content['canReprocess'] = false;
    //     content['fallbackMode'] = true;
    //   });
    // } else {
    //   content['originalImageAvailable'] = false;
    //   content['canReprocess'] = false;
    //   AppLogger.debug('没有原图URL信息',
    //       tag: 'ImageDataLoadStrategy');
    // }
  }

  /// 保留非图像数据的属性
  static void _preserveNonImageProperties(
      Map<String, dynamic> source, Map<String, dynamic> target) {
    // 需要保留的非图像数据属性
    final preserveKeys = [
      'fitMode',
      'opacity',
      'backgroundColor',
      'alignment',
      'isFlippedHorizontally',
      'isFlippedVertically',
      // 添加其他需要保留的UI属性
    ];

    for (final key in preserveKeys) {
      if (source.containsKey(key)) {
        target[key] = source[key];
      }
    }

    AppLogger.debug('保留非图像属性完成', tag: 'ImageDataLoadStrategy', data: {
      'preservedKeys':
          preserveKeys.where((k) => source.containsKey(k)).toList(),
    });
  }

  /// 设置编辑能力
  static void _setupEditingCapabilities(
      Map<String, dynamic> content, Map<String, dynamic>? metadata) {
    // 设置基本编辑状态
    content['isEditingMode'] = true;

    // 根据元数据设置处理能力
    final hasTransformApplied = metadata?['hasTransformApplied'] == true;
    final hasBinarizationApplied = metadata?['hasBinarizationApplied'] == true;

    content['processingState'] = {
      'hasTransformApplied': hasTransformApplied,
      'hasBinarizationApplied': hasBinarizationApplied,
      'canUndo': hasTransformApplied || hasBinarizationApplied,
      'canRedo': false, // 加载时重置redo状态
    };

    AppLogger.debug('编辑能力设置完成', tag: 'ImageDataLoadStrategy', data: {
      'isEditingMode': true,
      'hasTransform': hasTransformApplied,
      'hasBinarization': hasBinarizationApplied,
    });
  }

  /// 清理临时数据
  static void _cleanupTemporaryData(Map<String, dynamic> content) {
    final keysToRemove = [
      'finalImageData',
      'finalImageDataSource',
      'processingMetadata',
    ];

    int removedCount = 0;
    for (final key in keysToRemove) {
      if (content.remove(key) != null) {
        removedCount++;
      }
    }

    AppLogger.debug('清理临时数据完成', tag: 'ImageDataLoadStrategy', data: {
      'removedCount': removedCount,
      'removedKeys': keysToRemove,
    });
  }

  /// 验证恢复数据的完整性
  static bool validateRestoredData(Map<String, dynamic> content) {
    try {
      // 检查是否有有效的图像数据
      final hasValidImageData = content['binarizedImageData'] != null ||
          content['transformedImageData'] != null ||
          content['rawImageData'] != null ||
          content['base64ImageData'] != null;

      if (!hasValidImageData) {
        AppLogger.warning('恢复数据验证失败：没有有效的图像数据', tag: 'ImageDataLoadStrategy');
        return false;
      }

      // 检查编辑能力设置
      if (content['isEditingMode'] != true) {
        AppLogger.warning('恢复数据验证失败：编辑模式未正确设置', tag: 'ImageDataLoadStrategy');
        return false;
      }

      AppLogger.debug('恢复数据验证通过', tag: 'ImageDataLoadStrategy', data: {
        'hasValidImageData': hasValidImageData,
        'isEditingMode': content['isEditingMode'],
        'availableDataSources':
            content.keys.where((k) => k.contains('ImageData')).toList(),
      });

      return true;
    } catch (e) {
      AppLogger.error('恢复数据验证异常', tag: 'ImageDataLoadStrategy', error: e);
      return false;
    }
  }
}
