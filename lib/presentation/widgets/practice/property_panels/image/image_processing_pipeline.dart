import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../../../../application/providers/service_providers.dart';
import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../infrastructure/logging/logger.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/config/edit_page_logging_config.dart';

/// 统一的图像处理管线混合类
/// 实现连续的处理流程：原始图像 → 变换处理 → 二值化处理 → 最终显示
mixin ImageProcessingPipeline {
  /// 获取元素数据
  Map<String, dynamic> get element;

  /// 获取ref
  WidgetRef get ref;

  /// 图像尺寸
  Size? get imageSize;

  /// 渲染尺寸
  Size? get renderSize;

  /// 更新属性
  void updateProperty(String key, dynamic value,
      {bool createUndoOperation = true});

  /// 更新内容属性
  void updateContentProperty(String key, dynamic value,
      {bool createUndoOperation = true});

  /// 更新图像状态
  void updateImageState(Size? imageSize, Size? renderSize);

  /// 🔑 核心方法：执行完整的图像处理管线
  /// 这是唯一的图像处理入口点，确保处理流程的一致性
  Future<void> executeImageProcessingPipeline({
    bool triggerByTransform = false,
    bool triggerByBinarization = false,
    String? changedParameter,
  }) async {
    // 🔧 重要：获取最新的元素状态，而不是缓存的状态
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    final imageUrl = content['imageUrl'] as String? ?? '';

    // 🔍 调试：打印翻转参数状态（翻转现在在画布渲染阶段处理）
    AppLogger.debug('🔍 [处理管线] 开始执行，检查参数状态',
        tag: 'ImageProcessingPipeline',
        data: {
          'flipHandlingNote': '💡 翻转参数现在在画布渲染阶段处理，不影响图像处理管线',
          'triggerByTransform': triggerByTransform
        });

    EditPageLogger.editPageInfo('开始执行图像处理管线',
        tag: EditPageLoggingConfig.tagImagePanel,
        data: {
          'triggerByTransform': triggerByTransform,
          'triggerByBinarization': triggerByBinarization,
          'changedParameter': changedParameter,
          'imageUrl': imageUrl,
          'currentBinarizationState':
              content['isBinarizationEnabled'], // 添加调试信息
          'flipHorizontal': content['isFlippedHorizontally'], // 添加翻转状态调试
          'flipVertical': content['isFlippedVertically'], // 添加翻转状态调试
        });

    if (imageUrl.isEmpty) {
      EditPageLogger.editPageError('图像处理管线失败：图像URL为空',
          tag: EditPageLoggingConfig.tagImagePanel);
      return;
    }

    try {
      // 步骤1：加载原始图像
      Uint8List? originalImageData = await _loadImageFromUrl(imageUrl);
      if (originalImageData == null) {
        EditPageLogger.editPageError('无法加载原始图像',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {'imageUrl': imageUrl});
        return;
      }

      img.Image? sourceImage = img.decodeImage(originalImageData);
      if (sourceImage == null) {
        EditPageLogger.editPageError('无法解码原始图像',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {'imageUrl': imageUrl});
        return;
      }

      EditPageLogger.editPageInfo('成功加载原始图像',
          tag: EditPageLoggingConfig.tagImagePanel,
          data: {
            'imageSize': '${sourceImage.width}x${sourceImage.height}',
            'dataSize': originalImageData.length
          });

      // 步骤2：检查是否需要进行变换处理
      img.Image processedImage = sourceImage;
      bool hasTransformApplied = false;

      if (_shouldApplyTransform(content)) {
        EditPageLogger.editPageInfo('开始图像变换处理',
            tag: EditPageLoggingConfig.tagImagePanel);

        processedImage = await _applyImageTransform(sourceImage, content);
        hasTransformApplied = true;

        // 更新变换后的图像数据
        final transformedImageData =
            Uint8List.fromList(img.encodePng(processedImage));
        content['transformedImageData'] = transformedImageData;
        content['isTransformApplied'] = true;

        EditPageLogger.editPageInfo('图像变换处理完成',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {
              'resultSize': '${processedImage.width}x${processedImage.height}',
              'dataSize': transformedImageData.length
            });
      } else {
        // 🔧 重要修复：当不需要变换时，彻底清除所有变换相关数据
        AppLogger.debug('🔧 清除变换数据（参数为默认值）',
            tag: 'ImageProcessingPipeline',
            data: {
              'transformedImageDataExists':
                  content.containsKey('transformedImageData'),
              'isTransformApplied': content['isTransformApplied']
            });

        // 清除所有可能的变换数据
        final transformDataKeys = [
          'transformedImageData',
          'transformedImageUrl',
          'transformRect',
          // 确保清除旧坐标系统的数据
          'cropTop', 'cropBottom', 'cropLeft', 'cropRight'
        ];

        for (final key in transformDataKeys) {
          if (content.containsKey(key)) {
            AppLogger.debug('移除变换数据键',
                tag: 'ImageProcessingPipeline', data: {'removedKey': key});
            content.remove(key);
          }
        }

        content['isTransformApplied'] = false;

        AppLogger.debug('变换数据清除完成', tag: 'ImageProcessingPipeline', data: {
          'transformedImageDataExists':
              content.containsKey('transformedImageData'),
          'isTransformApplied': content['isTransformApplied'],
          'contentKeys': content.keys.toList()
        });

        EditPageLogger.editPageInfo('跳过图像变换处理（无需变换）- 已清除所有变换数据',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {
              'clearedKeys': transformDataKeys
                  .where((key) => !content.containsKey(key))
                  .toList(),
              'isTransformApplied': false
            });
      }

      // 步骤3：检查是否需要进行二值化处理
      // 🔧 修复：使用当前内容状态，而不是从元素重新读取
      final shouldApplyBinarization =
          content['isBinarizationEnabled'] as bool? ?? false;

      EditPageLogger.editPageInfo('检查二值化处理条件',
          tag: EditPageLoggingConfig.tagImagePanel,
          data: {
            'shouldApplyBinarization': shouldApplyBinarization,
            'triggerByBinarization': triggerByBinarization,
            'contentState': content['isBinarizationEnabled']
          });

      if (shouldApplyBinarization) {
        EditPageLogger.editPageInfo('开始二值化处理',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {'sourceIsTransformed': hasTransformApplied});

        processedImage = await _applyImageBinarization(processedImage, content);

        // 更新二值化后的图像数据
        final binarizedImageData =
            Uint8List.fromList(img.encodePng(processedImage));
        content['binarizedImageData'] = binarizedImageData;

        EditPageLogger.editPageInfo('二值化处理完成',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {
              'resultSize': '${processedImage.width}x${processedImage.height}',
              'dataSize': binarizedImageData.length
            });
      } else {
        // 清除二值化数据
        AppLogger.debug('🔧 二值化已禁用，清除二值化数据 (主处理管线)',
            tag: 'ImageProcessingPipeline',
            data: {
              'binarizedImageDataExists':
                  content.containsKey('binarizedImageData')
            });

        content.remove('binarizedImageData');

        AppLogger.debug('二值化数据清除完成 (主处理管线)',
            tag: 'ImageProcessingPipeline',
            data: {
              'binarizedImageDataExists':
                  content.containsKey('binarizedImageData'),
              'contentKeys': content.keys.toList()
            });

        EditPageLogger.editPageInfo('跳过二值化处理（未启用或已禁用）',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {'binarizationEnabled': shouldApplyBinarization});
      }

      // 步骤4：更新元素内容，触发UI重新渲染
      updateProperty('content', content, createUndoOperation: true);

      EditPageLogger.editPageInfo('图像处理管线执行完成',
          tag: EditPageLoggingConfig.tagImagePanel,
          data: {
            'hasTransform': hasTransformApplied,
            'hasBinarization': shouldApplyBinarization,
            'finalImageSize': '${processedImage.width}x${processedImage.height}'
          });
    } catch (e, stackTrace) {
      EditPageLogger.editPageError('图像处理管线执行失败',
          tag: EditPageLoggingConfig.tagImagePanel,
          error: e,
          stackTrace: stackTrace,
          data: {
            'triggerByTransform': triggerByTransform,
            'triggerByBinarization': triggerByBinarization,
            'changedParameter': changedParameter,
          });
    }
  }

  /// 检查是否需要应用变换
  bool _shouldApplyTransform(Map<String, dynamic> content) {
    final cropX = (content['cropX'] as num?)?.toDouble() ?? 0.0;
    final cropY = (content['cropY'] as num?)?.toDouble() ?? 0.0;
    final cropWidth = (content['cropWidth'] as num?)?.toDouble() ??
        (imageSize?.width ?? 100.0);
    final cropHeight = (content['cropHeight'] as num?)?.toDouble() ??
        (imageSize?.height ?? 100.0);
    // 🔧 移除翻转逻辑 - 翻转现在在画布渲染阶段处理
    // final flipHorizontal = content['isFlippedHorizontally'] as bool? ?? false;
    // final flipVertical = content['isFlippedVertically'] as bool? ?? false;
    final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

    // 检查是否有任何变换操作（移除翻转检查）
    final hasCropping = !(cropX == 0 &&
        cropY == 0 &&
        cropWidth == (imageSize?.width ?? 100.0) &&
        cropHeight == (imageSize?.height ?? 100.0));
    // final hasFlipping = flipHorizontal || flipVertical; // 🔧 移除翻转检查
    final hasRotation = contentRotation != 0.0;

    // 🔧 关键修复：检查是否有已应用的变换需要清除
    final isTransformApplied = content['isTransformApplied'] as bool? ?? false;
    final hasTransformedImageData =
        content.containsKey('transformedImageData') &&
            content['transformedImageData'] != null;

    // 如果当前有变换操作，或者之前有已应用的变换需要清除，都需要重新处理
    final needsTransformProcessing = hasCropping ||
        hasRotation ||
        (isTransformApplied && hasTransformedImageData);

    AppLogger.debug('🔍 _shouldApplyTransform 检查',
        tag: 'ImageProcessingPipeline',
        data: {
          'hasCropping': hasCropping,
          'hasRotation': hasRotation,
          'isTransformApplied': isTransformApplied,
          'hasTransformedImageData': hasTransformedImageData,
          'needsTransformProcessing': needsTransformProcessing,
          'flipProcessingNote': '💡 翻转处理已移至画布渲染阶段'
        });

    return needsTransformProcessing;
  }

  /// 应用图像变换（注意：翻转参数已移除，翻转现在在画布渲染阶段处理）
  Future<img.Image> _applyImageTransform(
      img.Image sourceImage, Map<String, dynamic> content) async {
    final cropX = (content['cropX'] as num?)?.toDouble() ?? 0.0;
    final cropY = (content['cropY'] as num?)?.toDouble() ?? 0.0;
    final cropWidth = (content['cropWidth'] as num?)?.toDouble() ??
        sourceImage.width.toDouble();
    final cropHeight = (content['cropHeight'] as num?)?.toDouble() ??
        sourceImage.height.toDouble();
    // 🔧 移除翻转参数 - 翻转现在在画布渲染阶段处理
    // final flipHorizontal = content['isFlippedHorizontally'] as bool? ?? false;
    // final flipVertical = content['isFlippedVertically'] as bool? ?? false;
    final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

    // 🔍 调试：打印传递给图像处理器的参数
    AppLogger.debug('🔍 [图像变换] 传递给图像处理器的参数',
        tag: 'ImageProcessingPipeline',
        data: {
          'cropRect': '($cropX, $cropY, $cropWidth, $cropHeight)',
          'rotation': contentRotation,
          'flipParameterNote': '💡 翻转参数已移除，现在在画布渲染阶段处理'
        });

    final cropRect = Rect.fromLTWH(cropX, cropY, cropWidth, cropHeight);

    // 注意：翻转参数已移除，现在只处理裁剪和旋转
    return ref.read(imageProcessorProvider).flipThenCropImage(
          sourceImage,
          cropRect,
          (contentRotation / 180) * math.pi,
          flipHorizontal: false, // 🔧 强制设为false，翻转在画布渲染阶段处理
          flipVertical: false, // 🔧 强制设为false，翻转在画布渲染阶段处理
        );
  }

  /// 应用二值化处理
  Future<img.Image> _applyImageBinarization(
      img.Image sourceImage, Map<String, dynamic> content) async {
    final threshold = (content['binaryThreshold'] as num?)?.toDouble() ?? 128.0;
    final isNoiseReductionEnabled =
        content['isNoiseReductionEnabled'] as bool? ?? false;
    final noiseReductionLevel =
        (content['noiseReductionLevel'] as num?)?.toDouble() ?? 3.0;

    final imageProcessor = ref.read(imageProcessorProvider);
    img.Image processedImage = sourceImage;

    // 🔍 调试：输入图像信息
    AppLogger.debug('🎯 二值化处理开始', tag: 'ImageProcessingPipeline', data: {
      'inputImageSize': '${sourceImage.width}x${sourceImage.height}',
      'threshold': threshold,
      'noiseReductionEnabled': isNoiseReductionEnabled,
      'noiseReductionLevel': noiseReductionLevel
    });

    // 先进行降噪处理（如果启用）
    if (isNoiseReductionEnabled && noiseReductionLevel > 0) {
      processedImage =
          imageProcessor.denoiseImage(processedImage, noiseReductionLevel);
      AppLogger.debug('降噪处理完成', tag: 'ImageProcessingPipeline', data: {
        'resultSize': '${processedImage.width}x${processedImage.height}'
      });
      EditPageLogger.editPageInfo('降噪处理完成',
          tag: EditPageLoggingConfig.tagImagePanel,
          data: {'level': noiseReductionLevel});
    }

    // 执行二值化处理
    AppLogger.debug('开始二值化处理', tag: 'ImageProcessingPipeline');
    processedImage =
        imageProcessor.binarizeImage(processedImage, threshold, false);
    AppLogger.debug('二值化处理完成', tag: 'ImageProcessingPipeline', data: {
      'resultSize': '${processedImage.width}x${processedImage.height}'
    });

    // 🔍 调试：检查二值化结果
    // 采样几个像素点来验证二值化效果
    final samplePixels = <String>[];
    const sampleCount = 10;
    for (int i = 0; i < sampleCount; i++) {
      final x = (processedImage.width * i / sampleCount).round();
      final y = (processedImage.height / 2).round();
      if (x < processedImage.width && y < processedImage.height) {
        final pixel = processedImage.getPixel(x, y);
        samplePixels.add('(${pixel.r},${pixel.g},${pixel.b})');
      }
    }
    AppLogger.debug('二值化结果采样',
        tag: 'ImageProcessingPipeline',
        data: {'samplePixels': samplePixels.join(', ')});

    EditPageLogger.editPageInfo('二值化处理完成',
        tag: EditPageLoggingConfig.tagImagePanel,
        data: {
          'threshold': threshold,
          'resultSize': '${processedImage.width}x${processedImage.height}',
          'samplePixels': samplePixels.take(5).join(', ')
        });

    return processedImage;
  }

  /// 从URL加载图像数据
  Future<Uint8List?> _loadImageFromUrl(String imageUrl) async {
    try {
      if (imageUrl.startsWith('file://')) {
        String filePath = imageUrl.substring(7);
        final file = File(filePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        } else {
          EditPageLogger.editPageError('图像文件不存在',
              tag: EditPageLoggingConfig.tagImagePanel,
              data: {'filePath': filePath, 'imageUrl': imageUrl});
          return null;
        }
      } else {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          EditPageLogger.editPageError('HTTP请求获取图像失败',
              tag: EditPageLoggingConfig.tagImagePanel,
              data: {'imageUrl': imageUrl, 'statusCode': response.statusCode});
          return null;
        }
      }
    } catch (e) {
      EditPageLogger.editPageError('加载图像数据失败',
          tag: EditPageLoggingConfig.tagImagePanel,
          error: e,
          data: {'imageUrl': imageUrl});
      return null;
    }
  }

  /// 🔧 向后兼容的方法：应用变换
  void applyTransform(BuildContext context) {
    EditPageLogger.editPageInfo('触发图像变换处理（通过向后兼容接口）',
        tag: EditPageLoggingConfig.tagImagePanel);

    AppLogger.debug('🔍 applyTransform 被调用', tag: 'ImageProcessingPipeline');

    // 🔧 重要修复：在应用变换前检查当前参数状态
    final content = element['content'] as Map<String, dynamic>;
    AppLogger.debug('当前变换参数状态', tag: 'ImageProcessingPipeline', data: {
      'cropX': content['cropX'],
      'cropY': content['cropY'],
      'cropWidth': content['cropWidth'],
      'cropHeight': content['cropHeight'],
      'rotation': content['rotation'],
      'flipH': content['isFlippedHorizontally'],
      'isTransformApplied': content['isTransformApplied']
    });

    // 检查是否需要变换
    final shouldTransform = _shouldApplyTransform(content);
    AppLogger.debug('变换需求检查',
        tag: 'ImageProcessingPipeline',
        data: {'shouldTransform': shouldTransform});

    if (!shouldTransform) {
      AppLogger.debug('💡 参数为默认值，将清除所有变换数据并恢复原始图像',
          tag: 'ImageProcessingPipeline');
    }

    executeImageProcessingPipeline(triggerByTransform: true);
  }

  /// 🔧 向后兼容的方法：处理二值化开关变化
  void handleBinarizationToggle(bool enabled) {
    EditPageLogger.editPageInfo('二值化开关变化（通过向后兼容接口）',
        tag: EditPageLoggingConfig.tagImagePanel, data: {'enabled': enabled});

    AppLogger.debug('🔍 handleBinarizationToggle 被调用',
        tag: 'ImageProcessingPipeline',
        data: {'enabled': enabled, 'elementId': element['id']});

    final currentContent = element['content'] as Map<String, dynamic>;
    AppLogger.debug('二值化状态检查', tag: 'ImageProcessingPipeline', data: {
      'beforeToggle_isBinarizationEnabled':
          currentContent['isBinarizationEnabled']
    });

    // 🔧 关键修复：防止开关自动关闭，确保状态持久化
    AppLogger.debug('🔍 准备更新二值化开关状态',
        tag: 'ImageProcessingPipeline',
        data: {'requestedState': enabled, 'currentState': currentContent['isBinarizationEnabled']});

    // 先记录撤销操作，再执行处理管线
    updateContentProperty('isBinarizationEnabled', enabled,
        createUndoOperation: true);

    // 🔧 增加延迟执行以确保UI状态更新完成
    Future.delayed(const Duration(milliseconds: 30), () async {
      // 再次验证状态是否正确设置
      final verifyContent = element['content'] as Map<String, dynamic>;
      final actualState = verifyContent['isBinarizationEnabled'] as bool? ?? false;
      
      AppLogger.debug('🔍 开关状态验证',
          tag: 'ImageProcessingPipeline',
          data: {
            'requestedState': enabled,
            'actualState': actualState,
            'stateMatches': actualState == enabled
          });

      if (actualState == enabled) {
        AppLogger.debug('🔍 开始执行处理管线 (开关变化)',
            tag: 'ImageProcessingPipeline');

        await _executeImageProcessingPipelineWithContent(
          verifyContent,
          triggerByBinarization: true,
        );

        AppLogger.debug('🔍 处理管线执行完成 (开关变化)',
            tag: 'ImageProcessingPipeline');
      } else {
        AppLogger.warning('⚠️ 开关状态不匹配，重新设置状态',
            tag: 'ImageProcessingPipeline',
            data: {
              'expected': enabled,
              'actual': actualState
            });
        
        // 强制重新设置状态
        updateContentProperty('isBinarizationEnabled', enabled,
            createUndoOperation: false);
      }
    });
  }

  /// 🔧 内部方法：使用指定内容执行处理管线
  Future<void> _executeImageProcessingPipelineWithContent(
      Map<String, dynamic> content,
      {bool triggerByTransform = false,
      bool triggerByBinarization = false,
      String? changedParameter}) async {
    final imageUrl = content['imageUrl'] as String? ?? '';

    EditPageLogger.editPageInfo('开始执行图像处理管线（使用指定内容）',
        tag: EditPageLoggingConfig.tagImagePanel,
        data: {
          'triggerByTransform': triggerByTransform,
          'triggerByBinarization': triggerByBinarization,
          'changedParameter': changedParameter,
          'imageUrl': imageUrl,
          'currentBinarizationState':
              content['isBinarizationEnabled'], // 使用传入的内容
        });

    if (imageUrl.isEmpty) {
      EditPageLogger.editPageError('图像处理管线失败：图像URL为空',
          tag: EditPageLoggingConfig.tagImagePanel);
      return;
    }

    try {
      // 步骤1：加载原始图像
      Uint8List? originalImageData = await _loadImageFromUrl(imageUrl);
      if (originalImageData == null) {
        EditPageLogger.editPageError('无法加载原始图像',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {'imageUrl': imageUrl});
        return;
      }

      img.Image? sourceImage = img.decodeImage(originalImageData);
      if (sourceImage == null) {
        EditPageLogger.editPageError('无法解码原始图像',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {'imageUrl': imageUrl});
        return;
      }

      EditPageLogger.editPageInfo('成功加载原始图像',
          tag: EditPageLoggingConfig.tagImagePanel,
          data: {
            'imageSize': '${sourceImage.width}x${sourceImage.height}',
            'dataSize': originalImageData.length
          });

      // 步骤2：检查是否需要进行变换处理
      img.Image processedImage = sourceImage;
      bool hasTransformApplied = false;

      if (_shouldApplyTransform(content)) {
        EditPageLogger.editPageInfo('开始图像变换处理',
            tag: EditPageLoggingConfig.tagImagePanel);

        processedImage = await _applyImageTransform(sourceImage, content);
        hasTransformApplied = true;

        // 更新变换后的图像数据
        final transformedImageData =
            Uint8List.fromList(img.encodePng(processedImage));
        content['transformedImageData'] = transformedImageData;
        content['isTransformApplied'] = true;

        EditPageLogger.editPageInfo('图像变换处理完成',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {
              'resultSize': '${processedImage.width}x${processedImage.height}',
              'dataSize': transformedImageData.length
            });
      } else {
        // 🔧 重要修复：当不需要变换时，彻底清除所有变换相关数据
        AppLogger.debug('🔧 清除变换数据（参数为默认值）',
            tag: 'ImageProcessingPipeline',
            data: {
              'transformedImageDataExists':
                  content.containsKey('transformedImageData'),
              'isTransformApplied': content['isTransformApplied']
            });

        // 清除所有可能的变换数据
        final transformDataKeys = [
          'transformedImageData',
          'transformedImageUrl',
          'transformRect',
          // 确保清除旧坐标系统的数据
          'cropTop', 'cropBottom', 'cropLeft', 'cropRight'
        ];

        for (final key in transformDataKeys) {
          if (content.containsKey(key)) {
            AppLogger.debug('移除变换数据键',
                tag: 'ImageProcessingPipeline', data: {'removedKey': key});
            content.remove(key);
          }
        }

        content['isTransformApplied'] = false;

        AppLogger.debug('变换数据清除完成', tag: 'ImageProcessingPipeline', data: {
          'transformedImageDataExists':
              content.containsKey('transformedImageData'),
          'isTransformApplied': content['isTransformApplied'],
          'contentKeys': content.keys.toList()
        });

        EditPageLogger.editPageInfo('跳过图像变换处理（无需变换）- 已清除所有变换数据',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {
              'clearedKeys': transformDataKeys
                  .where((key) => !content.containsKey(key))
                  .toList(),
              'isTransformApplied': false
            });
      }

      // 步骤3：检查是否需要进行二值化处理
      final shouldApplyBinarization =
          content['isBinarizationEnabled'] as bool? ?? false;

      EditPageLogger.editPageInfo('检查二值化处理条件',
          tag: EditPageLoggingConfig.tagImagePanel,
          data: {
            'shouldApplyBinarization': shouldApplyBinarization,
            'triggerByBinarization': triggerByBinarization,
            'contentState': content['isBinarizationEnabled']
          });

      if (shouldApplyBinarization) {
        EditPageLogger.editPageInfo('开始二值化处理',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {'sourceIsTransformed': hasTransformApplied});

        processedImage = await _applyImageBinarization(processedImage, content);

        // 更新二值化后的图像数据
        final binarizedImageData =
            Uint8List.fromList(img.encodePng(processedImage));
        content['binarizedImageData'] = binarizedImageData;

        // 🔍 调试：验证二值化数据实际更新
        final dataHash = binarizedImageData.fold(0, (prev, byte) => prev ^ byte.hashCode);
        
        // 🔍 增强调试：采样像素验证二值化效果并计算更多统计信息
        final samplePixels = <String>[];
        int whitePixels = 0;
        int blackPixels = 0;
        const sampleCount = 20; // 增加采样数量
        
        for (int i = 0; i < sampleCount; i++) {
          final x = (processedImage.width * i / sampleCount).round();
          final y = (processedImage.height / 2).round();
          if (x < processedImage.width && y < processedImage.height) {
            final pixel = processedImage.getPixel(x, y);
            samplePixels.add('(${pixel.r},${pixel.g},${pixel.b})');
            // 统计黑白像素
            if (pixel.r > 200 && pixel.g > 200 && pixel.b > 200) {
              whitePixels++;
            } else if (pixel.r < 50 && pixel.g < 50 && pixel.b < 50) {
              blackPixels++;
            }
          }
        }
        
        // 🔍 计算整体图像统计
        int totalWhite = 0;
        int totalBlack = 0;
        final step = math.max(1, (processedImage.width * processedImage.height) ~/ 10000); // 采样1万个像素
        for (int i = 0; i < processedImage.width * processedImage.height; i += step) {
          final x = i % processedImage.width;
          final y = i ~/ processedImage.width;
          final pixel = processedImage.getPixel(x, y);
          if (pixel.r > 200) totalWhite++;
          else if (pixel.r < 50) totalBlack++;
        }
        
        AppLogger.debug('🎯 二值化图像数据已生成 (增强验证)', tag: 'ImageProcessingPipeline', data: {
          'dataSize': '${binarizedImageData.length} bytes',
          'imageSize': '${processedImage.width}x${processedImage.height}',
          'storagePath': 'content[binarizedImageData]',
          'contentKeys': content.keys.toList(),
          'dataHash': dataHash, // 用于验证数据实际变化
          'dataHashHex': dataHash.toRadixString(16), // 十六进制显示更容易看出差异
          'threshold': content['binaryThreshold'], // 使用实际保存的参数值
          'isNoiseReductionEnabled': content['isNoiseReductionEnabled'],
          'noiseReductionLevel': content['noiseReductionLevel'],
          'pixelSample': samplePixels.take(10).join(', '),
          'pixelStats': {
            'sampleWhite': whitePixels,
            'sampleBlack': blackPixels, 
            'sampleOther': sampleCount - whitePixels - blackPixels,
            'totalWhiteApprox': totalWhite,
            'totalBlackApprox': totalBlack,
            'whiteRatio': (totalWhite * 100 / (totalWhite + totalBlack)).toStringAsFixed(1) + '%'
          },
          'processingParams': {
            'threshold': content['binaryThreshold'],
            'noiseReductionEnabled': content['isNoiseReductionEnabled'],
            'noiseLevel': content['isNoiseReductionEnabled'] ? content['noiseReductionLevel'] : 0
          },
          'isBinarizationEnabled': content['isBinarizationEnabled']
        });

        EditPageLogger.editPageInfo('二值化处理完成',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {
              'resultSize': '${processedImage.width}x${processedImage.height}',
              'dataSize': binarizedImageData.length
            });
      } else {
        // 清除二值化数据
        AppLogger.debug('🔧 二值化已禁用，清除二值化数据 (临时处理管线)',
            tag: 'ImageProcessingPipeline',
            data: {
              'binarizedImageDataExists':
                  content.containsKey('binarizedImageData')
            });

        content.remove('binarizedImageData');

        AppLogger.debug('二值化数据清除完成 (主处理管线)',
            tag: 'ImageProcessingPipeline',
            data: {
              'binarizedImageDataExists':
                  content.containsKey('binarizedImageData'),
              'contentKeys': content.keys.toList()
            });

        EditPageLogger.editPageInfo('跳过二值化处理（未启用或已禁用）',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {'binarizationEnabled': shouldApplyBinarization});
      }

      // 步骤4：更新元素内容，触发UI重新渲染
      AppLogger.debug('🔍 准备更新元素内容', tag: 'ImageProcessingPipeline', data: {
        'isBinarizationEnabled': content['isBinarizationEnabled'],
        'binarizedImageDataNotNull': content['binarizedImageData'] != null
      });
      if (content['binarizedImageData'] != null) {
        final data = content['binarizedImageData'] as Uint8List;
        AppLogger.debug('二值化数据状态检查', tag: 'ImageProcessingPipeline', data: {
          'dataSize': data.length,
          'dataType': data.runtimeType.toString(),
          'formatNote': '保持Uint8List格式，确保图像正确显示',
          'finalDataType': content['binarizedImageData'].runtimeType.toString(),
          'finalDataSize': data.length
        });

        // 🔧 保持Uint8List格式，不转换为List<int>
        // content['binarizedImageData'] = data.toList(); // 移除这行转换
      } else {
        AppLogger.debug('💡 binarizedImageData 已被清除，将回退到原始/变换图像',
            tag: 'ImageProcessingPipeline');
      }

      updateProperty('content', content,
          createUndoOperation: false); // 不创建撤销操作，避免状态冲突

      AppLogger.debug('🔍 元素内容已更新', tag: 'ImageProcessingPipeline');

      // 🔧 强制触发UI重建以确保渲染器使用新数据
      if (content['binarizedImageData'] != null) {
        AppLogger.debug('🔍 检测到二值化数据，强制触发UI重建', tag: 'ImageProcessingPipeline');
        // 由于我们无法直接访问setState，依靠handlePropertyChange中的更新机制
      }

      EditPageLogger.editPageInfo('图像处理管线执行完成',
          tag: EditPageLoggingConfig.tagImagePanel,
          data: {
            'hasTransform': hasTransformApplied,
            'hasBinarization': shouldApplyBinarization,
            'finalImageSize': '${processedImage.width}x${processedImage.height}'
          });
    } catch (e, stackTrace) {
      EditPageLogger.editPageError('图像处理管线执行失败',
          tag: EditPageLoggingConfig.tagImagePanel,
          error: e,
          stackTrace: stackTrace,
          data: {
            'triggerByTransform': triggerByTransform,
            'triggerByBinarization': triggerByBinarization,
            'changedParameter': changedParameter,
          });
    }
  }

  /// 🔧 向后兼容的方法：处理二值化参数变化
  void handleBinarizationParameterChange(String parameterName, dynamic value) {
    EditPageLogger.editPageInfo('二值化参数变化（通过向后兼容接口）',
        tag: EditPageLoggingConfig.tagImagePanel,
        data: {'parameter': parameterName, 'value': value});

    AppLogger.debug('🔍 handleBinarizationParameterChange 被调用',
        tag: 'ImageProcessingPipeline',
        data: {'parameter': parameterName, 'value': value});

    // 首先保存参数值
    updateContentProperty(parameterName, value, createUndoOperation: false);

    // 获取更新后的内容以确保参数值已生效
    final content = element['content'] as Map<String, dynamic>;
    final isBinarizationEnabled =
        content['isBinarizationEnabled'] as bool? ?? false;

    // 🔍 增强调试：详细记录参数变化
    AppLogger.debug('🎯 参数变化详情',
        tag: 'ImageProcessingPipeline',
        data: {
          'parameterName': parameterName,
          'newValue': value,
          'actualValueInContent': content[parameterName],
          'currentBinarizationEnabled': isBinarizationEnabled,
          'currentThreshold': content['binaryThreshold'],
          'currentNoiseEnabled': content['isNoiseReductionEnabled'], 
          'currentNoiseLevel': content['noiseReductionLevel'],
          'allContentKeys': content.keys.toList()
        });

    if (isBinarizationEnabled) {
      AppLogger.debug('执行处理管线，参数已保存',
          tag: 'ImageProcessingPipeline',
          data: {'parameter': parameterName, 'value': value});

      // 🔧 关键修复：增加延迟并验证参数状态，确保降噪开关不会自动关闭
      Future.delayed(const Duration(milliseconds: 50), () async {
        // 再次验证参数状态，防止并发修改
        final verifyContent = element['content'] as Map<String, dynamic>;
        final verifyBinarizationEnabled = verifyContent['isBinarizationEnabled'] as bool? ?? false;
        final verifyParameterValue = verifyContent[parameterName];
        
        AppLogger.debug('🔍 处理管线执行前最终验证',
            tag: 'ImageProcessingPipeline',
            data: {
              'verifyBinarizationEnabled': verifyBinarizationEnabled,
              'verifyParameterValue': verifyParameterValue,
              'expectedValue': value,
              'parameterChanged': verifyParameterValue != value,
              'parameterName': parameterName
            });

        if (verifyBinarizationEnabled && verifyParameterValue == value) {
          AppLogger.debug('🚀 开始执行图像处理管线 (参数变化)', 
              tag: 'ImageProcessingPipeline',
              data: {
                'trigger': 'parameter_change',
                'parameter': parameterName,
                'value': value
              });
              
          await executeImageProcessingPipeline(
            triggerByBinarization: true,
            changedParameter: parameterName,
          );

          AppLogger.debug('🔍 参数处理管线执行完成',
              tag: 'ImageProcessingPipeline');
        } else {
          AppLogger.warning('⚠️ 参数状态已改变，跳过处理管线',
              tag: 'ImageProcessingPipeline',
              data: {
                'binarizationEnabled': verifyBinarizationEnabled,
                'parameterStillMatches': verifyParameterValue == value,
                'parameterName': parameterName,
                'expectedValue': value,
                'actualValue': verifyParameterValue
              });
        }
      });
    } else {
      AppLogger.debug('🔧 二值化未启用，跳过处理管线', 
          tag: 'ImageProcessingPipeline',
          data: {'parameter': parameterName, 'value': value});
    }
  }

  /// 🔧 向后兼容的方法：重置变换
  void resetTransform(BuildContext context) {
    AppLogger.debug('🔍 resetTransform 开始执行',
        tag: 'ImageProcessingPipeline', data: {'elementId': element['id']});

    final l10n = AppLocalizations.of(context);
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    AppLogger.debug('重置前参数状态', tag: 'ImageProcessingPipeline', data: {
      'cropX': content['cropX'],
      'cropY': content['cropY'],
      'cropWidth': content['cropWidth'],
      'cropHeight': content['cropHeight'],
      'rotation': content['rotation'],
      'flipParameterNote': '💡 翻转参数现在在画布渲染阶段处理，不在此重置'
    });

    // Reset to new coordinate system defaults (移除翻转重置)
    final resetValues = <String, dynamic>{
      'cropX': 0.0,
      'cropY': 0.0,
      // 🔧 移除翻转重置 - 翻转现在在画布渲染阶段处理
      // 'isFlippedHorizontally': false,
      // 'isFlippedVertically': false,
      'rotation': 0.0,
      'isTransformApplied': false,
    };

    if (imageSize != null) {
      resetValues['cropWidth'] = imageSize!.width;
      resetValues['cropHeight'] = imageSize!.height;
      AppLogger.debug('使用imageSize设置裁剪尺寸',
          tag: 'ImageProcessingPipeline',
          data: {'cropSize': '${imageSize!.width}x${imageSize!.height}'});
    } else {
      resetValues['cropWidth'] = 100.0;
      resetValues['cropHeight'] = 100.0;
      AppLogger.debug('使用默认裁剪尺寸: 100x100', tag: 'ImageProcessingPipeline');
    }

    // Apply reset values
    resetValues.forEach((key, value) {
      content[key] = value;
    });

    // Remove old coordinate system properties if they exist
    final oldPropertiesToRemove = [
      'cropTop', 'cropBottom', 'cropLeft', 'cropRight',
      'transformedImageData', 'transformedImageUrl', 'transformRect',
      // 🔧 重要：确保清除二值化数据，因为它依赖于变换结果
      'binarizedImageData'
    ];

    for (final prop in oldPropertiesToRemove) {
      if (content.containsKey(prop)) {
        AppLogger.debug('移除旧属性',
            tag: 'ImageProcessingPipeline', data: {'removedProperty': prop});
        content.remove(prop);
      }
    }

    AppLogger.debug('重置后参数状态', tag: 'ImageProcessingPipeline', data: {
      'cropX': content['cropX'],
      'cropY': content['cropY'],
      'cropWidth': content['cropWidth'],
      'cropHeight': content['cropHeight'],
      'rotation': content['rotation'],
      'flipParameterNote': '💡 翻转参数保持不变，由画布渲染阶段处理'
    });

    AppLogger.debug(
        '🔍 准备调用updateProperty更新content (createUndoOperation=false)',
        tag: 'ImageProcessingPipeline');
    updateProperty('content', content,
        createUndoOperation: false); // 不创建撤销操作，避免冲突
    AppLogger.debug('🔍 updateProperty调用完成', tag: 'ImageProcessingPipeline');

    // 🔧 关键修复：延迟执行，并添加多重验证
    AppLogger.debug('🔍 准备延迟执行处理管线', tag: 'ImageProcessingPipeline');
    Future.microtask(() async {
      AppLogger.debug('🔍 开始执行处理管线 (重置变换)', tag: 'ImageProcessingPipeline');

      // 验证1：检查参数是否保持重置状态
      final verifyContent = element['content'] as Map<String, dynamic>;
      AppLogger.debug('处理管线执行前验证', tag: 'ImageProcessingPipeline', data: {
        'cropX': verifyContent['cropX'],
        'rotation': verifyContent['rotation']
      });

      // 如果参数已经被修改，重新应用重置值
      bool needsReapply = false;
      for (final entry in resetValues.entries) {
        if (verifyContent[entry.key] != entry.value) {
          AppLogger.warning('⚠️ 参数已被修改', tag: 'ImageProcessingPipeline', data: {
            'paramKey': entry.key,
            'currentValue': verifyContent[entry.key],
            'expectedValue': entry.value
          });
          needsReapply = true;
        }
      }

      if (needsReapply) {
        AppLogger.debug('🔧 重新应用重置值', tag: 'ImageProcessingPipeline');
        final reapplyContent = Map<String, dynamic>.from(verifyContent);
        resetValues.forEach((key, value) {
          reapplyContent[key] = value;
        });
        updateProperty('content', reapplyContent, createUndoOperation: false);

        // 再次验证
        await Future.delayed(const Duration(milliseconds: 10));
        final finalVerifyContent = element['content'] as Map<String, dynamic>;
        AppLogger.debug('重新应用后验证', tag: 'ImageProcessingPipeline', data: {
          'cropX': finalVerifyContent['cropX'],
          'rotation': finalVerifyContent['rotation']
        });
      }

      await executeImageProcessingPipeline(triggerByTransform: true);

      AppLogger.debug('🔍 处理管线执行完成 (重置变换)', tag: 'ImageProcessingPipeline');

      // 验证2：检查处理管线执行后参数是否仍然正确
      final postPipelineContent = element['content'] as Map<String, dynamic>;
      AppLogger.debug('处理管线执行后验证', tag: 'ImageProcessingPipeline', data: {
        'cropX': postPipelineContent['cropX'],
        'rotation': postPipelineContent['rotation']
      });

      bool parametersChanged = false;
      for (final entry in resetValues.entries) {
        if (postPipelineContent[entry.key] != entry.value) {
          AppLogger.error('❌ 处理管线后参数发生变化',
              tag: 'ImageProcessingPipeline',
              data: {
                'paramKey': entry.key,
                'actualValue': postPipelineContent[entry.key],
                'expectedValue': entry.value
              });
          parametersChanged = true;
        }
      }

      if (parametersChanged) {
        AppLogger.warning('🚨 检测到参数在处理管线执行后发生了变化，需要调查回调机制',
            tag: 'ImageProcessingPipeline');

        // 强制再次应用重置值
        AppLogger.debug('🔧 强制再次应用重置值', tag: 'ImageProcessingPipeline');
        final forceResetContent =
            Map<String, dynamic>.from(postPipelineContent);
        resetValues.forEach((key, value) {
          forceResetContent[key] = value;
        });
        updateProperty('content', forceResetContent,
            createUndoOperation: false);
      } else {
        AppLogger.debug('✅ 参数在整个重置过程中保持稳定', tag: 'ImageProcessingPipeline');
      }

      // 显示成功消息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageResetSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    AppLogger.debug('🔍 resetTransform 执行完成', tag: 'ImageProcessingPipeline');
  }
}
