import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../infrastructure/logging/logger.dart';
import 'image_data_save_strategy.dart';
import 'image_data_load_strategy.dart';

/// 智能图像数据管理器
/// 统一管理字帖编辑过程中的图像数据保存和加载
class ImageDataManager {
  static const String _tag = 'ImageDataManager';

  /// 准备图像元素进行保存
  /// 自动选择最优的数据存储策略
  static Map<String, dynamic> prepareElementForSave(
      Map<String, dynamic> element) {
    try {
      AppLogger.info('开始准备图像元素进行保存',
          tag: _tag,
          data: {
            'elementId': element['id'],
            'elementType': element['type'],
          });

      if (element['type'] != 'image') {
        AppLogger.warning('元素类型不是图像，跳过处理',
            tag: _tag,
            data: {'elementType': element['type']});
        return element;
      }

      final result = Map<String, dynamic>.from(element);
      final content = result['content'] as Map<String, dynamic>?;

      if (content == null) {
        AppLogger.warning('图像元素缺少content，跳过处理', tag: _tag);
        return element;
      }

      // 应用智能保存策略
      result['content'] =
          ImageDataSaveStrategy.prepareImageDataForSave(content);

      // 验证保存数据
      if (!ImageDataSaveStrategy.validateSaveData(result['content'])) {
        AppLogger.error('保存数据验证失败，使用原始数据',
            tag: _tag,
            data: {'elementId': element['id']});
        return element; // 返回原始数据以避免数据丢失
      }

      AppLogger.info('图像元素保存准备完成',
          tag: _tag,
          data: {
            'elementId': element['id'],
            'optimized': true,
            'finalDataSource': result['content']['finalImageDataSource'],
          });

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('准备图像元素保存失败',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'elementId': element['id']});

      // 发生错误时返回原始元素，确保数据不丢失
      return element;
    }
  }

  /// 从保存的数据恢复图像元素
  /// 自动重建完整的编辑状态
  static Map<String, dynamic> restoreElementFromSave(
      Map<String, dynamic> savedElement) {
    try {
      AppLogger.info('开始恢复图像元素',
          tag: _tag,
          data: {
            'elementId': savedElement['id'],
            'elementType': savedElement['type'],
          });

      if (savedElement['type'] != 'image') {
        AppLogger.warning('元素类型不是图像，跳过处理',
            tag: _tag,
            data: {'elementType': savedElement['type']});
        return savedElement;
      }

      final result = Map<String, dynamic>.from(savedElement);
      final content = result['content'] as Map<String, dynamic>?;

      if (content == null) {
        AppLogger.warning('图像元素缺少content，跳过处理', tag: _tag);
        return savedElement;
      }

      // 检查是否需要恢复（有新格式的数据）
      if (!_needsDataRestore(content)) {
        AppLogger.debug('元素不需要数据恢复',
            tag: _tag,
            data: {'elementId': savedElement['id']});
        return savedElement;
      }

      // 应用智能加载策略
      result['content'] =
          ImageDataLoadStrategy.restoreImageDataFromSave(content);

      // 验证恢复数据
      if (!ImageDataLoadStrategy.validateRestoredData(result['content'])) {
        AppLogger.error('恢复数据验证失败，使用原始数据',
            tag: _tag,
            data: {'elementId': savedElement['id']});
        return savedElement; // 返回原始数据
      }

      AppLogger.info('图像元素恢复完成',
          tag: _tag,
          data: {
            'elementId': savedElement['id'],
            'restored': true,
            'editingCapabilities': {
              'canAdjustBinarization':
                  result['content']['canAdjustBinarization'] ?? false,
              'canAdjustTransform':
                  result['content']['canAdjustTransform'] ?? false,
              'canRevertToOriginal':
                  result['content']['canRevertToOriginal'] ?? false,
            },
          });

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('恢复图像元素失败',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'elementId': savedElement['id']});

      // 发生错误时返回原始元素
      return savedElement;
    }
  }

  /// 批量处理多个图像元素的保存准备
  static List<Map<String, dynamic>> preparePracticeForSave(
      Map<String, dynamic> practice) {
    try {
      AppLogger.info('开始准备字帖进行保存',
          tag: _tag,
          data: {
            'practiceId': practice['id'],
            'elementsCount': (practice['elements'] as List?)?.length ?? 0,
          });

      final elements = practice['elements'] as List<dynamic>? ?? [];
      final result = <Map<String, dynamic>>[];

      int imageElementCount = 0;
      int optimizedCount = 0;

      for (final element in elements) {
        if (element is Map<String, dynamic>) {
          if (element['type'] == 'image') {
            imageElementCount++;
            final optimized = prepareElementForSave(element);
            result.add(optimized);

            // 检查是否真的被优化了
            if (optimized['content']?['finalImageData'] != null) {
              optimizedCount++;
            }
          } else {
            result.add(element);
          }
        }
      }

      AppLogger.info('字帖保存准备完成',
          tag: _tag,
          data: {
            'practiceId': practice['id'],
            'totalElements': elements.length,
            'imageElements': imageElementCount,
            'optimizedElements': optimizedCount,
          });

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('字帖保存准备失败',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'practiceId': practice['id']});

      // 返回原始元素列表
      return (practice['elements'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    }
  }

  /// 批量恢复多个图像元素
  static List<Map<String, dynamic>> restorePracticeFromSave(
      List<dynamic> savedElements) {
    try {
      AppLogger.info('开始恢复字帖元素',
          tag: _tag,
          data: {
            'elementsCount': savedElements.length,
          });

      final result = <Map<String, dynamic>>[];
      int imageElementCount = 0;
      int restoredCount = 0;

      for (final element in savedElements) {
        if (element is Map<String, dynamic>) {
          if (element['type'] == 'image') {
            imageElementCount++;
            final restored = restoreElementFromSave(element);
            result.add(restored);

            // 检查是否真的被恢复了
            if (restored['content']?['isEditingMode'] == true) {
              restoredCount++;
            }
          } else {
            result.add(element);
          }
        }
      }

      AppLogger.info('字帖元素恢复完成',
          tag: _tag,
          data: {
            'totalElements': savedElements.length,
            'imageElements': imageElementCount,
            'restoredElements': restoredCount,
          });

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('字帖元素恢复失败',
          tag: _tag,
          error: e,
          stackTrace: stackTrace);

      // 返回原始元素列表
      return savedElements.cast<Map<String, dynamic>>();
    }
  }

  /// 检查内容是否需要数据恢复
  static bool _needsDataRestore(Map<String, dynamic> content) {
    // 如果有新格式的数据结构，则需要恢复
    return content.containsKey('finalImageData') &&
        content.containsKey('finalImageDataSource') &&
        content.containsKey('processingMetadata');
  }

  /// 获取图像数据使用统计
  static Map<String, dynamic> getImageDataUsageStats(
      List<Map<String, dynamic>> elements) {
    int totalElements = 0;
    int imageElements = 0;
    int optimizedElements = 0;
    int binarizedElements = 0;
    int transformedElements = 0;
    int rawElements = 0;
    int base64Elements = 0;

    int totalOriginalSize = 0;
    int totalOptimizedSize = 0;

    for (final element in elements) {
      if (element['type'] == 'image') {
        totalElements++;
        imageElements++;

        final content = element['content'] as Map<String, dynamic>?;
        if (content == null) continue;

        // 统计原始大小
        _addDataSize(content, 'rawImageData', (size) => totalOriginalSize += size);
        _addDataSize(content, 'base64ImageData', (size) => totalOriginalSize += size ~/ 4 * 3); // Base64解码后大小估计
        _addDataSize(content, 'transformedImageData', (size) => totalOriginalSize += size);
        _addDataSize(content, 'binarizedImageData', (size) => totalOriginalSize += size);

        // 统计优化后的数据
        if (content.containsKey('finalImageData')) {
          optimizedElements++;
          final finalData = content['finalImageData'];
          final finalDataSize = _getDataSize(finalData);
          totalOptimizedSize += finalDataSize;

          // 统计数据类型
          switch (content['finalImageDataSource']) {
            case 'binarizedImageData':
              binarizedElements++;
              break;
            case 'transformedImageData':
              transformedElements++;
              break;
            case 'rawImageData':
              rawElements++;
              break;
            case 'base64ImageData':
              base64Elements++;
              break;
          }
        }
      } else {
        totalElements++;
      }
    }

    final compressionRatio = totalOriginalSize > 0 
        ? (1.0 - totalOptimizedSize / totalOriginalSize) 
        : 0.0;

    return {
      'totalElements': totalElements,
      'imageElements': imageElements,
      'optimizedElements': optimizedElements,
      'compressionRatio': compressionRatio,
      'dataTypeDistribution': {
        'binarized': binarizedElements,
        'transformed': transformedElements,
        'raw': rawElements,
        'base64': base64Elements,
      },
      'sizeStats': {
        'totalOriginalSize': totalOriginalSize,
        'totalOptimizedSize': totalOptimizedSize,
        'savedBytes': totalOriginalSize - totalOptimizedSize,
      },
    };
  }

  /// 辅助方法：添加数据大小到统计
  static void _addDataSize(Map<String, dynamic> content, String key, Function(int) callback) {
    final data = content[key];
    if (data != null) {
      callback(_getDataSize(data));
    }
  }

  /// 辅助方法：获取数据大小
  static int _getDataSize(dynamic data) {
    if (data is List) {
      return data.length;
    } else if (data is String) {
      return data.length;
    } else if (data is Uint8List) {
      return data.length;
    }
    return 0;
  }

  /// 检查系统兼容性
  static bool isSystemCompatible() {
    try {
      // 测试基本的序列化/反序列化
      final testData = {
        'finalImageData': Uint8List.fromList([1, 2, 3]),
        'finalImageDataSource': 'rawImageData',
        'processingMetadata': {'test': true},
      };

      final restored = ImageDataLoadStrategy.restoreImageDataFromSave(testData);
      return restored['rawImageData'] != null;
    } catch (e) {
      AppLogger.error('系统兼容性检查失败', tag: _tag, error: e);
      return false;
    }
  }
}

/// 图像数据管理器的Riverpod提供者
final imageDataManagerProvider = Provider<ImageDataManager>((ref) {
  return ImageDataManager();
});