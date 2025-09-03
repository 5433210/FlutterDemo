import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../infrastructure/logging/logger.dart';
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
        tag: EditPageLoggingConfig.tagImagePanel,
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
  void updateProperty(String key, dynamic value,
      {bool createUndoOperation = true}) {
    final updates = {key: value};
    handlePropertyChange(updates, createUndoOperation: createUndoOperation);

    // 只有当更新的是content且可能影响图像尺寸时，才检查图像状态
    // 避免不必要的图像状态检查导致预览重置
    if (key == 'content') {
      final content = value as Map<String, dynamic>;
      // 只有当content包含图像URL变化时才检查图像状态
      if (content.containsKey('imageUrl')) {
        final currentImageSize = imageSize;
        final currentRenderSize = renderSize;
        if (currentImageSize != null && currentRenderSize != null) {
          updateImageState(currentImageSize, currentRenderSize);
        }
      }
    }
  }

  /// 更新内容属性
  void updateContentProperty(String key, dynamic value,
      {bool createUndoOperation = true}) {
    AppLogger.debug(
      '🔍 updateContentProperty 被调用',
      tag: 'ImagePropertyPanelMixins',
      data: {
        'key': key,
        'value': value,
        'createUndoOperation': createUndoOperation,
      },
    );

    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    AppLogger.debug(
      '更新content属性',
      tag: 'ImagePropertyPanelMixins',
      data: {
        'key': key,
        'valueBeforeUpdate': content[key],
        'valueAfterUpdate': value,
      },
    );

    content[key] = value;

    // 🔧 特别检查翻转状态
    if (key == 'isFlippedHorizontally' || key == 'isFlippedVertically') {
      final flipH = content['isFlippedHorizontally'] as bool? ?? false;
      final flipV = content['isFlippedVertically'] as bool? ?? false;

      AppLogger.debug(
        '🔍 翻转状态特别检查',
        tag: 'ImagePropertyPanelMixins',
        data: {
          'isFlippedHorizontally': content['isFlippedHorizontally'],
          'isFlippedVertically': content['isFlippedVertically'],
          'bothFlipsFalse': !flipH && !flipV,
          'message': !flipH && !flipV ? '🎯 检测到两个翻转都为false，这应该是允许的！' : null,
        },
      );
    }

    updateProperty('content', content,
        createUndoOperation: createUndoOperation);

    AppLogger.debug(
      'updateProperty 已调用',
      tag: 'ImagePropertyPanelMixins',
    );
  }

  /// 更新裁剪值
  void updateCropValue(String key, double value,
      {bool createUndoOperation = true}) {
    final imageSize = this.imageSize;
    final renderSize = this.renderSize;

    AppLogger.debug(
      '=== updateCropValue 开始 ===',
      tag: 'ImagePropertyPanelMixins',
      data: {
        'key': key,
        'value': value.toStringAsFixed(1),
        'createUndoOperation': createUndoOperation,
      },
    );

    if (imageSize == null || renderSize == null) {
      AppLogger.debug(
        '图像尺寸信息不可用，返回',
        tag: 'ImagePropertyPanelMixins',
        data: {
          'operation': 'update_crop_value',
          'key': key,
          'value': value,
          'imageSize': imageSize?.toString(),
          'renderSize': renderSize?.toString(),
        },
      );
      EditPageLogger.propertyPanelDebug(
        '图像尺寸信息不可用',
        tag: EditPageLoggingConfig.tagImagePanel,
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

    // 记录更新前的内容状态和图像尺寸
    AppLogger.debug(
      '图像尺寸和裁剪状态',
      tag: 'ImagePropertyPanelMixins',
      data: {
        'imageSize': '${imageSize.width}x${imageSize.height}',
        'renderSize': '${renderSize.width}x${renderSize.height}',
        'beforeUpdate': {
          'cropX': content['cropX'],
          'cropY': content['cropY'],
          'cropWidth': content['cropWidth'],
          'cropHeight': content['cropHeight'],
        },
      },
    );

    // 使用新的坐标格式进行验证
    double safeValue;
    switch (key) {
      case 'cropX':
        // X 坐标不能超出图像宽度，也要考虑裁剪宽度
        final currentWidth = (content['cropWidth'] as num?)?.toDouble() ?? 1.0;
        safeValue = value.clamp(0.0, imageSize.width - currentWidth);
        break;
      case 'cropY':
        // Y 坐标不能超出图像高度，也要考虑裁剪高度
        final currentHeight =
            (content['cropHeight'] as num?)?.toDouble() ?? 1.0;
        safeValue = value.clamp(0.0, imageSize.height - currentHeight);
        break;
      case 'cropWidth':
        // 裁剪宽度不能超出图像宽度，也要考虑X坐标
        final currentX = (content['cropX'] as num?)?.toDouble() ?? 0.0;
        safeValue = value.clamp(1.0, imageSize.width - currentX);
        break;
      case 'cropHeight':
        // 裁剪高度不能超出图像高度，也要考虑Y坐标
        final currentY = (content['cropY'] as num?)?.toDouble() ?? 0.0;
        safeValue = value.clamp(1.0, imageSize.height - currentY);
        break;
      default:
        safeValue = value;
    }

    content[key] = safeValue;

    // 记录更新后的内容状态
    AppLogger.debug(
      '裁剪值验证和更新完成',
      tag: 'ImagePropertyPanelMixins',
      data: {
        'key': key,
        'safeValue': safeValue.toStringAsFixed(1),
        'afterUpdate': {
          'cropX': content['cropX'],
          'cropY': content['cropY'],
          'cropWidth': content['cropWidth'],
          'cropHeight': content['cropHeight'],
        },
        'willCallUpdateProperty': createUndoOperation,
      },
    );

    updateProperty('content', content,
        createUndoOperation: createUndoOperation);

    AppLogger.debug(
      '=== updateCropValue 结束 ===',
      tag: 'ImagePropertyPanelMixins',
    );

    EditPageLogger.propertyPanelDebug(
      '更新裁剪值',
      tag: EditPageLoggingConfig.tagImagePanel,
      data: {
        'operation': 'update_crop_value',
        'key': key,
        'originalValue': value,
        'safeValue': safeValue,
        'imageSize': '${imageSize.width}x${imageSize.height}',
        'createUndoOperation': createUndoOperation,
      },
    );
  }

  /// 批量更新所有裁剪值，避免单独更新时的相互干扰
  void updateAllCropValues(double x, double y, double width, double height,
      {bool createUndoOperation = true}) {
    final imageSize = this.imageSize;
    final renderSize = this.renderSize;

    AppLogger.debug(
      '=== updateAllCropValues 开始 ===',
      tag: 'ImagePropertyPanelMixins',
      data: {
        'parameters': {
          'x': x.toStringAsFixed(1),
          'y': y.toStringAsFixed(1),
          'width': width.toStringAsFixed(1),
          'height': height.toStringAsFixed(1),
          'createUndoOperation': createUndoOperation,
        },
      },
    );

    if (imageSize == null || renderSize == null) {
      AppLogger.debug(
        '图像尺寸信息不可用，返回',
        tag: 'ImagePropertyPanelMixins',
        data: {
          'operation': 'update_all_crop_values',
          'x': x,
          'y': y,
          'width': width,
          'height': height,
          'imageSize': imageSize?.toString(),
          'renderSize': renderSize?.toString(),
        },
      );
      EditPageLogger.propertyPanelDebug(
        '图像尺寸信息不可用',
        tag: EditPageLoggingConfig.tagImagePanel,
        data: {
          'operation': 'update_all_crop_values',
          'x': x,
          'y': y,
          'width': width,
          'height': height,
          'imageSize': imageSize?.toString(),
          'renderSize': renderSize?.toString(),
        },
      );
      return;
    }

    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    AppLogger.debug(
      '图像尺寸和更新前状态',
      tag: 'ImagePropertyPanelMixins',
      data: {
        'imageSize': '${imageSize.width}x${imageSize.height}',
        'renderSize': '${renderSize.width}x${renderSize.height}',
        'beforeUpdate': {
          'cropX': content['cropX'],
          'cropY': content['cropY'],
          'cropWidth': content['cropWidth'],
          'cropHeight': content['cropHeight'],
        },
      },
    );

    // 更宽松的边界验证 - 允许裁剪区域超出图像边界，但确保最小尺寸
    double safeX = x.clamp(0.0, imageSize.width);
    double safeY = y.clamp(0.0, imageSize.height);
    double safeWidth = width.clamp(1.0, imageSize.width * 2); // 允许超出边界
    double safeHeight = height.clamp(1.0, imageSize.height * 2); // 允许超出边界

    AppLogger.debug(
      '边界验证结果',
      tag: 'ImagePropertyPanelMixins',
      data: {
        'originalImageSize': '${imageSize.width}x${imageSize.height}',
        'maxAllowedSize': '${imageSize.width * 2}x${imageSize.height * 2}',
        'validatedValues': {
          'x': safeX.toStringAsFixed(1),
          'y': safeY.toStringAsFixed(1),
          'width': safeWidth.toStringAsFixed(1),
          'height': safeHeight.toStringAsFixed(1),
        },
      },
    );

    // 一次性更新所有值
    content['cropX'] = safeX;
    content['cropY'] = safeY;
    content['cropWidth'] = safeWidth;
    content['cropHeight'] = safeHeight;

    AppLogger.debug(
      '批量更新完成',
      tag: 'ImagePropertyPanelMixins',
      data: {
        'afterUpdate': {
          'cropX': content['cropX'],
          'cropY': content['cropY'],
          'cropWidth': content['cropWidth'],
          'cropHeight': content['cropHeight'],
        },
        'willCallUpdateProperty': createUndoOperation,
      },
    );

    updateProperty('content', content,
        createUndoOperation: createUndoOperation);

    AppLogger.debug(
      '=== updateAllCropValues 结束 ===',
      tag: 'ImagePropertyPanelMixins',
    );

    EditPageLogger.propertyPanelDebug(
      '批量更新裁剪值',
      tag: EditPageLoggingConfig.tagImagePanel,
      data: {
        'operation': 'update_all_crop_values',
        'originalValues': 'x=$x, y=$y, width=$width, height=$height',
        'safeValues':
            'x=$safeX, y=$safeY, width=$safeWidth, height=$safeHeight',
        'imageSize': '${imageSize.width}x${imageSize.height}',
        'createUndoOperation': createUndoOperation,
      },
    );
  }

  /// 更新图像尺寸信息
  void updateImageSizeInfo(Size imageSize, Size renderSize) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    // 更新图像尺寸信息
    content['originalWidth'] = imageSize.width;
    content['originalHeight'] = imageSize.height;
    content['renderWidth'] = renderSize.width;
    content['renderHeight'] = renderSize.height;

    // 强制重新初始化裁剪区域，确保新图片加载时使用新的尺寸
    if (content['cropX'] == null) content['cropX'] = 0.0;
    if (content['cropY'] == null) content['cropY'] = 0.0;
    if (content['cropWidth'] == null) content['cropWidth'] = imageSize.width;
    if (content['cropHeight'] == null) content['cropHeight'] = imageSize.height;

    EditPageLogger.propertyPanelDebug(
      '更新图像尺寸信息并重置裁剪区域',
      tag: EditPageLoggingConfig.tagImagePanel,
      data: {
        'operation': 'update_image_size_and_reset_crop',
        'imageSize': '${imageSize.width}x${imageSize.height}',
        'renderSize': '${renderSize.width}x${renderSize.height}',
        'cropArea': '0,0,${imageSize.width},${imageSize.height}',
      },
    );

    // 🔧 修复：初次加载图像时不创建撤销操作，避免选择元素时立即出现undo记录
    updateProperty('content', content, createUndoOperation: false);
  }

  /// 仅更新图像尺寸信息，不重置裁剪区域（用于避免预览重复重置）
  void updateImageSizeInfoOnly(Size imageSize, Size renderSize) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    // 只更新图像尺寸信息，保持现有的裁剪区域设置
    content['originalWidth'] = imageSize.width;
    content['originalHeight'] = imageSize.height;
    content['renderWidth'] = renderSize.width;
    content['renderHeight'] = renderSize.height;

    EditPageLogger.propertyPanelDebug(
      '仅更新图像尺寸信息（保持裁剪区域）',
      tag: EditPageLoggingConfig.tagImagePanel,
      data: {
        'operation': 'update_image_size_only',
        'imageSize': '${imageSize.width}x${imageSize.height}',
        'renderSize': '${renderSize.width}x${renderSize.height}',
      },
    );

    updateProperty('content', content, createUndoOperation: false);
  }

  /// 更新图像状态
  void updateImageState(Size? imageSize, Size? renderSize) {
    if (imageSize == null || renderSize == null) {
      return;
    }

    // 检查图像尺寸是否真的改变了
    final content = element['content'] as Map<String, dynamic>;
    final currentImageWidth = (content['originalWidth'] as num?)?.toDouble();
    final currentImageHeight = (content['originalHeight'] as num?)?.toDouble();
    final currentRenderWidth = (content['renderWidth'] as num?)?.toDouble();
    final currentRenderHeight = (content['renderHeight'] as num?)?.toDouble();

    // 区分是初次加载图像还是图像真正改变
    final isInitialLoad =
        currentImageWidth == null || currentImageHeight == null;
    final imageSizeChanged = !isInitialLoad &&
        (currentImageWidth != imageSize.width ||
            currentImageHeight != imageSize.height);
    final renderSizeChanged = !isInitialLoad &&
        currentRenderWidth != null &&
        currentRenderHeight != null &&
        (currentRenderWidth != renderSize.width ||
            currentRenderHeight != renderSize.height);

    if (isInitialLoad) {
      AppLogger.debug(
        '🔄 首次加载图像，初始化尺寸信息（不创建撤销操作）',
        tag: 'ImagePropertyPanelMixins',
        data: {
          'imageSize': '${imageSize.width}x${imageSize.height}',
          'renderSize': '${renderSize.width}x${renderSize.height}',
          'willUpdateAfterBuild': true,
        },
      );

      // 🔧 修复：延迟到构建完成后再更新图像状态，避免setState during build错误
      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateImageSizeInfo(imageSize, renderSize);
      });
    } else if (imageSizeChanged || renderSizeChanged) {
      AppLogger.debug(
        '🔍 图像尺寸发生变化，需要更新和重置裁剪区域',
        tag: 'ImagePropertyPanelMixins',
        data: {
          'sizeChanges': {
            'originalImageSize': {
              'from': '${currentImageWidth}x$currentImageHeight',
              'to': '${imageSize.width}x${imageSize.height}',
            },
            'renderSize': {
              'from': '${currentRenderWidth}x$currentRenderHeight',
              'to': '${renderSize.width}x${renderSize.height}',
            },
          },
          'willUpdateAfterBuild': true,
        },
      );

      // 真正的图像变更时才创建撤销操作（比如切换到不同的图像文件）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateImageSizeInfoWithUndo(imageSize, renderSize);
      });
    } else {
      AppLogger.debug(
        '🔍 图像尺寸未改变，跳过更新',
        tag: 'ImagePropertyPanelMixins',
      );
    }
  }

  /// 更新图像尺寸信息（带撤销操作）
  void updateImageSizeInfoWithUndo(Size imageSize, Size renderSize) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    // 更新图像尺寸信息
    content['originalWidth'] = imageSize.width;
    content['originalHeight'] = imageSize.height;
    content['renderWidth'] = renderSize.width;
    content['renderHeight'] = renderSize.height;

    // 强制重新初始化裁剪区域，确保新图片加载时使用新的尺寸
    content['cropX'] = 0.0;
    content['cropY'] = 0.0;
    content['cropWidth'] = imageSize.width;
    content['cropHeight'] = imageSize.height;

    EditPageLogger.propertyPanelDebug(
      '更新图像尺寸信息并重置裁剪区域（带撤销操作）',
      tag: EditPageLoggingConfig.tagImagePanel,
      data: {
        'operation': 'update_image_size_and_reset_crop_with_undo',
        'imageSize': '${imageSize.width}x${imageSize.height}',
        'renderSize': '${renderSize.width}x${renderSize.height}',
        'cropArea': '0,0,${imageSize.width},${imageSize.height}',
      },
    );

    // 真正的图像变更时创建撤销操作
    updateProperty('content', content, createUndoOperation: true);
  }

  /// 处理属性变更（需要被实现类重写）
  void handlePropertyChange(Map<String, dynamic> updates,
      {bool createUndoOperation = true});

  /// 访问器（需要混合 ImagePropertyAccessors）
  Size? get imageSize;
  Size? get renderSize;
}
