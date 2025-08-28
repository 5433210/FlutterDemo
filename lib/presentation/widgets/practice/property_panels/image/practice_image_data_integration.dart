import '../../../../../infrastructure/logging/logger.dart';
import 'image_data_manager.dart';

/// 字帖服务的图像数据集成扩展
/// 提供与现有PracticeService的无缝集成
mixin PracticeImageDataIntegration {
  static const String _tag = 'PracticeImageDataIntegration';

  /// 准备字帖数据进行保存
  /// 在保存到数据库之前调用，自动优化图像数据
  Map<String, dynamic> preparePracticeDataForSave(
      Map<String, dynamic> practiceData) {
    try {
      AppLogger.info('准备字帖数据进行保存',
          tag: _tag,
          data: {
            'practiceId': practiceData['id'],
            'hasElements': practiceData['elements'] != null,
            'elementsCount': practiceData['elements'] is List
                ? (practiceData['elements'] as List).length
                : 0,
          });

      // 复制原始数据
      final result = Map<String, dynamic>.from(practiceData);

      // 优化图像元素 - 处理页面结构
      if (result['elements'] is List) {
        final pages = result['elements'] as List<dynamic>;
        final optimizedPages = <Map<String, dynamic>>[];
        
        // 收集所有图像元素进行处理
        List<Map<String, dynamic>> allImageElements = [];
        Map<int, List<int>> pageImageIndexMap = {}; // 页面索引 -> 该页面的图像元素在allImageElements中的索引列表
        
        for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
          final page = pages[pageIndex];
          if (page is Map<String, dynamic> && page['elements'] is List) {
            final pageElements = page['elements'] as List<dynamic>;
            List<int> imageIndexesInThisPage = [];
            
            for (int elementIndex = 0; elementIndex < pageElements.length; elementIndex++) {
              final element = pageElements[elementIndex];
              if (element is Map<String, dynamic> && element['type'] == 'image') {
                allImageElements.add(element);
                imageIndexesInThisPage.add(allImageElements.length - 1);
              }
            }
            
            pageImageIndexMap[pageIndex] = imageIndexesInThisPage;
          }
        }
        
        // 如果有图像元素，进行批量优化
        List<Map<String, dynamic>> optimizedImageElements = [];
        if (allImageElements.isNotEmpty) {
          // 构建临时练习数据结构供ImageDataManager处理
          final tempPracticeData = {
            'id': practiceData['id'],
            'elements': allImageElements,
          };
          optimizedImageElements = ImageDataManager.preparePracticeForSave(tempPracticeData);
          
          AppLogger.info('图像元素批量优化完成',
              tag: _tag,
              data: {
                'practiceId': practiceData['id'],
                'originalImageCount': allImageElements.length,
                'optimizedImageCount': optimizedImageElements.length,
              });
        }
        
        // 重新构建页面结构，替换优化后的图像元素
        for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
          final page = pages[pageIndex];
          if (page is Map<String, dynamic>) {
            final optimizedPage = Map<String, dynamic>.from(page);
            
            if (page['elements'] is List) {
              final pageElements = page['elements'] as List<dynamic>;
              final optimizedPageElements = <Map<String, dynamic>>[];
              int imageElementIndex = 0;
              
              for (int elementIndex = 0; elementIndex < pageElements.length; elementIndex++) {
                final element = pageElements[elementIndex];
                if (element is Map<String, dynamic>) {
                  if (element['type'] == 'image') {
                    // 使用优化后的图像元素
                    final imageIndexesInThisPage = pageImageIndexMap[pageIndex] ?? [];
                    if (imageElementIndex < imageIndexesInThisPage.length && 
                        imageIndexesInThisPage[imageElementIndex] < optimizedImageElements.length) {
                      optimizedPageElements.add(optimizedImageElements[imageIndexesInThisPage[imageElementIndex]]);
                    } else {
                      // 备用方案：使用原始元素
                      optimizedPageElements.add(element);
                    }
                    imageElementIndex++;
                  } else {
                    // 非图像元素直接添加
                    optimizedPageElements.add(element);
                  }
                }
              }
              
              optimizedPage['elements'] = optimizedPageElements;
            }
            
            optimizedPages.add(optimizedPage);
          }
        }
        
        result['elements'] = optimizedPages;

        // 记录优化统计信息
        _logOptimizationStats(optimizedImageElements, practiceData['id']);
      }

      AppLogger.info('字帖数据保存准备完成',
          tag: _tag,
          data: {'practiceId': practiceData['id']});

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('字帖数据保存准备失败',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'practiceId': practiceData['id']});

      // 返回原始数据以确保保存不会失败
      return practiceData;
    }
  }

  /// 从保存的数据恢复字帖数据
  /// 从数据库加载后调用，自动恢复图像编辑状态
  Map<String, dynamic> restorePracticeDataFromSave(
      Map<String, dynamic> savedData) {
    try {
      AppLogger.info('从保存数据恢复字帖',
          tag: _tag,
          data: {
            'practiceId': savedData['id'],
            'hasElements': savedData['elements'] != null,
            'elementsCount': savedData['elements'] is List
                ? (savedData['elements'] as List).length
                : 0,
          });

      // 复制保存的数据
      final result = Map<String, dynamic>.from(savedData);

      // 恢复图像元素 - 处理页面结构
      if (result['elements'] is List) {
        final pages = result['elements'] as List<dynamic>;
        final restoredPages = <Map<String, dynamic>>[];
        
        // 收集所有图像元素进行恢复
        List<Map<String, dynamic>> allImageElements = [];
        Map<int, List<int>> pageImageIndexMap = {}; // 页面索引 -> 该页面的图像元素在allImageElements中的索引列表
        
        for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
          final page = pages[pageIndex];
          if (page is Map<String, dynamic> && page['elements'] is List) {
            final pageElements = page['elements'] as List<dynamic>;
            List<int> imageIndexesInThisPage = [];
            
            for (int elementIndex = 0; elementIndex < pageElements.length; elementIndex++) {
              final element = pageElements[elementIndex];
              if (element is Map<String, dynamic> && element['type'] == 'image') {
                allImageElements.add(element);
                imageIndexesInThisPage.add(allImageElements.length - 1);
              }
            }
            
            pageImageIndexMap[pageIndex] = imageIndexesInThisPage;
          }
        }
        
        // 如果有图像元素，进行批量恢复
        List<Map<String, dynamic>> restoredImageElements = [];
        if (allImageElements.isNotEmpty) {
          restoredImageElements = ImageDataManager.restorePracticeFromSave(allImageElements);
          
          AppLogger.info('图像元素批量恢复完成',
              tag: _tag,
              data: {
                'practiceId': savedData['id'],
                'originalImageCount': allImageElements.length,
                'restoredImageCount': restoredImageElements.length,
              });
        }
        
        // 重新构建页面结构，替换恢复后的图像元素
        for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
          final page = pages[pageIndex];
          if (page is Map<String, dynamic>) {
            final restoredPage = Map<String, dynamic>.from(page);
            
            if (page['elements'] is List) {
              final pageElements = page['elements'] as List<dynamic>;
              final restoredPageElements = <Map<String, dynamic>>[];
              int imageElementIndex = 0;
              
              for (int elementIndex = 0; elementIndex < pageElements.length; elementIndex++) {
                final element = pageElements[elementIndex];
                if (element is Map<String, dynamic>) {
                  if (element['type'] == 'image') {
                    // 使用恢复后的图像元素
                    final imageIndexesInThisPage = pageImageIndexMap[pageIndex] ?? [];
                    if (imageElementIndex < imageIndexesInThisPage.length && 
                        imageIndexesInThisPage[imageElementIndex] < restoredImageElements.length) {
                      restoredPageElements.add(restoredImageElements[imageIndexesInThisPage[imageElementIndex]]);
                    } else {
                      // 备用方案：使用原始元素
                      restoredPageElements.add(element);
                    }
                    imageElementIndex++;
                  } else {
                    // 非图像元素直接添加
                    restoredPageElements.add(element);
                  }
                }
              }
              
              restoredPage['elements'] = restoredPageElements;
            }
            
            restoredPages.add(restoredPage);
          }
        }
        
        result['elements'] = restoredPages;

        // 记录恢复统计信息
        _logRestorationStats(restoredImageElements, savedData['id']);
      }

      AppLogger.info('字帖数据恢复完成',
          tag: _tag,
          data: {'practiceId': savedData['id']});

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('字帖数据恢复失败',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'practiceId': savedData['id']});

      // 返回原始数据
      return savedData;
    }
  }

  /// 验证字帖数据的图像完整性
  bool validatePracticeImageData(Map<String, dynamic> practiceData) {
    try {
      final elements = practiceData['elements'] as List<dynamic>? ?? [];
      int imageElementCount = 0;
      int validImageElements = 0;

      for (final element in elements) {
        if (element is Map<String, dynamic> && element['type'] == 'image') {
          imageElementCount++;

          final content = element['content'] as Map<String, dynamic>?;
          if (content == null) continue;

          // 检查是否有任何有效的图像数据
          final hasValidImageData = content['finalImageData'] != null ||
              content['binarizedImageData'] != null ||
              content['transformedImageData'] != null ||
              content['rawImageData'] != null ||
              content['base64ImageData'] != null ||
              (content['imageUrl'] != null &&
                  (content['imageUrl'] as String).isNotEmpty);

          if (hasValidImageData) {
            validImageElements++;
          }
        }
      }

      final isValid = imageElementCount == 0 || validImageElements > 0;

      AppLogger.info('字帖图像数据完整性检查',
          tag: _tag,
          data: {
            'practiceId': practiceData['id'],
            'imageElementCount': imageElementCount,
            'validImageElements': validImageElements,
            'isValid': isValid,
          });

      return isValid;
    } catch (e) {
      AppLogger.error('字帖图像数据完整性检查失败',
          tag: _tag,
          error: e,
          data: {'practiceId': practiceData['id']});
      return false;
    }
  }

  /// 获取字帖的存储优化报告
  Map<String, dynamic> getPracticeStorageReport(
      Map<String, dynamic> practiceData) {
    try {
      final elements = practiceData['elements'] as List<dynamic>? ?? [];
      final elementMaps = elements
          .whereType<Map<String, dynamic>>()
          .toList();

      final stats = ImageDataManager.getImageDataUsageStats(elementMaps);

      final report = {
        'practiceId': practiceData['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'elementStats': stats,
        'recommendations': _generateOptimizationRecommendations(stats),
        'healthScore': _calculateHealthScore(stats),
      };

      AppLogger.debug('生成字帖存储报告',
          tag: _tag,
          data: {
            'practiceId': practiceData['id'],
            'healthScore': report['healthScore'],
          });

      return report;
    } catch (e) {
      AppLogger.error('生成字帖存储报告失败',
          tag: _tag,
          error: e,
          data: {'practiceId': practiceData['id']});

      return {
        'practiceId': practiceData['id'],
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 记录优化统计信息
  void _logOptimizationStats(
      List<Map<String, dynamic>> elements, String? practiceId) {
    final stats = ImageDataManager.getImageDataUsageStats(elements);

    AppLogger.info('字帖保存优化统计',
        tag: _tag,
        data: {
          'practiceId': practiceId,
          'totalElements': stats['totalElements'],
          'imageElements': stats['imageElements'],
          'optimizedElements': stats['optimizedElements'],
          'compressionRatio': stats['compressionRatio'],
          'savedBytes': stats['sizeStats']['savedBytes'],
          'dataTypeDistribution': stats['dataTypeDistribution'],
        });
  }

  /// 记录恢复统计信息
  void _logRestorationStats(
      List<Map<String, dynamic>> elements, String? practiceId) {
    int imageElementCount = 0;
    int editableElements = 0;
    int elementsWithMissingOriginals = 0;

    for (final element in elements) {
      if (element['type'] == 'image') {
        imageElementCount++;

        final content = element['content'] as Map<String, dynamic>?;
        if (content != null) {
          if (content['isEditingMode'] == true) {
            editableElements++;
          }
          if (content['originalImageAvailable'] == false) {
            elementsWithMissingOriginals++;
          }
        }
      }
    }

    AppLogger.info('字帖恢复统计',
        tag: _tag,
        data: {
          'practiceId': practiceId,
          'imageElementCount': imageElementCount,
          'editableElements': editableElements,
          'elementsWithMissingOriginals': elementsWithMissingOriginals,
          'editabilityRatio': imageElementCount > 0
              ? editableElements / imageElementCount
              : 1.0,
        });
  }

  /// 生成优化建议
  List<String> _generateOptimizationRecommendations(
      Map<String, dynamic> stats) {
    final recommendations = <String>[];

    final compressionRatio = stats['compressionRatio'] as double? ?? 0.0;
    final optimizedElements = stats['optimizedElements'] as int? ?? 0;
    final imageElements = stats['imageElements'] as int? ?? 0;

    if (compressionRatio < 0.3 && imageElements > 0) {
      recommendations.add('考虑对更多图像应用二值化处理以减少存储空间');
    }

    if (optimizedElements < imageElements) {
      final unoptimized = imageElements - optimizedElements;
      recommendations
          .add('有 $unoptimized 个图像元素尚未优化，建议检查其处理状态');
    }

    final totalSize = stats['sizeStats']['totalOptimizedSize'] as int? ?? 0;
    if (totalSize > 10 * 1024 * 1024) {
      // 大于10MB
      recommendations.add('字帖总大小较大（${(totalSize / 1024 / 1024).toStringAsFixed(1)}MB），建议进一步优化图像质量');
    }

    if (recommendations.isEmpty) {
      recommendations.add('存储已充分优化');
    }

    return recommendations;
  }

  /// 计算健康评分
  double _calculateHealthScore(Map<String, dynamic> stats) {
    double score = 100.0;

    final compressionRatio = stats['compressionRatio'] as double? ?? 0.0;
    final optimizedElements = stats['optimizedElements'] as int? ?? 0;
    final imageElements = stats['imageElements'] as int? ?? 0;

    // 压缩率评分（权重：40%）
    score -= (1.0 - compressionRatio) * 40;

    // 优化覆盖率评分（权重：30%）
    if (imageElements > 0) {
      final optimizationRate = optimizedElements / imageElements;
      score -= (1.0 - optimizationRate) * 30;
    }

    // 大小评分（权重：30%）
    final totalSize = stats['sizeStats']['totalOptimizedSize'] as int? ?? 0;
    if (totalSize > 5 * 1024 * 1024) {
      // 超过5MB扣分
      score -= 30 * (totalSize / (10 * 1024 * 1024)).clamp(0.0, 1.0);
    }

    return score.clamp(0.0, 100.0);
  }

  /// 检查是否需要升级数据格式
  bool needsDataFormatUpgrade(Map<String, dynamic> practiceData) {
    final elements = practiceData['elements'] as List<dynamic>? ?? [];

    for (final element in elements) {
      if (element is Map<String, dynamic> && element['type'] == 'image') {
        final content = element['content'] as Map<String, dynamic>?;
        if (content == null) continue;

        // 如果有旧格式的冗余数据，建议升级
        final hasRedundantData = content['rawImageData'] != null &&
            content['transformedImageData'] != null &&
            content['binarizedImageData'] != null;

        if (hasRedundantData && !content.containsKey('finalImageData')) {
          return true;
        }
      }
    }

    return false;
  }

  /// 执行数据格式升级
  Map<String, dynamic> upgradeDataFormat(Map<String, dynamic> practiceData) {
    AppLogger.info('执行字帖数据格式升级',
        tag: _tag,
        data: {'practiceId': practiceData['id']});

    // 先准备保存（这会应用新格式）
    final prepared = preparePracticeDataForSave(practiceData);

    // 然后立即恢复（这会重建编辑状态）
    final upgraded = restorePracticeDataFromSave(prepared);

    AppLogger.info('数据格式升级完成',
        tag: _tag,
        data: {'practiceId': practiceData['id']});

    return upgraded;
  }
}