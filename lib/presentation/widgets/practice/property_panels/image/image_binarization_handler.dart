import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../../../../application/providers/service_providers.dart';
import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../utils/config/edit_page_logging_config.dart';

/// 图像二值化处理器混合类
mixin ImageBinarizationHandler {
  /// 获取元素数据
  Map<String, dynamic> get element;

  /// 获取ref
  WidgetRef get ref;

  /// 更新内容属性
  void updateContentProperty(String key, dynamic value, {bool createUndoOperation = true});

  /// 处理二值化开关变化
  void handleBinarizationToggle(bool enabled) async {
    EditPageLogger.editPageInfo(
      '二值化开关变化', 
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
      data: {'enabled': enabled}
    );

    if (enabled) {
      // 开关打开时，先更新状态，然后处理图像
      updateContentProperty('isBinarizationEnabled', true, createUndoOperation: true);
      EditPageLogger.editPageInfo(
        '开始执行二值化图像处理', 
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL
      );
      await _processBinarizedImage();
      EditPageLogger.editPageInfo(
        '二值化图像处理完成', 
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL
      );
    } else {
      // 开关关闭时，先清除二值化数据，再更新状态
      updateContentProperty('binarizedImageData', null, createUndoOperation: false); // 立即清除二值化数据
      updateContentProperty('isBinarizationEnabled', false, createUndoOperation: true);
      EditPageLogger.editPageInfo(
        '撤销二值化效果', 
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {'action': 'clear_binarized_data'}
      );
    }
  }

  /// 处理二值化参数变化
  void handleBinarizationParameterChange(String parameterName, dynamic value) async {
    final content = element['content'] as Map<String, dynamic>;
    final isBinarizationEnabled = content['isBinarizationEnabled'] as bool? ?? false;
    
    // 更新参数值
    updateContentProperty(parameterName, value, createUndoOperation: false);

    // 如果二值化开关打开，立即重新处理图像
    if (isBinarizationEnabled) {
      EditPageLogger.editPageInfo(
        '二值化参数变化，重新处理图像', 
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {'parameter': parameterName, 'value': value}
      );
      
      await _processBinarizedImage();
    }
  }

  /// 检查并触发二值化处理（如果已启用）
  Future<void> triggerBinarizationIfEnabled() async {
    final content = element['content'] as Map<String, dynamic>;
    final isBinarizationEnabled = content['isBinarizationEnabled'] as bool? ?? false;
    
    if (isBinarizationEnabled) {
      EditPageLogger.editPageInfo(
        '检测到二值化已启用，重新执行二值化处理', 
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL
      );
      await _processBinarizedImage();
    } else {
      EditPageLogger.editPageInfo(
        '二值化未启用，跳过处理', 
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL
      );
    }
  }
  Future<void> _processBinarizedImage() async {
    try {
      final content = element['content'] as Map<String, dynamic>;
      final imageUrl = content['imageUrl'] as String? ?? '';
      
      EditPageLogger.editPageInfo(
        '检查图像URL', 
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {'imageUrl': imageUrl, 'imageUrlLength': imageUrl.length}
      );
      
      if (imageUrl.isEmpty) {
        EditPageLogger.editPageError(
          '无法进行二值化处理：图像URL为空',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL
        );
        return;
      }

      // 获取处理参数
      final threshold = (content['binaryThreshold'] as num?)?.toDouble() ?? 128.0;
      final isNoiseReductionEnabled = content['isNoiseReductionEnabled'] as bool? ?? false;
      final noiseReductionLevel = (content['noiseReductionLevel'] as num?)?.toDouble() ?? 3.0;

      EditPageLogger.editPageInfo(
        '开始二值化处理', 
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {
          'threshold': threshold,
          'noiseReductionEnabled': isNoiseReductionEnabled,
          'noiseReductionLevel': noiseReductionLevel,
          'imageUrl': imageUrl
        }
      );

      // 获取图像处理服务
      final imageProcessor = ref.read(imageProcessorProvider);
      
      img.Image? sourceImage;
      
      // 🔑 关键改进：检查是否存在变换后的图像数据，优先使用变换后的图像
      final transformedImageData = content['transformedImageData'];
      if (transformedImageData != null) {
        EditPageLogger.editPageInfo(
          '使用变换后的图像进行二值化处理', 
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'dataType': transformedImageData.runtimeType.toString()}
        );
        
        // 处理变换后的图像数据
        Uint8List? imageBytes;
        if (transformedImageData is Uint8List) {
          imageBytes = transformedImageData;
        } else if (transformedImageData is List<int>) {
          imageBytes = Uint8List.fromList(transformedImageData);
        }
        
        if (imageBytes != null) {
          sourceImage = img.decodeImage(imageBytes);
          EditPageLogger.editPageInfo(
            '成功加载变换后的图像数据', 
            tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
            data: {'imageLoaded': sourceImage != null, 'dataSize': imageBytes.length}
          );
        }
      }
      
      // 如果没有变换后的图像，则加载原始图像
      if (sourceImage == null) {
        EditPageLogger.editPageInfo(
          '未找到变换后的图像，加载原始图像', 
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'imageUrl': imageUrl}
        );
        
        if (imageUrl.startsWith('file://')) {
          // 本地文件
          final filePath = imageUrl.substring(7);
          final file = File(filePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            sourceImage = img.decodeImage(bytes);
            EditPageLogger.editPageInfo(
              '成功加载本地文件图像', 
              tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
              data: {'filePath': filePath, 'imageLoaded': sourceImage != null}
            );
          }
        } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
          // 网络图像
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            sourceImage = img.decodeImage(response.bodyBytes);
            EditPageLogger.editPageInfo(
              '成功加载网络图像', 
              tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
              data: {'statusCode': response.statusCode, 'imageLoaded': sourceImage != null}
            );
          }
        } else {
          // 尝试作为本地文件路径
          final file = File(imageUrl);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            sourceImage = img.decodeImage(bytes);
            EditPageLogger.editPageInfo(
              '成功加载本地路径图像', 
              tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
              data: {'filePath': imageUrl, 'imageLoaded': sourceImage != null}
            );
          }
        }
      }

      if (sourceImage == null) {
        EditPageLogger.editPageError(
          '无法加载图像进行二值化处理',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'imageUrl': imageUrl}
        );
        return;
      }

      // 执行二值化处理管线
      img.Image processedImage = sourceImage;

      // 先进行降噪处理（如果启用）
      if (isNoiseReductionEnabled && noiseReductionLevel > 0) {
        processedImage = imageProcessor.denoiseImage(processedImage, noiseReductionLevel);
        EditPageLogger.editPageInfo(
          '降噪处理完成', 
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {'level': noiseReductionLevel}
        );
      }

      // 执行二值化处理
      processedImage = imageProcessor.binarizeImage(processedImage, threshold, false);
      EditPageLogger.editPageInfo(
        '二值化处理完成', 
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {'threshold': threshold}
      );

      // 将处理后的图像编码为字节数组
      final processedBytes = Uint8List.fromList(img.encodePng(processedImage));

      // 更新内容属性，存储处理后的图像数据
      updateContentProperty('binarizedImageData', processedBytes, createUndoOperation: true);
      
      EditPageLogger.editPageInfo(
        '二值化图像数据已更新', 
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {'dataSize': processedBytes.length}
      );

    } catch (e, stackTrace) {
      EditPageLogger.editPageError(
        '二值化处理失败',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        error: e,
        stackTrace: stackTrace
      );
    }
  }
}