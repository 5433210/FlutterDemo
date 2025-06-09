import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../utils/config/edit_page_logging_config.dart';

import '../../../../../application/providers/service_providers.dart';
import '../../../../../l10n/app_localizations.dart';

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
  void updateProperty(String key, dynamic value);

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
          content: Text(l10n.imagePropertyPanelCannotApplyNoImage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final imageSize = this.imageSize;
    final renderSize = this.renderSize;

    if (imageSize != null && renderSize != null) {
      final maxCropWidth = renderSize.width / 2;
      final maxCropHeight = renderSize.height / 2;

      final safeCropTop =
          (content['cropTop'] as num?)?.toDouble().clamp(0.0, maxCropHeight) ??
              0.0;
      final safeCropBottom = (content['cropBottom'] as num?)
              ?.toDouble()
              .clamp(0.0, maxCropHeight) ??
          0.0;
      final safeCropLeft =
          (content['cropLeft'] as num?)?.toDouble().clamp(0.0, maxCropWidth) ??
              0.0;
      final safeCropRight =
          (content['cropRight'] as num?)?.toDouble().clamp(0.0, maxCropWidth) ??
              0.0;

      final flipHorizontal = content['isFlippedHorizontally'] as bool? ?? false;
      final flipVertical = content['isFlippedVertically'] as bool? ?? false;
      final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

      final originalCropLeft = safeCropLeft;
      final originalCropTop = safeCropTop;
      final originalCropRight = safeCropRight;
      final originalCropBottom = safeCropBottom;

      content['transformRect'] = {
        'x': safeCropLeft,
        'y': safeCropTop,
        'width': renderSize.width - safeCropLeft - safeCropRight,
        'height': renderSize.height - safeCropTop - safeCropBottom,
        'originalWidth': renderSize.width,
        'originalHeight': renderSize.height,
      };

      content['cropTop'] = originalCropTop;
      content['cropBottom'] = originalCropBottom;
      content['cropLeft'] = originalCropLeft;
      content['cropRight'] = originalCropRight;

      final bool hasOtherTransforms =
          flipHorizontal || flipVertical || contentRotation != 0.0;
      final bool invalidCropping =
          safeCropLeft + safeCropRight >= imageSize.width ||
              safeCropTop + safeCropBottom >= imageSize.height;

      if (invalidCropping) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .imagePropertyPanelCroppingValueTooLarge),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final bool noCropping = safeCropLeft == 0 &&
          safeCropRight == 0 &&
          safeCropTop == 0 &&
          safeCropBottom == 0;
      final bool isInitialState = noCropping && !hasOtherTransforms;

      if (isInitialState) {
        content['isTransformApplied'] = true;
        content.remove('transformedImageData');
        content.remove('transformedImageUrl');

        content['transformRect'] = {
          'x': 0,
          'y': 0,
          'width': renderSize.width,
          'height': renderSize.height,
          'originalWidth': renderSize.width,
          'originalHeight': renderSize.height,
        };

        updateProperty('content', content);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imagePropertyPanelTransformApplied +
                l10n.imagePropertyPanelNoCropping),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      Future(() async {
        try {
          final widthRatio = imageSize.width / renderSize.width;
          final heightRatio = imageSize.height / renderSize.height;

          final cropAreaLeft = safeCropLeft * widthRatio;
          final cropAreaTop = safeCropTop * heightRatio;
          final cropAreaRight = safeCropRight * widthRatio;
          final cropAreaBottom = safeCropBottom * heightRatio;

          var left = cropAreaLeft;
          var top = cropAreaTop;
          var right = imageSize.width - cropAreaRight;
          var bottom = imageSize.height - cropAreaBottom;

          final minWidth = imageSize.width * 0.01;
          final minHeight = imageSize.height * 0.01;

          if (right - left < minWidth) {
            right = left + minWidth;
            if (right > imageSize.width) {
              right = imageSize.width;
              left = right - minWidth;
            }
          }

          if (bottom - top < minHeight) {
            bottom = top + minHeight;
            if (bottom > imageSize.height) {
              bottom = imageSize.height;
              top = bottom - minHeight;
            }
          }

          if (right <= left) right = left + 1;
          if (bottom <= top) bottom = top + 1;

          final cropRect = Rect.fromLTRB(left, top, right, bottom);

          Uint8List? imageData = await _loadImageFromUrl(imageUrl);

          if (imageData == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.imagePropertyPanelLoadError('{error}')),
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
                  content: Text(l10n.imagePropertyPanelLoadError('{error}')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          final croppedImage =
              ref.read(imageProcessorProvider).rotateAndCropImage(
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

          String message = l10n.imagePropertyPanelTransformApplied;
          if (noCropping) {
            message += l10n.imagePropertyPanelNoCropping;
          } else {
            message += l10n.imagePropertyPanelCroppingApplied(
                originalCropLeft.toInt().toString(),
                originalCropTop.toInt().toString(),
                originalCropRight.toInt().toString(),
                originalCropBottom.toInt().toString());
          }

          if (context.mounted) {
            updateProperty('content', content);
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
            tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
            error: e,
            data: {
              'operation': 'apply_transform',
              'imageUrl': imageUrl,
              'cropLeft': safeCropLeft,
              'cropTop': safeCropTop,
              'cropRight': safeCropRight,
              'cropBottom': safeCropBottom,
              'flipHorizontal': flipHorizontal,
              'flipVertical': flipVertical,
              'contentRotation': contentRotation,
            },
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(l10n.imagePropertyPanelTransformError(e.toString())),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.imagePropertyPanelCannotApplyNoSizeInfo),
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

    content['cropTop'] = 0.0;
    content['cropBottom'] = 0.0;
    content['cropLeft'] = 0.0;
    content['cropRight'] = 0.0;
    content['isFlippedHorizontally'] = false;
    content['isFlippedVertically'] = false;
    content['rotation'] = 0.0;
    content['isTransformApplied'] = false;

    content.remove('transformedImageData');
    content.remove('transformedImageUrl');
    content.remove('transformRect');

    updateProperty('content', content);

    if (imageSize != null && renderSize != null) {
      updateImageState(imageSize, renderSize);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.imagePropertyPanelResetSuccess),
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
            tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
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
            tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
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
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
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