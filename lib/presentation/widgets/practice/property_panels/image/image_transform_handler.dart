import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../../../../application/providers/service_providers.dart';
import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/config/edit_page_logging_config.dart';
import 'image_binarization_handler.dart';

/// 图像变换处理器混合类
mixin ImageTransformHandler {
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

  /// 更新图像状态
  void updateImageState(Size? imageSize, Size? renderSize);

  /// 应用变换到图像
  void applyTransform(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    final imageUrl = content['imageUrl'] as String? ?? '';

    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotApplyNoImage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final imageSize = this.imageSize;
    final renderSize = this.renderSize;

    if (imageSize != null && renderSize != null) {
      // Use new coordinate system directly
      final cropX = (content['cropX'] as num?)?.toDouble() ?? 0.0;
      final cropY = (content['cropY'] as num?)?.toDouble() ?? 0.0;
      final cropWidth =
          (content['cropWidth'] as num?)?.toDouble() ?? imageSize.width;
      final cropHeight =
          (content['cropHeight'] as num?)?.toDouble() ?? imageSize.height;

      final flipHorizontal = content['isFlippedHorizontally'] as bool? ?? false;
      final flipVertical = content['isFlippedVertically'] as bool? ?? false;
      final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

      content['transformRect'] = {
        'x': cropX,
        'y': cropY,
        'width': cropWidth,
        'height': cropHeight,
        'originalWidth': imageSize.width,
        'originalHeight': imageSize.height,
      };

      content['cropX'] = cropX;
      content['cropY'] = cropY;
      content['cropWidth'] = cropWidth;
      content['cropHeight'] = cropHeight;

      final bool invalidCropping = cropX < 0 ||
          cropY < 0 ||
          cropX + cropWidth > imageSize.width ||
          cropY + cropHeight > imageSize.height ||
          cropWidth <= 0 ||
          cropHeight <= 0;

      if (invalidCropping) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .valueTooLarge('Crop area', 'image bounds')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final bool noCropping = cropX == 0 &&
          cropY == 0 &&
          cropWidth == imageSize.width &&
          cropHeight == imageSize.height;

      // 总是执行图像处理，即使是初始状态
      // 这样用户的期望更一致

      Future(() async {
        try {
          // Create crop rectangle using new coordinate system
          final cropRect = Rect.fromLTWH(cropX, cropY, cropWidth, cropHeight);

          Uint8List? imageData = await _loadImageFromUrl(imageUrl);

          if (imageData == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.imageLoadError('{error}')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          final image = img.decodeImage(imageData);
          if (image == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.imageLoadError('{error}')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          final croppedImage =
              ref.read(imageProcessorProvider).flipThenCropImage(
                    image,
                    cropRect,
                    (contentRotation / 180) * math.pi,
                    flipHorizontal: flipHorizontal,
                    flipVertical: flipVertical,
                  );

          final transformedImageData =
              Uint8List.fromList(img.encodePng(croppedImage));
          content['transformedImageData'] = transformedImageData;
          content['isTransformApplied'] = true;

          String message = l10n.transformApplied;
          if (noCropping) {
            message += l10n.noCropping;
          } else {
            message +=
                'Cropping applied: x=${cropX.toInt()}, y=${cropY.toInt()}, width=${cropWidth.toInt()}, height=${cropHeight.toInt()}';
          }

          if (context.mounted) {
            updateProperty('content', content);

            // 🔑 关键改进：变换完成后，检查是否需要重新进行二值化处理
            if (this is ImageBinarizationHandler) {
              await (this as ImageBinarizationHandler)
                  .triggerBinarizationIfEnabled();
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          EditPageLogger.propertyPanelError(
            '应用图像变换失败',
            tag: EditPageLoggingConfig.tagImagePanel,
            error: e,
            data: {
              'operation': 'apply_transform',
              'imageUrl': imageUrl,
              'cropX': cropX,
              'cropY': cropY,
              'cropWidth': cropWidth,
              'cropHeight': cropHeight,
              'flipHorizontal': flipHorizontal,
              'flipVertical': flipVertical,
              'contentRotation': contentRotation,
            },
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.imageTransformError(e.toString())),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotApplyNoSizeInfo),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 重置变换
  void resetTransform(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    // Reset to new coordinate system defaults
    content['cropX'] = 0.0;
    content['cropY'] = 0.0;
    if (imageSize != null) {
      content['cropWidth'] = imageSize!.width;
      content['cropHeight'] = imageSize!.height;
    } else {
      content['cropWidth'] = 100.0;
      content['cropHeight'] = 100.0;
    }

    content['isFlippedHorizontally'] = false;
    content['isFlippedVertically'] = false;
    content['rotation'] = 0.0;
    content['isTransformApplied'] = false;

    // Remove old coordinate system properties if they exist
    content.remove('cropTop');
    content.remove('cropBottom');
    content.remove('cropLeft');
    content.remove('cropRight');

    content.remove('transformedImageData');
    content.remove('transformedImageUrl');
    content.remove('transformRect');

    updateProperty('content', content);

    if (imageSize != null && renderSize != null) {
      updateImageState(imageSize, renderSize);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.imageResetSuccess),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 从URL加载图像
  Future<Uint8List?> _loadImageFromUrl(String imageUrl) async {
    try {
      if (imageUrl.startsWith('file://')) {
        String filePath = imageUrl.substring(7);
        final file = File(filePath);

        if (await file.exists()) {
          return await file.readAsBytes();
        } else {
          EditPageLogger.propertyPanelError(
            '图像文件不存在',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {
              'operation': 'load_image_file',
              'filePath': filePath,
              'imageUrl': imageUrl,
            },
          );
          return null;
        }
      } else {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          EditPageLogger.propertyPanelError(
            'HTTP请求获取图像失败',
            tag: EditPageLoggingConfig.tagImagePanel,
            data: {
              'operation': 'load_image_http',
              'imageUrl': imageUrl,
              'statusCode': response.statusCode,
            },
          );
          return null;
        }
      }
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '加载图像数据失败',
        tag: EditPageLoggingConfig.tagImagePanel,
        error: e,
        data: {
          'operation': 'load_image_data',
          'imageUrl': imageUrl,
        },
      );
      return null;
    }
  }
}
