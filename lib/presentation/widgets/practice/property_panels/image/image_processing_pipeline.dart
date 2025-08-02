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
  void updateProperty(String key, dynamic value, {bool createUndoOperation = true});

  /// 更新内容属性
  void updateContentProperty(String key, dynamic value, {bool createUndoOperation = true});

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
    final content = Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    final imageUrl = content['imageUrl'] as String? ?? '';
    
    EditPageLogger.editPageInfo(
      '开始执行图像处理管线',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
      data: {
        'triggerByTransform': triggerByTransform,
        'triggerByBinarization': triggerByBinarization,
        'changedParameter': changedParameter,
        'imageUrl': imageUrl,
        'currentBinarizationState': content['isBinarizationEnabled'], // 添加调试信息
      }
    );

    if (imageUrl.isEmpty) {
      EditPageLogger.editPageError(
        '图像处理管线失败：图像URL为空',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL
      );
      return;
    }

    try {
      // 步骤1：加载原始图像
      Uint8List? originalImageData = await _loadImageFromUrl(imageUrl);
      if (originalImageData == null) {
        EditPageLogger.editPageError(
          '无法加载原始图像',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'imageUrl': imageUrl}
        );
        return;
      }

      img.Image? sourceImage = img.decodeImage(originalImageData);
      if (sourceImage == null) {
        EditPageLogger.editPageError(
          '无法解码原始图像',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'imageUrl': imageUrl}
        );
        return;
      }

      EditPageLogger.editPageInfo(
        '成功加载原始图像',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {
          'imageSize': '${sourceImage.width}x${sourceImage.height}',
          'dataSize': originalImageData.length
        }
      );

      // 步骤2：检查是否需要进行变换处理
      img.Image processedImage = sourceImage;
      bool hasTransformApplied = false;

      if (_shouldApplyTransform(content)) {
        EditPageLogger.editPageInfo(
          '开始图像变换处理',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL
        );
        
        processedImage = await _applyImageTransform(sourceImage, content);
        hasTransformApplied = true;
        
        // 更新变换后的图像数据
        final transformedImageData = Uint8List.fromList(img.encodePng(processedImage));
        content['transformedImageData'] = transformedImageData;
        content['isTransformApplied'] = true;
        
        EditPageLogger.editPageInfo(
          '图像变换处理完成',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {
            'resultSize': '${processedImage.width}x${processedImage.height}',
            'dataSize': transformedImageData.length
          }
        );
      } else {
        // 🔧 重要修复：当不需要变换时，彻底清除所有变换相关数据
        print('🔧 清除变换数据（参数为默认值）');
        print('  - 清除前 transformedImageData 存在: ${content.containsKey('transformedImageData')}');
        print('  - 清除前 isTransformApplied: ${content['isTransformApplied']}');
        
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
            print('  - 移除 $key');
            content.remove(key);
          }
        }
        
        content['isTransformApplied'] = false;
        
        print('  - 清除后 transformedImageData 存在: ${content.containsKey('transformedImageData')}');
        print('  - 清除后 isTransformApplied: ${content['isTransformApplied']}');
        print('  - 清除后 content keys: ${content.keys.toList()}');
        
        EditPageLogger.editPageInfo(
          '跳过图像变换处理（无需变换）- 已清除所有变换数据',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {
            'clearedKeys': transformDataKeys.where((key) => !content.containsKey(key)).toList(),
            'isTransformApplied': false
          }
        );
      }

      // 步骤3：检查是否需要进行二值化处理
      // 🔧 修复：使用当前内容状态，而不是从元素重新读取
      final shouldApplyBinarization = content['isBinarizationEnabled'] as bool? ?? false;
      
      EditPageLogger.editPageInfo(
        '检查二值化处理条件',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {
          'shouldApplyBinarization': shouldApplyBinarization,
          'triggerByBinarization': triggerByBinarization,
          'contentState': content['isBinarizationEnabled']
        }
      );
      
      if (shouldApplyBinarization) {
        EditPageLogger.editPageInfo(
          '开始二值化处理',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'sourceIsTransformed': hasTransformApplied}
        );
        
        processedImage = await _applyImageBinarization(processedImage, content);
        
        // 更新二值化后的图像数据
        final binarizedImageData = Uint8List.fromList(img.encodePng(processedImage));
        content['binarizedImageData'] = binarizedImageData;
        
        EditPageLogger.editPageInfo(
          '二值化处理完成',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {
            'resultSize': '${processedImage.width}x${processedImage.height}',
            'dataSize': binarizedImageData.length
          }
        );
      } else {
        // 清除二值化数据
        print('🔧 二值化已禁用，清除二值化数据 (主处理管线)');
        print('  - 清除前 binarizedImageData 存在: ${content.containsKey('binarizedImageData')}');
        
        content.remove('binarizedImageData');
        
        print('  - 清除后 binarizedImageData 存在: ${content.containsKey('binarizedImageData')}');
        print('  - content keys: ${content.keys.toList()}');
        
        EditPageLogger.editPageInfo(
          '跳过二值化处理（未启用或已禁用）',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'binarizationEnabled': shouldApplyBinarization}
        );
      }

      // 步骤4：更新元素内容，触发UI重新渲染
      updateProperty('content', content, createUndoOperation: true);
      
      EditPageLogger.editPageInfo(
        '图像处理管线执行完成',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {
          'hasTransform': hasTransformApplied,
          'hasBinarization': shouldApplyBinarization,
          'finalImageSize': '${processedImage.width}x${processedImage.height}'
        }
      );

    } catch (e, stackTrace) {
      EditPageLogger.editPageError(
        '图像处理管线执行失败',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        error: e,
        stackTrace: stackTrace,
        data: {
          'triggerByTransform': triggerByTransform,
          'triggerByBinarization': triggerByBinarization,
          'changedParameter': changedParameter,
        }
      );
    }
  }

  /// 检查是否需要应用变换
  bool _shouldApplyTransform(Map<String, dynamic> content) {
    final cropX = (content['cropX'] as num?)?.toDouble() ?? 0.0;
    final cropY = (content['cropY'] as num?)?.toDouble() ?? 0.0;
    final cropWidth = (content['cropWidth'] as num?)?.toDouble() ?? (imageSize?.width ?? 100.0);
    final cropHeight = (content['cropHeight'] as num?)?.toDouble() ?? (imageSize?.height ?? 100.0);
    final flipHorizontal = content['isFlippedHorizontally'] as bool? ?? false;
    final flipVertical = content['isFlippedVertically'] as bool? ?? false;
    final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

    // 检查是否有任何变换操作
    final hasCropping = !(cropX == 0 && cropY == 0 && 
                         cropWidth == (imageSize?.width ?? 100.0) && 
                         cropHeight == (imageSize?.height ?? 100.0));
    final hasFlipping = flipHorizontal || flipVertical;
    final hasRotation = contentRotation != 0.0;

    return hasCropping || hasFlipping || hasRotation;
  }

  /// 检查是否需要应用二值化
  bool _shouldApplyBinarization(Map<String, dynamic> content) {
    return content['isBinarizationEnabled'] as bool? ?? false;
  }

  /// 应用图像变换
  Future<img.Image> _applyImageTransform(img.Image sourceImage, Map<String, dynamic> content) async {
    final cropX = (content['cropX'] as num?)?.toDouble() ?? 0.0;
    final cropY = (content['cropY'] as num?)?.toDouble() ?? 0.0;
    final cropWidth = (content['cropWidth'] as num?)?.toDouble() ?? sourceImage.width.toDouble();
    final cropHeight = (content['cropHeight'] as num?)?.toDouble() ?? sourceImage.height.toDouble();
    final flipHorizontal = content['isFlippedHorizontally'] as bool? ?? false;
    final flipVertical = content['isFlippedVertically'] as bool? ?? false;
    final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

    final cropRect = Rect.fromLTWH(cropX, cropY, cropWidth, cropHeight);
    
    return ref.read(imageProcessorProvider).flipThenCropImage(
      sourceImage,
      cropRect,
      (contentRotation / 180) * math.pi,
      flipHorizontal: flipHorizontal,
      flipVertical: flipVertical,
    );
  }

  /// 应用二值化处理
  Future<img.Image> _applyImageBinarization(img.Image sourceImage, Map<String, dynamic> content) async {
    final threshold = (content['binaryThreshold'] as num?)?.toDouble() ?? 128.0;
    final isNoiseReductionEnabled = content['isNoiseReductionEnabled'] as bool? ?? false;
    final noiseReductionLevel = (content['noiseReductionLevel'] as num?)?.toDouble() ?? 3.0;

    final imageProcessor = ref.read(imageProcessorProvider);
    img.Image processedImage = sourceImage;

    // 🔍 调试：输入图像信息
    print('🎯 二值化处理开始');
    print('  - 输入图像尺寸: ${sourceImage.width}x${sourceImage.height}');
    print('  - 阈值: $threshold');
    print('  - 降噪开启: $isNoiseReductionEnabled');
    print('  - 降噪强度: $noiseReductionLevel');

    // 先进行降噪处理（如果启用）
    if (isNoiseReductionEnabled && noiseReductionLevel > 0) {
      processedImage = imageProcessor.denoiseImage(processedImage, noiseReductionLevel);
      print('  - 降噪处理完成: ${processedImage.width}x${processedImage.height}');
      EditPageLogger.editPageInfo(
        '降噪处理完成',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {'level': noiseReductionLevel}
      );
    }

    // 执行二值化处理
    print('  - 开始二值化处理');
    processedImage = imageProcessor.binarizeImage(processedImage, threshold, false);
    print('  - 二值化处理完成: ${processedImage.width}x${processedImage.height}');
    
    // 🔍 调试：检查二值化结果
    // 采样几个像素点来验证二值化效果
    final samplePixels = <String>[];
    final sampleCount = 10;
    for (int i = 0; i < sampleCount; i++) {
      final x = (processedImage.width * i / sampleCount).round();
      final y = (processedImage.height / 2).round();
      if (x < processedImage.width && y < processedImage.height) {
        final pixel = processedImage.getPixel(x, y);
        samplePixels.add('(${pixel.r},${pixel.g},${pixel.b})');
      }
    }
    print('  - 采样像素值: ${samplePixels.join(', ')}');
    
    EditPageLogger.editPageInfo(
      '二值化处理完成',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
      data: {
        'threshold': threshold,
        'resultSize': '${processedImage.width}x${processedImage.height}',
        'samplePixels': samplePixels.take(5).join(', ')
      }
    );

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
          EditPageLogger.editPageError(
            '图像文件不存在',
            tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
            data: {'filePath': filePath, 'imageUrl': imageUrl}
          );
          return null;
        }
      } else {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          EditPageLogger.editPageError(
            'HTTP请求获取图像失败',
            tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
            data: {'imageUrl': imageUrl, 'statusCode': response.statusCode}
          );
          return null;
        }
      }
    } catch (e) {
      EditPageLogger.editPageError(
        '加载图像数据失败',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        error: e,
        data: {'imageUrl': imageUrl}
      );
      return null;
    }
  }

  /// 🔧 向后兼容的方法：应用变换
  void applyTransform(BuildContext context) {
    EditPageLogger.editPageInfo(
      '触发图像变换处理（通过向后兼容接口）',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL
    );
    
    print('🔍 applyTransform 被调用');
    
    // 🔧 重要修复：在应用变换前检查当前参数状态
    final content = element['content'] as Map<String, dynamic>;
    print('  - 当前变换参数: cropX=${content['cropX']}, cropY=${content['cropY']}');
    print('  - 当前变换参数: cropWidth=${content['cropWidth']}, cropHeight=${content['cropHeight']}');
    print('  - 当前变换参数: rotation=${content['rotation']}, flipH=${content['isFlippedHorizontally']}');
    print('  - 当前应用状态: isTransformApplied=${content['isTransformApplied']}');
    
    // 检查是否需要变换
    final shouldTransform = _shouldApplyTransform(content);
    print('  - 是否需要应用变换: $shouldTransform');
    
    if (!shouldTransform) {
      print('  - 💡 参数为默认值，将清除所有变换数据并恢复原始图像');
    }
    
    executeImageProcessingPipeline(triggerByTransform: true);
  }

  /// 🔧 向后兼容的方法：处理二值化开关变化
  void handleBinarizationToggle(bool enabled) {
    EditPageLogger.editPageInfo(
      '二值化开关变化（通过向后兼容接口）',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
      data: {'enabled': enabled}
    );

    print('🔍 handleBinarizationToggle 被调用');
    print('  - enabled: $enabled');
    print('  - 当前元素ID: ${element['id']}');
    
    final currentContent = element['content'] as Map<String, dynamic>;
    print('  - 调用前 isBinarizationEnabled: ${currentContent['isBinarizationEnabled']}');

    // 🔧 关键修复：创建包含新状态的临时content并立即执行处理管线
    final updatedContent = Map<String, dynamic>.from(currentContent);
    updatedContent['isBinarizationEnabled'] = enabled;
    
    print('  - 临时更新后 content[isBinarizationEnabled]: ${updatedContent['isBinarizationEnabled']}');
    
    // 立即执行处理管线，使用临时更新的content
    Future.microtask(() async {
      print('🔍 开始执行处理管线 (开关变化，使用临时content)');
      
      // 使用临时content执行处理管线
      await _executeImageProcessingPipelineWithContent(
        updatedContent,
        triggerByBinarization: true,
      );
      
      // 🔧 关键修复：不再调用updateContentProperty，因为处理管线已经更新了完整的content
      // updateContentProperty('isBinarizationEnabled', enabled, createUndoOperation: true);
      
      print('🔍 处理管线执行完成 (开关变化) - 已跳过updateContentProperty以保留二值化数据');
    });
  }
  
  /// 🔧 内部方法：使用指定内容执行处理管线
  Future<void> _executeImageProcessingPipelineWithContent(
    Map<String, dynamic> content,
    {bool triggerByTransform = false,
     bool triggerByBinarization = false,
     String? changedParameter}
  ) async {
    final imageUrl = content['imageUrl'] as String? ?? '';
    
    EditPageLogger.editPageInfo(
      '开始执行图像处理管线（使用指定内容）',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
      data: {
        'triggerByTransform': triggerByTransform,
        'triggerByBinarization': triggerByBinarization,
        'changedParameter': changedParameter,
        'imageUrl': imageUrl,
        'currentBinarizationState': content['isBinarizationEnabled'], // 使用传入的内容
      }
    );

    if (imageUrl.isEmpty) {
      EditPageLogger.editPageError(
        '图像处理管线失败：图像URL为空',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL
      );
      return;
    }

    try {
      // 步骤1：加载原始图像
      Uint8List? originalImageData = await _loadImageFromUrl(imageUrl);
      if (originalImageData == null) {
        EditPageLogger.editPageError(
          '无法加载原始图像',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'imageUrl': imageUrl}
        );
        return;
      }

      img.Image? sourceImage = img.decodeImage(originalImageData);
      if (sourceImage == null) {
        EditPageLogger.editPageError(
          '无法解码原始图像',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'imageUrl': imageUrl}
        );
        return;
      }

      EditPageLogger.editPageInfo(
        '成功加载原始图像',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {
          'imageSize': '${sourceImage.width}x${sourceImage.height}',
          'dataSize': originalImageData.length
        }
      );

      // 步骤2：检查是否需要进行变换处理
      img.Image processedImage = sourceImage;
      bool hasTransformApplied = false;

      if (_shouldApplyTransform(content)) {
        EditPageLogger.editPageInfo(
          '开始图像变换处理',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL
        );
        
        processedImage = await _applyImageTransform(sourceImage, content);
        hasTransformApplied = true;
        
        // 更新变换后的图像数据
        final transformedImageData = Uint8List.fromList(img.encodePng(processedImage));
        content['transformedImageData'] = transformedImageData;
        content['isTransformApplied'] = true;
        
        EditPageLogger.editPageInfo(
          '图像变换处理完成',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {
            'resultSize': '${processedImage.width}x${processedImage.height}',
            'dataSize': transformedImageData.length
          }
        );
      } else {
        // 🔧 重要修复：当不需要变换时，彻底清除所有变换相关数据
        print('🔧 清除变换数据（参数为默认值）');
        print('  - 清除前 transformedImageData 存在: ${content.containsKey('transformedImageData')}');
        print('  - 清除前 isTransformApplied: ${content['isTransformApplied']}');
        
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
            print('  - 移除 $key');
            content.remove(key);
          }
        }
        
        content['isTransformApplied'] = false;
        
        print('  - 清除后 transformedImageData 存在: ${content.containsKey('transformedImageData')}');
        print('  - 清除后 isTransformApplied: ${content['isTransformApplied']}');
        print('  - 清除后 content keys: ${content.keys.toList()}');
        
        EditPageLogger.editPageInfo(
          '跳过图像变换处理（无需变换）- 已清除所有变换数据',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {
            'clearedKeys': transformDataKeys.where((key) => !content.containsKey(key)).toList(),
            'isTransformApplied': false
          }
        );
      }

      // 步骤3：检查是否需要进行二值化处理
      final shouldApplyBinarization = content['isBinarizationEnabled'] as bool? ?? false;
      
      EditPageLogger.editPageInfo(
        '检查二值化处理条件',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {
          'shouldApplyBinarization': shouldApplyBinarization,
          'triggerByBinarization': triggerByBinarization,
          'contentState': content['isBinarizationEnabled']
        }
      );
      
      if (shouldApplyBinarization) {
        EditPageLogger.editPageInfo(
          '开始二值化处理',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'sourceIsTransformed': hasTransformApplied}
        );
        
        processedImage = await _applyImageBinarization(processedImage, content);
        
        // 更新二值化后的图像数据
        final binarizedImageData = Uint8List.fromList(img.encodePng(processedImage));
        content['binarizedImageData'] = binarizedImageData;
        
        // 🔍 调试：验证二值化数据
        print('🎯 二值化图像数据已生成');
        print('  - 数据大小: ${binarizedImageData.length} bytes');
        print('  - 图像尺寸: ${processedImage.width}x${processedImage.height}');
        print('  - 存储到 content[binarizedImageData]');
        print('  - content 键值: ${content.keys.toList()}');
        
        EditPageLogger.editPageInfo(
          '二值化处理完成',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {
            'resultSize': '${processedImage.width}x${processedImage.height}',
            'dataSize': binarizedImageData.length
          }
        );
      } else {
        // 清除二值化数据
        print('🔧 二值化已禁用，清除二值化数据 (临时处理管线)');
        print('  - 清除前 binarizedImageData 存在: ${content.containsKey('binarizedImageData')}');
        
        content.remove('binarizedImageData');
        
        print('  - 清除后 binarizedImageData 存在: ${content.containsKey('binarizedImageData')}');
        print('  - content keys: ${content.keys.toList()}');
        
        EditPageLogger.editPageInfo(
          '跳过二值化处理（未启用或已禁用）',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'binarizationEnabled': shouldApplyBinarization}
        );
      }

      // 步骤4：更新元素内容，触发UI重新渲染
      print('🔍 准备更新元素内容');
      print('  - content[isBinarizationEnabled]: ${content['isBinarizationEnabled']}');
      print('  - content[binarizedImageData] != null: ${content['binarizedImageData'] != null}');
      if (content['binarizedImageData'] != null) {
        final data = content['binarizedImageData'] as Uint8List;
        print('  - binarizedImageData 大小: ${data.length}');
        print('  - binarizedImageData 类型: ${data.runtimeType}');
        
        // 🔧 保持Uint8List格式，不转换为List<int>
        print('  - 保持Uint8List格式，确保图像正确显示');
        // content['binarizedImageData'] = data.toList(); // 移除这行转换
        print('  - 最终数据类型: ${content['binarizedImageData'].runtimeType}');
        print('  - 最终数据大小: ${data.length}');
      } else {
        print('  - 💡 binarizedImageData 已被清除，将回退到原始/变换图像');
      }
      
      updateProperty('content', content, createUndoOperation: false); // 不创建撤销操作，避免状态冲突
      
      print('🔍 元素内容已更新');
      
      // 🔧 强制触发UI重建以确保渲染器使用新数据
      if (content['binarizedImageData'] != null) {
        print('🔍 检测到二值化数据，强制触发UI重建');
        // 由于我们无法直接访问setState，依靠handlePropertyChange中的更新机制
      }
      
      EditPageLogger.editPageInfo(
        '图像处理管线执行完成',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {
          'hasTransform': hasTransformApplied,
          'hasBinarization': shouldApplyBinarization,
          'finalImageSize': '${processedImage.width}x${processedImage.height}'
        }
      );

    } catch (e, stackTrace) {
      EditPageLogger.editPageError(
        '图像处理管线执行失败',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        error: e,
        stackTrace: stackTrace,
        data: {
          'triggerByTransform': triggerByTransform,
          'triggerByBinarization': triggerByBinarization,
          'changedParameter': changedParameter,
        }
      );
    }
  }

  /// 🔧 向后兼容的方法：处理二值化参数变化
  void handleBinarizationParameterChange(String parameterName, dynamic value) {
    EditPageLogger.editPageInfo(
      '二值化参数变化（通过向后兼容接口）',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
      data: {'parameter': parameterName, 'value': value}
    );

    print('🔍 handleBinarizationParameterChange 被调用');
    print('  - parameter: $parameterName');
    print('  - value: $value');

    // 如果二值化已启用，执行完整的处理管线
    final content = element['content'] as Map<String, dynamic>;
    final isBinarizationEnabled = content['isBinarizationEnabled'] as bool? ?? false;
    
    print('  - 当前二值化状态: $isBinarizationEnabled');
    
    if (isBinarizationEnabled) {
      // 创建临时content来包含新参数值
      final tempContent = Map<String, dynamic>.from(content);
      tempContent[parameterName] = value;
      
      print('  - 执行处理管线，使用临时参数: $parameterName = $value');
      
      Future.microtask(() async {
        await _executeImageProcessingPipelineWithContent(
          tempContent,
          triggerByBinarization: true,
          changedParameter: parameterName,
        );
        
        // 🔧 关键修复：不再调用updateContentProperty，因为处理管线已经更新了完整的content
        // updateContentProperty(parameterName, value, createUndoOperation: false);
        
        print('🔍 参数处理管线执行完成 - 已跳过updateContentProperty以保留二值化数据');
      });
    } else {
      // 如果二值化未启用，直接更新属性（这种情况不会丢失二值化数据，因为二值化未启用）
      updateContentProperty(parameterName, value, createUndoOperation: false);
    }
  }

  /// 🔧 向后兼容的方法：重置变换
  void resetTransform(BuildContext context) {
    print('🔍 resetTransform 开始执行');
    print('  - 当前元素ID: ${element['id']}');
    
    final l10n = AppLocalizations.of(context);
    final content = Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    print('  - 重置前参数: cropX=${content['cropX']}, cropY=${content['cropY']}');
    print('  - 重置前参数: cropWidth=${content['cropWidth']}, cropHeight=${content['cropHeight']}');
    print('  - 重置前参数: rotation=${content['rotation']}, flipH=${content['isFlippedHorizontally']}');

    // Reset to new coordinate system defaults
    final resetValues = <String, dynamic>{
      'cropX': 0.0,
      'cropY': 0.0,
      'isFlippedHorizontally': false,
      'isFlippedVertically': false,
      'rotation': 0.0,
      'isTransformApplied': false,
    };

    if (imageSize != null) {
      resetValues['cropWidth'] = imageSize!.width;
      resetValues['cropHeight'] = imageSize!.height;
      print('  - 使用imageSize设置裁剪尺寸: ${imageSize!.width}x${imageSize!.height}');
    } else {
      resetValues['cropWidth'] = 100.0;
      resetValues['cropHeight'] = 100.0;
      print('  - 使用默认裁剪尺寸: 100x100');
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
        print('  - 移除旧属性: $prop');
        content.remove(prop);
      }
    }

    print('  - 重置后参数: cropX=${content['cropX']}, cropY=${content['cropY']}');
    print('  - 重置后参数: cropWidth=${content['cropWidth']}, cropHeight=${content['cropHeight']}');
    print('  - 重置后参数: rotation=${content['rotation']}, flipH=${content['isFlippedHorizontally']}');

    print('🔍 准备调用updateProperty更新content (createUndoOperation=false)');
    updateProperty('content', content, createUndoOperation: false); // 不创建撤销操作，避免冲突
    print('🔍 updateProperty调用完成');

    // 🔧 关键修复：延迟执行，并添加多重验证
    print('🔍 准备延迟执行处理管线');
    Future.microtask(() async {
      print('🔍 开始执行处理管线 (重置变换)');
      
      // 验证1：检查参数是否保持重置状态
      final verifyContent = element['content'] as Map<String, dynamic>;
      print('  - 处理管线执行前验证: cropX=${verifyContent['cropX']}, rotation=${verifyContent['rotation']}');
      
      // 如果参数已经被修改，重新应用重置值
      bool needsReapply = false;
      for (final entry in resetValues.entries) {
        if (verifyContent[entry.key] != entry.value) {
          print('  - ⚠️ 参数${entry.key}已被修改: ${verifyContent[entry.key]} != ${entry.value}');
          needsReapply = true;
        }
      }
      
      if (needsReapply) {
        print('  - 🔧 重新应用重置值');
        final reapplyContent = Map<String, dynamic>.from(verifyContent);
        resetValues.forEach((key, value) {
          reapplyContent[key] = value;
        });
        updateProperty('content', reapplyContent, createUndoOperation: false);
        
        // 再次验证
        await Future.delayed(Duration(milliseconds: 10));
        final finalVerifyContent = element['content'] as Map<String, dynamic>;
        print('  - 重新应用后验证: cropX=${finalVerifyContent['cropX']}, rotation=${finalVerifyContent['rotation']}');
      }
      
      await executeImageProcessingPipeline(triggerByTransform: true);
      
      print('🔍 处理管线执行完成 (重置变换)');
      
      // 验证2：检查处理管线执行后参数是否仍然正确
      final postPipelineContent = element['content'] as Map<String, dynamic>;
      print('  - 处理管线执行后验证: cropX=${postPipelineContent['cropX']}, rotation=${postPipelineContent['rotation']}');
      
      bool parametersChanged = false;
      for (final entry in resetValues.entries) {
        if (postPipelineContent[entry.key] != entry.value) {
          print('  - ❌ 处理管线后参数${entry.key}发生变化: ${postPipelineContent[entry.key]} != ${entry.value}');
          parametersChanged = true;
        }
      }
      
      if (parametersChanged) {
        print('  - 🚨 检测到参数在处理管线执行后发生了变化，需要调查回调机制');
        
        // 强制再次应用重置值
        print('  - 🔧 强制再次应用重置值');
        final forceResetContent = Map<String, dynamic>.from(postPipelineContent);
        resetValues.forEach((key, value) {
          forceResetContent[key] = value;
        });
        updateProperty('content', forceResetContent, createUndoOperation: false);
      } else {
        print('  - ✅ 参数在整个重置过程中保持稳定');
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
    
    print('🔍 resetTransform 执行完成');
  }
}