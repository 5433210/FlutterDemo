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
      return _parseBackgroundColor(backgroundColor);
    }
    return Colors.transparent;
  }

  /// 解析背景颜色，支持16进制颜色和CSS颜色名称
  Color _parseBackgroundColor(String colorValue) {
    final trimmedValue = colorValue.trim().toLowerCase();

    // 处理CSS颜色名称
    switch (trimmedValue) {
      case 'transparent':
        return Colors.transparent;
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'cyan':
        return Colors.cyan;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'brown':
        return Colors.brown;
      case 'magenta':
        return const Color(0xFFFF00FF);
      case 'lime':
        return Colors.lime;
      case 'indigo':
        return Colors.indigo;
      case 'teal':
        return Colors.teal;
      case 'amber':
        return Colors.amber;
    }

    // 处理16进制颜色
    try {
      final colorStr = trimmedValue.startsWith('#')
          ? trimmedValue.substring(1)
          : trimmedValue;

      // 支持3位、6位、8位16进制格式
      String fullColorStr;
      if (colorStr.length == 3) {
        // 将 RGB 转换为 RRGGBB
        fullColorStr =
            'FF${colorStr[0]}${colorStr[0]}${colorStr[1]}${colorStr[1]}${colorStr[2]}${colorStr[2]}';
      } else if (colorStr.length == 6) {
        // 添加Alpha通道 (完全不透明)
        fullColorStr = 'FF$colorStr';
      } else if (colorStr.length == 8) {
        // 已包含Alpha通道
        fullColorStr = colorStr;
      } else {
        throw FormatException('Invalid color format: $colorValue');
      }

      return Color(int.parse(fullColorStr, radix: 16));
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '解析背景颜色失败',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        error: e,
        data: {
          'operation': 'parse_background_color',
          'backgroundColor': colorValue,
          'trimmedValue': trimmedValue,
        },
      );
      // 解析失败时返回透明色
      return Colors.transparent;
    }
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
