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
  void updateProperty(String key, dynamic value,
      {bool createUndoOperation = true}) {
    final updates = {key: value};
    handlePropertyChange(updates, createUndoOperation: createUndoOperation);

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
  void updateCropValue(String key, double value,
      {bool createUndoOperation = true}) {
    print('=== updateCropValue 开始 ===');
    print(
        '参数: key=$key, value=${value.toStringAsFixed(1)}, createUndoOperation=$createUndoOperation');

    final imageSize = this.imageSize;
    final renderSize = this.renderSize;

    if (imageSize == null || renderSize == null) {
      print('图像尺寸信息不可用，返回');
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

    print('图像尺寸: ${imageSize.width}x${imageSize.height}');
    print('渲染尺寸: ${renderSize.width}x${renderSize.height}');

    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    // 记录更新前的内容状态
    print('更新前content[cropX]: ${content['cropX']}');
    print('更新前content[cropY]: ${content['cropY']}');
    print('更新前content[cropWidth]: ${content['cropWidth']}');
    print('更新前content[cropHeight]: ${content['cropHeight']}');

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

    print('验证后设置: content[$key] = ${safeValue.toStringAsFixed(1)}');

    // 记录更新后的内容状态
    print('更新后content[cropX]: ${content['cropX']}');
    print('更新后content[cropY]: ${content['cropY']}');
    print('更新后content[cropWidth]: ${content['cropWidth']}');
    print('更新后content[cropHeight]: ${content['cropHeight']}');

    print('调用 updateProperty，createUndoOperation=$createUndoOperation');
    updateProperty('content', content,
        createUndoOperation: createUndoOperation);

    print('=== updateCropValue 结束 ===');

    EditPageLogger.propertyPanelDebug(
      '更新裁剪值',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
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
    print('=== updateAllCropValues 开始 ===');
    print('参数: x=${x.toStringAsFixed(1)}, y=${y.toStringAsFixed(1)}, '
        'width=${width.toStringAsFixed(1)}, height=${height.toStringAsFixed(1)}, '
        'createUndoOperation=$createUndoOperation');

    final imageSize = this.imageSize;
    final renderSize = this.renderSize;

    if (imageSize == null || renderSize == null) {
      print('图像尺寸信息不可用，返回');
      EditPageLogger.propertyPanelDebug(
        '图像尺寸信息不可用',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
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

    print('图像尺寸: ${imageSize.width}x${imageSize.height}');
    print('渲染尺寸: ${renderSize.width}x${renderSize.height}');

    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    // 记录更新前的内容状态
    print('更新前content[cropX]: ${content['cropX']}');
    print('更新前content[cropY]: ${content['cropY']}');
    print('更新前content[cropWidth]: ${content['cropWidth']}');
    print('更新前content[cropHeight]: ${content['cropHeight']}');

    // 更宽松的边界验证 - 允许裁剪区域超出图像边界，但确保最小尺寸
    double safeX = x.clamp(0.0, imageSize.width);
    double safeY = y.clamp(0.0, imageSize.height);
    double safeWidth = width.clamp(1.0, imageSize.width * 2); // 允许超出边界
    double safeHeight = height.clamp(1.0, imageSize.height * 2); // 允许超出边界

    print('放宽边界限制 - 原始图像尺寸: ${imageSize.width}x${imageSize.height}');
    print('允许的最大尺寸: ${imageSize.width * 2}x${imageSize.height * 2}');

    print(
        '验证后的值: x=${safeX.toStringAsFixed(1)}, y=${safeY.toStringAsFixed(1)}, '
        'width=${safeWidth.toStringAsFixed(1)}, height=${safeHeight.toStringAsFixed(1)}');

    // 一次性更新所有值
    content['cropX'] = safeX;
    content['cropY'] = safeY;
    content['cropWidth'] = safeWidth;
    content['cropHeight'] = safeHeight;

    // 记录更新后的内容状态
    print('更新后content[cropX]: ${content['cropX']}');
    print('更新后content[cropY]: ${content['cropY']}');
    print('更新后content[cropWidth]: ${content['cropWidth']}');
    print('更新后content[cropHeight]: ${content['cropHeight']}');

    print('调用 updateProperty，createUndoOperation=$createUndoOperation');
    updateProperty('content', content,
        createUndoOperation: createUndoOperation);

    print('=== updateAllCropValues 结束 ===');

    EditPageLogger.propertyPanelDebug(
      '批量更新裁剪值',
      tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
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

    // 如果裁剪属性未初始化，则使用图像的完整尺寸作为初始裁剪区域
    bool needsInitialization = false;

    if (content['cropX'] == null) {
      content['cropX'] = 0.0;
      needsInitialization = true;
    }
    if (content['cropY'] == null) {
      content['cropY'] = 0.0;
      needsInitialization = true;
    }
    if (content['cropWidth'] == null) {
      content['cropWidth'] = imageSize.width;
      needsInitialization = true;
    }
    if (content['cropHeight'] == null) {
      content['cropHeight'] = imageSize.height;
      needsInitialization = true;
    }

    // 验证现有的裁剪值是否合理
    final currentCropX = (content['cropX'] as num?)?.toDouble() ?? 0.0;
    final currentCropY = (content['cropY'] as num?)?.toDouble() ?? 0.0;
    final currentCropWidth =
        (content['cropWidth'] as num?)?.toDouble() ?? imageSize.width;
    final currentCropHeight =
        (content['cropHeight'] as num?)?.toDouble() ?? imageSize.height;

    // 如果现有值超出了图像边界，需要修正
    if (currentCropX + currentCropWidth > imageSize.width ||
        currentCropY + currentCropHeight > imageSize.height ||
        currentCropX < 0 ||
        currentCropY < 0 ||
        currentCropWidth <= 0 ||
        currentCropHeight <= 0) {
      content['cropX'] = 0.0;
      content['cropY'] = 0.0;
      content['cropWidth'] = imageSize.width;
      content['cropHeight'] = imageSize.height;
      needsInitialization = true;
    }

    if (needsInitialization) {
      EditPageLogger.propertyPanelDebug(
        '初始化或修正裁剪区域',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        data: {
          'operation': 'initialize_crop_area',
          'imageSize': '${imageSize.width}x${imageSize.height}',
          'cropArea':
              '${content['cropX']},${content['cropY']},${content['cropWidth']},${content['cropHeight']}',
        },
      );
    }

    updateProperty('content', content);
  }

  /// 更新图像状态
  void updateImageState(Size? imageSize, Size? renderSize) {
    if (imageSize == null || renderSize == null) {
      return;
    }

    final currentImageSize = this.imageSize;
    final currentRenderSize = this.renderSize;

    // 检查是否需要更新
    bool needsUpdate = false;

    if (currentImageSize == null || currentRenderSize == null) {
      needsUpdate = true;
    } else if (currentImageSize != imageSize ||
        currentRenderSize != renderSize) {
      needsUpdate = true;
    }

    // 检查裁剪属性是否已初始化
    final content = element['content'] as Map<String, dynamic>;
    if (content['cropX'] == null ||
        content['cropY'] == null ||
        content['cropWidth'] == null ||
        content['cropHeight'] == null) {
      needsUpdate = true;
    }

    if (needsUpdate) {
      updateImageSizeInfo(imageSize, renderSize);
    }
  }

  /// 处理属性变更（需要被实现类重写）
  void handlePropertyChange(Map<String, dynamic> updates,
      {bool createUndoOperation = true});

  /// 访问器（需要混合 ImagePropertyAccessors）
  Size? get imageSize;
  Size? get renderSize;
}
