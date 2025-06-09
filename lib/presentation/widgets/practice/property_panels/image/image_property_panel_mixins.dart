import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../utils/config/edit_page_logging_config.dart';

import '../../practice_edit_controller.dart';

/// 图像属性访问器混合类
mixin ImagePropertyAccessors {
  /// 获取元素数据
  Map<String, dynamic> get element;

  /// 图像尺寸
  Size? get imageSize {
    final content = element['content'] as Map<String, dynamic>;
    final width = content['originalWidth'] as num?;
    final height = content['originalHeight'] as num?;
    return (width != null && height != null)
        ? Size(width.toDouble(), height.toDouble())
        : null;
  }

  /// 渲染尺寸
  Size? get renderSize {
    final content = element['content'] as Map<String, dynamic>;
    final width = content['renderWidth'] as num?;
    final height = content['renderHeight'] as num?;
    return (width != null && height != null)
        ? Size(width.toDouble(), height.toDouble())
        : null;
  }

  /// 最大裁剪宽度
  double get maxCropWidth {
    final renderSize = this.renderSize;
    if (renderSize != null) {
      return renderSize.width / 2;
    }

    final imageSize = this.imageSize;
    if (imageSize != null) {
      return imageSize.width / 2;
    }

    final content = element['content'] as Map<String, dynamic>;
    final width = content['originalWidth'] as num?;
    if (width != null) {
      return width.toDouble() / 2;
    }

    return 0.0;
  }

  /// 最大裁剪高度
  double get maxCropHeight {
    final renderSize = this.renderSize;
    if (renderSize != null) {
      return renderSize.height / 2;
    }

    final imageSize = this.imageSize;
    if (imageSize != null) {
      return imageSize.height / 2;
    }

    final content = element['content'] as Map<String, dynamic>;
    final height = content['originalHeight'] as num?;
    if (height != null) {
      return height.toDouble() / 2;
    }

    return 0.0;
  }

  /// 获取背景色
  Color getBackgroundColor() {
    final content = element['content'] as Map<String, dynamic>;
    final backgroundColor = content['backgroundColor'] as String?;

    if (backgroundColor != null && backgroundColor.isNotEmpty) {
      try {
        final colorStr = backgroundColor.startsWith('#')
            ? backgroundColor.substring(1)
            : backgroundColor;
        final fullColorStr = colorStr.length == 6 ? 'FF$colorStr' : colorStr;
        return Color(int.parse(fullColorStr, radix: 16));
      } catch (e) {
        final colorStr = backgroundColor.startsWith('#')
            ? backgroundColor.substring(1)
            : backgroundColor;
        final fullColorStr = colorStr.length == 6 ? 'FF$colorStr' : colorStr;
        EditPageLogger.propertyPanelError(
          '解析背景颜色失败',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          error: e,
          data: {
            'operation': 'parse_background_color',
            'backgroundColor': backgroundColor,
            'colorStr': colorStr,
            'fullColorStr': fullColorStr,
          },
        );
      }
    }
    return Colors.transparent;
  }

  /// 左侧裁剪值
  double get leftCrop =>
      (element['content']['cropLeft'] as num?)?.toDouble() ?? 0.0;

  /// 右侧裁剪值
  double get rightCrop =>
      (element['content']['cropRight'] as num?)?.toDouble() ?? 0.0;

  /// 顶部裁剪值
  double get topCrop =>
      (element['content']['cropTop'] as num?)?.toDouble() ?? 0.0;

  /// 底部裁剪值
  double get bottomCrop =>
      (element['content']['cropBottom'] as num?)?.toDouble() ?? 0.0;
}

/// 图像属性更新器混合类
mixin ImagePropertyUpdaters {
  /// 获取控制器
  PracticeEditController get controller;

  /// 获取元素数据
  Map<String, dynamic> get element;

  /// 获取ref
  WidgetRef get ref;

  /// 更新属性
  void updateProperty(String key, dynamic value) {
    final updates = {key: value};
    handlePropertyChange(updates);

    final currentImageSize = imageSize;
    final currentRenderSize = renderSize;
    if (currentImageSize != null && currentRenderSize != null) {
      updateImageState(currentImageSize, currentRenderSize);
    }
  }

  /// 更新内容属性
  void updateContentProperty(String key, dynamic value) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    content[key] = value;
    updateProperty('content', content);
  }

  /// 更新裁剪值
  void updateCropValue(String key, double value) {
    Future.microtask(() {
      final imageSize = this.imageSize;
      final renderSize = this.renderSize;

      if (imageSize == null || renderSize == null) {
        EditPageLogger.propertyPanelDebug(
          '图像尺寸信息不可用',
          tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
          data: {
            'operation': 'update_crop_value',
            'key': key,
            'value': value,
            'imageSize': imageSize?.toString(),
            'renderSize': renderSize?.toString(),
          },
        );
        return;
      }

      final content =
          Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

      double maxValue;
      if (key == 'cropTop' || key == 'cropBottom') {
        maxValue = renderSize.height / 2;
      } else {
        maxValue = renderSize.width / 2;
      }

      final safeValue = value.clamp(0.0, maxValue);
      content[key] = safeValue;
      updateProperty('content', content);
    });
  }

  /// 更新图像尺寸信息
  void updateImageSizeInfo(Size imageSize, Size renderSize) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    content['originalWidth'] = imageSize.width;
    content['originalHeight'] = imageSize.height;
    content['renderWidth'] = renderSize.width;
    content['renderHeight'] = renderSize.height;
    updateProperty('content', content);
  }

  /// 更新图像状态
  void updateImageState(Size? imageSize, Size? renderSize) {
    if (imageSize == null || renderSize == null) {
      return;
    }

    final currentImageSize = this.imageSize;
    final currentRenderSize = this.renderSize;

    if (currentImageSize != null && currentRenderSize != null) {
      if (currentImageSize == imageSize && currentRenderSize == renderSize) {
        return;
      }
    }

    updateImageSizeInfo(imageSize, renderSize);
  }

  /// 处理属性变更（需要被实现类重写）
  void handlePropertyChange(Map<String, dynamic> updates);

  /// 访问器（需要混合 ImagePropertyAccessors）
  Size? get imageSize;
  Size? get renderSize;
} 