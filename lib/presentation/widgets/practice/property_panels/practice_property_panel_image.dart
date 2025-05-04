import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../../../application/providers/providers.dart';
import '../../common/color_palette_widget.dart';
import '../../common/editable_number_field.dart';
import '../practice_edit_controller.dart';
import 'element_common_property_panel.dart';
import 'layer_info_panel.dart';
import 'practice_property_panel_base.dart';

// 自定义虚线装饰
class DashedDecoration extends Decoration {
  final Color color;
  final BorderRadius? borderRadius;
  final double strokeWidth;
  final double gap;
  final Color dashedColor;

  const DashedDecoration({
    required this.color,
    this.borderRadius,
    required this.strokeWidth,
    required this.gap,
    required this.dashedColor,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _DashedDecorationPainter(
      color: color,
      borderRadius: borderRadius,
      strokeWidth: strokeWidth,
      gap: gap,
      dashedColor: dashedColor,
      decoration: this,
    );
  }
}

/// 图片内容属性面板
class ImagePropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final VoidCallback onSelectImage;
  final WidgetRef ref;
  final ValueNotifier<bool> _isImageLoadedNotifier = ValueNotifier<bool>(false);

  ImagePropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onSelectImage,
    required this.ref,
  }) : super(key: key, controller: controller);

  double get bottomCrop =>
      (element['content']['cropBottom'] as num?)?.toDouble() ?? 0.0;

  // 获取图片尺寸信息
  Size? get imageSize {
    final content = element['content'] as Map<String, dynamic>;
    final width = content['originalWidth'] as num?;
    final height = content['originalHeight'] as num?;
    if (width != null && height != null) {
      return Size(width.toDouble(), height.toDouble());
    }
    return null;
  }

  // 获取图片加载状态
  bool get isImageLoaded => _isImageLoadedNotifier.value;

  double get leftCrop =>
      (element['content']['cropLeft'] as num?)?.toDouble() ?? 0.0;

  double get maxCropHeight {
    // 最大裁剪值应该基于渲染尺寸（UI展示的图像）
    final renderSize = this.renderSize;
    if (renderSize != null) {
      // 使用渲染高度的一半作为UI上的最大裁剪值
      return renderSize.height / 2;
    }

    // 兜底逻辑，如果渲染尺寸不可用
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

  // 获取最大裁剪值（UI）
  double get maxCropWidth {
    // 最大裁剪值应该基于渲染尺寸（UI展示的图像）
    final renderSize = this.renderSize;
    if (renderSize != null) {
      // 使用渲染宽度的一半作为UI上的最大裁剪值
      return renderSize.width / 2;
    }

    // 兜底逻辑，如果渲染尺寸不可用
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

  // 获取渲染尺寸
  Size? get renderSize {
    final content = element['content'] as Map<String, dynamic>;
    final width = content['renderWidth'] as num?;
    final height = content['renderHeight'] as num?;
    if (width != null && height != null) {
      return Size(width.toDouble(), height.toDouble());
    }
    return null;
  }

  double get rightCrop =>
      (element['content']['cropRight'] as num?)?.toDouble() ?? 0.0;
  // 获取当前裁剪值
  double get topCrop =>
      (element['content']['cropTop'] as num?)?.toDouble() ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;
    final layerId = element['layerId'] as String?;

    // 获取图层信息
    Map<String, dynamic>? layer;
    if (layerId != null) {
      layer = controller.state.getLayerById(layerId);
    }

    // 图片特有属性
    final content = element['content'] as Map<String, dynamic>;
    final imageUrl = content['imageUrl'] as String? ?? '';

    // 裁剪属性
    final cropTop = (content['cropTop'] as num?)?.toDouble() ?? 0.0;
    final cropBottom = (content['cropBottom'] as num?)?.toDouble() ?? 0.0;
    final cropLeft = (content['cropLeft'] as num?)?.toDouble() ?? 0.0;
    final cropRight = (content['cropRight'] as num?)?.toDouble() ?? 0.0;

    // 不在build方法中更新裁剪值，避免在构建过程中修改状态
    // 裁剪值已经从element中获取，直接使用即可

    // 翻转属性
    final isFlippedHorizontally =
        content['isFlippedHorizontally'] as bool? ?? false;
    final isFlippedVertically =
        content['isFlippedVertically'] as bool? ?? false;

    // 内容旋转属性
    final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

    // 绘制模式
    final fitMode = content['fitMode'] as String? ?? 'contain';

    // 是否已应用变换
    final isTransformApplied = content['isTransformApplied'] as bool? ?? false;

    // 注意：图片加载后可能需要重置裁剪值
    // 这个功能已经在图片加载回调中处理

    return ListView(
      children: [
        // 基本属性面板（放在最上方）
        ElementCommonPropertyPanel(
          element: element,
          onElementPropertiesChanged: onElementPropertiesChanged,
          controller: controller,
        ),

        // 图层信息部分
        LayerInfoPanel(layer: layer),

        // 几何属性部分
        materialExpansionTile(
          title: const Text('元素几何属性'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 添加提示信息
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color:
                          Colors.blue.withAlpha(26), // 0.1 opacity = 26 alpha
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                          color: Colors.blue
                              .withAlpha(77)), // 0.3 opacity = 77 alpha
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '以下属性调整的是整个元素框，而非图片内容本身',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // X和Y位置
                  Row(
                    children: [
                      Expanded(
                        child: EditableNumberField(
                          label: 'X',
                          value: x,
                          suffix: 'px',
                          min: 0,
                          max: 10000,
                          onChanged: (value) => _updateProperty('x', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: EditableNumberField(
                          label: 'Y',
                          value: y,
                          suffix: 'px',
                          min: 0,
                          max: 10000,
                          onChanged: (value) => _updateProperty('y', value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // 宽度和高度
                  Row(
                    children: [
                      Expanded(
                        child: EditableNumberField(
                          label: '宽度',
                          value: width,
                          suffix: 'px',
                          min: 10,
                          max: 10000,
                          onChanged: (value) => _updateProperty('width', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: EditableNumberField(
                          label: '高度',
                          value: height,
                          suffix: 'px',
                          min: 10,
                          max: 10000,
                          onChanged: (value) =>
                              _updateProperty('height', value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // 旋转角度
                  EditableNumberField(
                    label: '旋转',
                    value: rotation,
                    suffix: '°',
                    min: -360,
                    max: 360,
                    decimalPlaces: 1,
                    onChanged: (value) => _updateProperty('rotation', value),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 视觉属性部分
        materialExpansionTile(
          title: const Text('视觉设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 透明度滑块
                  const Text('透明度:'),
                  Row(
                    children: [
                      Expanded(
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return Slider(
                              value: opacity,
                              min: 0.0,
                              max: 1.0,
                              divisions: 100,
                              label: '${(opacity * 100).toStringAsFixed(0)}%',
                              onChanged: (value) {
                                setState(() {});
                                _updateProperty('opacity', value);
                              },
                              onChangeEnd: (value) {
                                _updateProperty('opacity', value);
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text('${(opacity * 100).toStringAsFixed(0)}%'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 背景颜色选择器
                  const Text('背景颜色:'),
                  const SizedBox(height: 8.0),
                  ColorPaletteWidget(
                    initialColor: _getBackgroundColor(),
                    labelText: '背景颜色',
                    onColorChanged: (color) {
                      // 将颜色转换为十六进制字符串
                      final hexColor =
                          '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                      debugPrint('选择的背景颜色: $hexColor');

                      // 更新内容属性
                      _updateContentProperty('backgroundColor', hexColor);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        // 图片选择部分
        materialExpansionTile(
          title: const Text('图片选择'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          onPressed: () => _selectImageFromLocal(context),
                          label: const Text('从本地选择'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        materialExpansionTile(
          title: const Text('适应模式'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 适应模式选择

                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFitModeButton('contain', '适应', fitMode),
                      _buildFitModeButton('cover', '填充', fitMode),
                      _buildFitModeButton('fill', '拉伸', fitMode),
                      _buildFitModeButton('none', '原始', fitMode),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 图像预览部分
        materialExpansionTile(
          title: const Text('图像预览'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color:
                          Colors.amber.withAlpha(26), // 0.1 opacity = 26 alpha
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                          color: Colors.amber
                              .withAlpha(128)), // 0.5 opacity = 128 alpha
                    ),
                    child: const Text(
                      '注意: 长时间显示重复日志属于正常现象，不影响功能',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _buildImagePreviewWithTransformBox(
                    imageUrl: imageUrl,
                    fitMode: fitMode,
                    cropTop: cropTop,
                    cropBottom: cropBottom,
                    cropLeft: cropLeft,
                    cropRight: cropRight,
                    flipHorizontal: isFlippedHorizontally,
                    flipVertical: isFlippedVertically,
                    contentRotation: contentRotation,
                    isTransformApplied: isTransformApplied,
                  ),
                ],
              ),
            ),
          ],
        ),

        // 图像变换部分
        materialExpansionTile(
          title: const Text('图像变换'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 添加提示信息
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color:
                          Colors.amber.withAlpha(26), // 0.1 opacity = 26 alpha
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                          color: Colors.amber
                              .withAlpha(77)), // 0.3 opacity = 77 alpha
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '以下变换直接修改图片内容本身，而不是整个元素框',
                            style: TextStyle(fontSize: 12, color: Colors.amber),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 裁剪设置
                  const Text('裁剪:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            // 上裁剪滑块
                            _buildCropSlider(
                              label: '上裁剪',
                              cropKey: 'cropTop',
                              value: cropTop,
                              max: maxCropHeight,
                            ),
                            // 下裁剪滑块
                            _buildCropSlider(
                              label: '下裁剪',
                              cropKey: 'cropBottom',
                              value: cropBottom,
                              max: maxCropHeight,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            // 左裁剪滑块
                            _buildCropSlider(
                              label: '左裁剪',
                              cropKey: 'cropLeft',
                              value: cropLeft,
                              max: maxCropWidth,
                            ),
                            // 右裁剪滑块
                            _buildCropSlider(
                              label: '右裁剪',
                              cropKey: 'cropRight',
                              value: cropRight,
                              max: maxCropWidth,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 翻转按钮
                  const Text('翻转:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flip),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isFlippedHorizontally ? Colors.blue : null,
                            foregroundColor:
                                isFlippedHorizontally ? Colors.white : null,
                          ),
                          onPressed: () => _updateContentProperty(
                              'isFlippedHorizontally', !isFlippedHorizontally),
                          label: const Text('水平翻转'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flip),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isFlippedVertically ? Colors.blue : null,
                            foregroundColor:
                                isFlippedVertically ? Colors.white : null,
                          ),
                          onPressed: () => _updateContentProperty(
                              'isFlippedVertically', !isFlippedVertically),
                          label: const Text('垂直翻转'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // 旋转
                  const Text('旋转:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            // 获取最新的内容旋转值
                            final currentContent =
                                element['content'] as Map<String, dynamic>;
                            final currentRotation =
                                (currentContent['rotation'] as num?)
                                        ?.toDouble() ??
                                    0.0;
                            // 确保旋转值在滑块范围内
                            final safeRotation =
                                currentRotation.clamp(-180.0, 180.0);

                            return Slider(
                              value: safeRotation,
                              min: -180.0,
                              max: 180.0,
                              divisions: 360,
                              label: '${safeRotation.toStringAsFixed(0)}°',
                              onChanged: (value) {
                                // 直接更新content属性
                                _updateContentProperty('rotation', value);
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Builder(
                          builder: (context) {
                            // 确保显示最新的旋转值
                            final currentContent =
                                element['content'] as Map<String, dynamic>;
                            final currentRotation =
                                (currentContent['rotation'] as num?)
                                        ?.toDouble() ??
                                    0.0;
                            return Text(
                                '${currentRotation.toStringAsFixed(0)}°');
                          },
                        ),
                      ),
                    ],
                  ),

                  // 快速旋转按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRotationButton('0°', () {
                        // 重置为0度
                        _updateContentProperty('rotation', 0.0);
                      }),
                      const SizedBox(width: 8.0),
                      _buildRotationButton('+90°', () {
                        // 获取当前内容旋转值
                        final contentRotation =
                            (content['rotation'] as num?)?.toDouble() ?? 0.0;
                        // 计算新的旋转值并确保在-180到180范围内
                        double newRotation = contentRotation + 90;
                        while (newRotation > 180) {
                          newRotation -= 360;
                        }
                        _updateContentProperty('rotation', newRotation);
                      }),
                      const SizedBox(width: 8.0),
                      _buildRotationButton('-90°', () {
                        // 获取当前内容旋转值
                        final contentRotation =
                            (content['rotation'] as num?)?.toDouble() ?? 0.0;
                        // 计算新的旋转值并确保在-180到180范围内
                        double newRotation = contentRotation - 90;
                        while (newRotation < -180) {
                          newRotation += 360;
                        }
                        _updateContentProperty('rotation', newRotation);
                      }),
                      const SizedBox(width: 8.0),
                      _buildRotationButton('180°', () {
                        // 获取当前内容旋转值
                        final contentRotation =
                            (content['rotation'] as num?)?.toDouble() ?? 0.0;
                        // 计算新的旋转值并确保在-180到180范围内
                        double newRotation = contentRotation + 180;
                        while (newRotation > 180) {
                          newRotation -= 360;
                        }
                        _updateContentProperty('rotation', newRotation);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // 应用和重置按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          onPressed: () => _applyTransform(context),
                          label: const Text('应用变换'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          onPressed: () => _resetTransform(context),
                          label: const Text('重置变换'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void forceKeepLoadedState() {
    if (imageSize != null && renderSize != null) {
      debugPrint('ImageSizeStateHolder: 强制保持加载状态');
    }
  }

  // 获取字符串的最小长度
  int min(int a, int b) => a < b ? a : b;

  // 更新裁剪值
  void updateCropValue(String key, double value) {
    // 使用Future.microtask延迟状态更新，避免在构建过程中修改状态
    Future.microtask(() {
      // 获取当前图片尺寸
      final imageSize = this.imageSize;
      final renderSize = this.renderSize;

      if (imageSize == null || renderSize == null) {
        debugPrint('警告：图片尺寸信息不可用');
        return;
      }

      final content =
          Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

      // 重要：这里的裁剪值是UI坐标系中的值（基于渲染尺寸）
      // 用户操作的是界面上的滑块，滑块的最大值应该基于渲染尺寸
      double maxValue;
      if (key == 'cropTop' || key == 'cropBottom') {
        // 使用渲染高度的一半作为UI裁剪最大值
        maxValue = renderSize.height / 2;
      } else {
        // 使用渲染宽度的一半作为UI裁剪最大值
        maxValue = renderSize.width / 2;
      }

      // 确保裁剪值在有效范围内
      final safeValue = value.clamp(0.0, maxValue);

      // 记录实际裁剪值（UI坐标系）
      debugPrint('设置UI裁剪值 $key = $safeValue (最大值: $maxValue)');

      // 更新裁剪值 - 注意这是保存在元素属性中的UI坐标系值
      // 真正转换为图像坐标系是在应用变换时进行
      content[key] = safeValue;

      // 更新属性
      _updateProperty('content', content);
    });
  }

  // 更新图片尺寸信息
  void updateImageSizeInfo(Size imageSize, Size renderSize) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    content['originalWidth'] = imageSize.width;
    content['originalHeight'] = imageSize.height;
    content['renderWidth'] = renderSize.width;
    content['renderHeight'] = renderSize.height;
    _updateProperty('content', content);
  }

  // 更新图片状态
  void updateImageState(Size? imageSize, Size? renderSize) {
    if (imageSize == null || renderSize == null) {
      debugPrint('ImageSizeStateHolder: 图片尺寸或渲染尺寸无效，保持当前状态');
      return;
    }

    // 检查是否需要更新
    final currentImageSize = this.imageSize;
    final currentRenderSize = this.renderSize;

    if (currentImageSize != null && currentRenderSize != null) {
      // 如果尺寸没有变化，不需要更新
      if (currentImageSize == imageSize && currentRenderSize == renderSize) {
        return;
      }
    }

    // 更新图片尺寸信息
    updateImageSizeInfo(imageSize, renderSize);
    // 设置图片加载状态为true
    _isImageLoadedNotifier.value = true;
    debugPrint(
        'ImageSizeStateHolder: 图片尺寸已更新，isImageLoaded=${_isImageLoadedNotifier.value}');
  }

  // 应用变换
  void _applyTransform(BuildContext context) {
    // 获取当前变换参数
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    final imageUrl = content['imageUrl'] as String? ?? '';

    // 如果没有图片URL，无法执行变换
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法应用变换：未设置图片'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 获取图片尺寸信息（如果可用）
    final imageSize = this.imageSize;
    final renderSize = this.renderSize;

    if (imageSize != null && renderSize != null) {
      // 使用与getter相同的逻辑，裁剪值最大为渲染尺寸的一半
      final maxCropWidth = renderSize.width / 2;
      final maxCropHeight = renderSize.height / 2;

      debugPrint('应用变换时的最大裁剪值: 宽=$maxCropWidth, 高=$maxCropHeight');

      // 获取用户通过滑块设置的裁剪值
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

      // 翻转属性
      final flipHorizontal = content['isFlippedHorizontally'] as bool? ?? false;
      final flipVertical = content['isFlippedVertically'] as bool? ?? false;

      // 内容旋转属性
      final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

      // 保存原始裁剪值，用于显示在成功消息中
      final originalCropLeft = safeCropLeft;
      final originalCropTop = safeCropTop;
      final originalCropRight = safeCropRight;
      final originalCropBottom = safeCropBottom;

      // 保存变换区域信息 - 这些参数将用于在画布上绘制时提取变换区域
      content['transformRect'] = {
        'x': safeCropLeft,
        'y': safeCropTop,
        'width': renderSize.width - safeCropLeft - safeCropRight,
        'height': renderSize.height - safeCropTop - safeCropBottom,
        'originalWidth': renderSize.width,
        'originalHeight': renderSize.height,
      };

      // 保存用户设置的原始裁剪值
      content['cropTop'] = originalCropTop;
      content['cropBottom'] = originalCropBottom;
      content['cropLeft'] = originalCropLeft;
      content['cropRight'] = originalCropRight;

      // 判断是否有其他变换
      final bool hasOtherTransforms =
          flipHorizontal || flipVertical || contentRotation != 0.0;

      // 检查是否有无效的裁剪值（裁剪值过大导致裁剪区域太小或不存在）
      final bool invalidCropping =
          safeCropLeft + safeCropRight >= imageSize.width ||
              safeCropTop + safeCropBottom >= imageSize.height;

      if (invalidCropping) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法应用变换：裁剪值过大，导致裁剪区域无效'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 判断是否是初始状态（没有裁剪和其他变换）
      final bool noCropping = safeCropLeft == 0 &&
          safeCropRight == 0 &&
          safeCropTop == 0 &&
          safeCropBottom == 0;
      final bool isInitialState = noCropping && !hasOtherTransforms;

      // 即使没有变换，也允许用户应用变换操作，以支持历史回退
      if (isInitialState) {
        // 标记已应用变换，但使用原始图像
        content['isTransformApplied'] = true;
        // 确保删除任何之前的变换图像数据
        content.remove('transformedImageData');
        content.remove('transformedImageUrl');

        // 记录变换区域信息，即使使用原始图像
        content['transformRect'] = {
          'x': 0,
          'y': 0,
          'width': renderSize.width,
          'height': renderSize.height,
          'originalWidth': renderSize.width,
          'originalHeight': renderSize.height,
        };

        // 更新内容
        _updateProperty('content', content);

        // 通知控制器元素已更新，触发画布重绘
        controller.notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已应用变换：使用原始图像'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 使用 Future 处理异步操作
      Future(() async {
        try {
          // 添加详细的调试日志，记录尺寸信息
          debugPrint('=== 开始应用变换 ===');
          debugPrint(
              '原始图片尺寸: ${imageSize.width}x${imageSize.height}, 渲染尺寸: ${renderSize.width}x${renderSize.height}');
          debugPrint(
              '用户设置的裁剪值: 左=$originalCropLeft, 上=$originalCropTop, 右=$originalCropRight, 下=$originalCropBottom');
          debugPrint('最大裁剪值: maxWidth=$maxCropWidth, maxHeight=$maxCropHeight');

          // 计算比例因子 - 原始图像尺寸与渲染尺寸的比例
          final scaleX = imageSize.width / renderSize.width;
          final scaleY = imageSize.height / renderSize.height;
          final scale = math.min(scaleX, scaleY); // 保持宽高比
          debugPrint('缩放比例: scaleX=$scaleX, scaleY=$scaleY, 取最小值=$scale');

          // =====================================================================
          // 重要说明：裁剪值的处理涉及两个坐标系
          // 1. UI坐标系：用户在界面上通过滑块设置的值，基于渲染尺寸（renderSize）
          // 2. 图像坐标系：实际应用裁剪的像素位置，基于原始图像尺寸（imageSize）
          //
          // 需要将UI坐标系中的裁剪值转换为图像坐标系中的裁剪区域
          // =====================================================================

          // 改用这种方式计算裁剪区域
          // 第一步：获取UI坐标系中的裁剪值（通过滑块设置的值）
          final displayedWidth = renderSize.width;
          final displayedHeight = renderSize.height;

          // 这些值是在UI上设置的，基于renderSize
          final cropLeft = originalCropLeft; // UI左边裁剪量
          final cropTop = originalCropTop; // UI上边裁剪量
          final cropRight = originalCropRight; // UI右边裁剪量
          final cropBottom = originalCropBottom; // UI下边裁剪量

          debugPrint(
              '原始裁剪值(UI坐标系): 左=$cropLeft, 上=$cropTop, 右=$cropRight, 下=$cropBottom');
          debugPrint('渲染区域尺寸: 宽=$displayedWidth, 高=$displayedHeight');

          // 验证UI裁剪值是否合理
          if (cropLeft + cropRight >= displayedWidth ||
              cropTop + cropBottom >= displayedHeight) {
            debugPrint('警告: 裁剪值总和超过了渲染区域的尺寸，可能会导致计算错误');
          }

          // 第二步：将UI坐标系裁剪值转换为图像坐标系裁剪值

          // 重要说明: 这里的转换需要与预览画布中的线框计算保持一致
          // 预览计算考虑了图像在画布中的偏移和缩放，我们在实际裁剪时也需要同样处理

          // 使用比例因子将UI上的裁剪值转换为原始图像上的像素数
          final widthRatio = imageSize.width / displayedWidth; // 宽度比例因子
          final heightRatio = imageSize.height / displayedHeight; // 高度比例因子
          debugPrint('坐标转换比例: 宽度=$widthRatio, 高度=$heightRatio');

          // 使用相同的计算方法将UI裁剪值转换为图像坐标
          // 注意：这里的计算必须与预览线框计算保持一致，否则会导致裁剪结果与预览不符
          final cropAreaLeft = cropLeft * widthRatio;
          final cropAreaTop = cropTop * heightRatio;
          final cropAreaRight = cropRight * widthRatio;
          final cropAreaBottom = cropBottom * heightRatio;

          // 计算裁剪矩形在原始图像上的位置
          var left = cropAreaLeft;
          var top = cropAreaTop;
          var right = imageSize.width - cropAreaRight;
          var bottom = imageSize.height - cropAreaBottom;

          debugPrint(
              '原始UI裁剪值转换后: 左=$cropAreaLeft, 上=$cropAreaTop, 右=$cropAreaRight, 下=$cropAreaBottom');
          debugPrint('转换后的裁剪区域(图像坐标系): 左=$left, 上=$top, 右=$right, 下=$bottom');
          debugPrint('裁剪区域大小: 宽=${right - left}, 高=${bottom - top}');

          // 确保裁剪矩形有合理的最小尺寸（至少为原始图像尺寸的1%）
          final minWidth = imageSize.width * 0.01;
          final minHeight = imageSize.height * 0.01;

          if (right - left < minWidth) {
            // 如果宽度太小，增加右边界
            right = left + minWidth;
            // 确保不超出图像边界
            if (right > imageSize.width) {
              right = imageSize.width;
              left = right - minWidth;
            }
          }

          if (bottom - top < minHeight) {
            // 如果高度太小，增加底部边界
            bottom = top + minHeight;
            // 确保不超出图像边界
            if (bottom > imageSize.height) {
              bottom = imageSize.height;
              top = bottom - minHeight;
            }
          }

          debugPrint('调整后的裁剪区域: 左=$left, 上=$top, 右=$right, 下=$bottom');
          debugPrint('调整后裁剪区域大小: 宽=${right - left}, 高=${bottom - top}');

          // 确保裁剪矩形有效（宽度和高度至少为1像素）
          if (right <= left) {
            right = left + 1;
          }
          if (bottom <= top) {
            bottom = top + 1;
          }

          final cropRect = Rect.fromLTRB(left, top, right, bottom);

          debugPrint(
              '转换后的实际裁剪矩形: left=${cropRect.left}, top=${cropRect.top}, right=${cropRect.right}, bottom=${cropRect.bottom}');
          debugPrint(
              '裁剪区域尺寸: width=${cropRect.width}, height=${cropRect.height}');

          final effectiveCropLeft = cropRect.left;
          final effectiveCropTop = cropRect.top;
          final effectiveCropRight = imageSize.width - cropRect.right;
          final effectiveCropBottom = imageSize.height - cropRect.bottom;

          debugPrint(
              '有效裁剪值(像素): 左=$effectiveCropLeft, 上=$effectiveCropTop, 右=$effectiveCropRight, 下=$effectiveCropBottom');

          // 计算裁剪区域相对于原始图像的百分比
          final percentLeft =
              (effectiveCropLeft / imageSize.width * 100).toStringAsFixed(2);
          final percentTop =
              (effectiveCropTop / imageSize.height * 100).toStringAsFixed(2);
          final percentRight =
              (effectiveCropRight / imageSize.width * 100).toStringAsFixed(2);
          final percentBottom =
              (effectiveCropBottom / imageSize.height * 100).toStringAsFixed(2);

          debugPrint(
              '裁剪百分比: 左=$percentLeft%, 上=$percentTop%, 右=$percentRight%, 下=$percentBottom%');
          debugPrint('=== 裁剪参数准备完成 ===');

          // 异步加载图像
          Uint8List? imageData = await _loadImageFromUrl(imageUrl);

          if (imageData == null) {
            // 关闭加载对话框
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('无法加载图像数据'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          final image = img.decodeImage(imageData);
          if (image == null) {
            // 关闭加载对话框
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('无法解码图像'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          // 使用转换后的 Image 对象
          final croppedImage =
              ref.read(imageProcessorProvider).rotateAndCropImage(
                    image,
                    cropRect,
                    contentRotation,
                    flipHorizontal: flipHorizontal,
                    flipVertical: flipVertical,
                  );

          final transformedImageData =
              Uint8List.fromList(img.encodePng(croppedImage));

          // 将变换后的图像数据直接存储到元素中
          content['transformedImageData'] = transformedImageData;
          content['isTransformApplied'] = true;

          // 构建成功消息
          String message = '变换已应用到图片';
          if (noCropping) {
            message += ' (无裁剪，但应用了其他变换)';
          } else {
            message +=
                ' (裁剪: 左${originalCropLeft.toInt()}px, 上${originalCropTop.toInt()}px, 右${originalCropRight.toInt()}px, 下${originalCropBottom.toInt()}px)';
          }

          // 关闭加载对话框并更新UI
          if (context.mounted) {
            // 更新内容
            _updateProperty('content', content);

            // 显示成功消息
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          // 记录错误
          debugPrint('应用变换时出错: $e');

          // 显示错误信息
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('应用变换失败: ${e.toString()}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      });
    } else {
      // 如果图片尺寸信息不可用，显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法应用变换：图片尺寸信息不可用'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 修改裁剪滑块部分
  Widget _buildCropSlider({
    required String label,
    required String cropKey,
    required double value,
    required double max,
  }) {
    // 确保 max 至少为 1.0，避免 Slider 的 min 和 max 相同
    final safeMax = max > 0 ? max : 1.0;
    // 确保 value 在有效范围内
    final safeValue = value.clamp(0.0, safeMax);
    // 计算百分比
    final percentage = max > 0 ? (safeValue / safeMax * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: safeValue,
                min: 0,
                max: safeMax,
                onChanged: (newValue) {
                  updateCropValue(cropKey, newValue);
                },
              ),
            ),
            SizedBox(
              width: 70,
              child: Text('$percentage%'),
            ),
          ],
        ),
      ],
    );
  }

  // 适应模式按钮
  Widget _buildFitModeButton(String mode, String label, String currentMode) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: currentMode == mode ? Colors.blue : null,
        foregroundColor: currentMode == mode ? Colors.white : null,
      ),
      onPressed: () => _updateContentProperty('fitMode', mode),
      child: Text(label),
    );
  }

  // 修改图片预览部分
  Widget _buildImagePreviewWithTransformBox({
    required String imageUrl,
    required String fitMode,
    required double cropTop,
    required double cropBottom,
    required double cropLeft,
    required double cropRight,
    required bool flipHorizontal,
    required bool flipVertical,
    required double contentRotation,
    required bool isTransformApplied,
  }) {
    // 图片预览始终使用"contain"适应模式，忽略fitMode参数
    const previewFitMode = 'contain';

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
        color: Colors.grey.shade200,
      ),
      child: imageUrl.isNotEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                debugPrint(
                    'LayoutBuilder约束: ${constraints.maxWidth}x${constraints.maxHeight}');
                return Stack(
                  children: [
                    // 原始图片显示
                    Positioned.fill(
                      child: ClipRect(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..scale(
                              flipHorizontal ? -1.0 : 1.0,
                              flipVertical ? -1.0 : 1.0,
                            ),
                          alignment: Alignment.center,
                          child: _buildImageWithSizeListener(
                            imageUrl: imageUrl,
                            fitMode: _getFitMode(previewFitMode),
                            onImageSizeAvailable:
                                (Size imageSize, Size renderSize) {
                              // 使用Future.microtask延迟状态更新，避免在构建过程中修改状态
                              Future.microtask(() {
                                // 只更新图片尺寸信息，不更新裁剪值
                                updateImageState(imageSize, renderSize);

                                // 打印调试信息
                                debugPrint(
                                    '图片尺寸已更新: ${imageSize.width}x${imageSize.height}');
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    // 无论图像尺寸信息是否可用，都尝试显示变换预览矩形线框
                    // 在_buildTransformPreviewRect方法中会根据条件判断是否实际绘制
                    _buildTransformPreviewRect(
                      containerConstraints: constraints,
                      cropTop: cropTop,
                      cropBottom: cropBottom,
                      cropLeft: cropLeft,
                      cropRight: cropRight,
                      contentRotation: contentRotation,
                      flipHorizontal: flipHorizontal,
                      flipVertical: flipVertical,
                      fitMode: previewFitMode,
                    ),
                  ],
                );
              },
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('没有选择图片', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
    );
  }

  // 构建带尺寸监听的图片
  Widget _buildImageWithSizeListener({
    required String imageUrl,
    required BoxFit fitMode,
    required Function(Size, Size) onImageSizeAvailable,
  }) {
    // 判断是否是本地文件路径
    if (imageUrl.startsWith('file://')) {
      try {
        // 修正Windows路径格式
        String filePath = imageUrl.substring(7); // 移除 'file://' 前缀

        debugPrint('处理后的文件路径: $filePath');

        final file = File(filePath);
        if (!file.existsSync()) {
          debugPrint('文件不存在: $filePath');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  '文件不存在: $filePath',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final imageProvider = FileImage(file);

            // 预加载图片并获取其尺寸
            final imageStream = imageProvider.resolve(ImageConfiguration(
              size: constraints.biggest,
            ));

            imageStream.addListener(ImageStreamListener(
              (ImageInfo info, bool _) {
                final imageSize = Size(
                  info.image.width.toDouble(),
                  info.image.height.toDouble(),
                );

                // 计算渲染尺寸
                final renderSize = _calculateRenderSize(
                    imageSize,
                    constraints.biggest,
                    fitMode == BoxFit.contain
                        ? 'contain'
                        : fitMode == BoxFit.cover
                            ? 'cover'
                            : fitMode == BoxFit.fill
                                ? 'fill'
                                : 'none');

                // 使用WidgetsBinding.instance.addPostFrameCallback避免在构建过程中调用setState
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // 调用回调
                  onImageSizeAvailable(imageSize, renderSize);
                });
              },
              onError: (exception, stackTrace) {
                debugPrint('图片加载错误: $exception');
              },
            ));

            return Image(
              image: imageProvider,
              fit: fitMode,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (frame == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return child;
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('图片加载错误: $error');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        '无法加载图片: ${error.toString().substring(0, math.min(error.toString().length, 50))}...',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      } catch (e) {
        debugPrint('处理文件路径时出错: $e');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                '处理文件路径时出错: ${e.toString()}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    } else {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final imageProvider = NetworkImage(imageUrl);

          // 预加载图片并获取其尺寸
          final imageStream = imageProvider.resolve(ImageConfiguration(
            size: constraints.biggest,
          ));

          imageStream.addListener(ImageStreamListener(
            (ImageInfo info, bool _) {
              final imageSize = Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              );

              // 计算渲染尺寸
              final renderSize = _calculateRenderSize(
                  imageSize,
                  constraints.biggest,
                  fitMode == BoxFit.contain
                      ? 'contain'
                      : fitMode == BoxFit.cover
                          ? 'cover'
                          : fitMode == BoxFit.fill
                              ? 'fill'
                              : 'none');

              // 使用WidgetsBinding.instance.addPostFrameCallback避免在构建过程中调用setState
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // 调用回调
                onImageSizeAvailable(imageSize, renderSize);
              });
            },
            onError: (exception, stackTrace) {
              debugPrint('图片加载错误: $exception');
            },
          ));

          return Image(
            image: imageProvider,
            fit: fitMode,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return child;
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('图片加载错误: $error');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      '无法加载图片: ${error.toString().substring(0, math.min(error.toString().length, 50))}...',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }

  // 旋转按钮
  Widget _buildRotationButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  // 构建变换预览矩形框
  Widget _buildTransformPreviewRect({
    required BoxConstraints containerConstraints,
    required double cropTop,
    required double cropBottom,
    required double cropLeft,
    required double cropRight,
    required double contentRotation,
    required bool flipHorizontal,
    required bool flipVertical,
    required String fitMode,
  }) {
    final currentImageSize = imageSize;
    final currentRenderSize = renderSize;

    if (currentImageSize == null || currentRenderSize == null) {
      debugPrint('图片尺寸或渲染尺寸为null，不显示裁剪框');
      return const SizedBox();
    }

    return SizedBox(
      width: containerConstraints.maxWidth,
      height: containerConstraints.maxHeight,
      child: CustomPaint(
        painter: _TransformPreviewPainter(
          imageSize: currentImageSize,
          renderSize: currentRenderSize,
          cropTop: cropTop,
          cropBottom: cropBottom,
          cropLeft: cropLeft,
          cropRight: cropRight,
          flipHorizontal: flipHorizontal,
          flipVertical: flipVertical,
          contentRotation: contentRotation,
          isTransformApplied:
              element['content']['isTransformApplied'] as bool? ?? false,
        ),
      ),
    );
  }

  // 根据适应模式计算图片实际渲染尺寸
  Size _calculateRenderSize(
      Size imageSize, Size containerSize, String fitMode) {
    final imageRatio = imageSize.width / imageSize.height;
    final containerRatio = containerSize.width / containerSize.height;

    switch (fitMode) {
      case 'contain':
        if (imageRatio > containerRatio) {
          return Size(
            containerSize.width,
            containerSize.width / imageRatio,
          );
        } else {
          return Size(
            containerSize.height * imageRatio,
            containerSize.height,
          );
        }
      case 'cover':
        if (imageRatio > containerRatio) {
          return Size(
            containerSize.height * imageRatio,
            containerSize.height,
          );
        } else {
          return Size(
            containerSize.width,
            containerSize.width / imageRatio,
          );
        }
      case 'fill':
        return containerSize;
      case 'none':
        return imageSize;
      default:
        return Size(
          math.min(imageSize.width, containerSize.width),
          math.min(imageSize.height, containerSize.height),
        );
    }
  }

  // 获取背景颜色
  Color _getBackgroundColor() {
    final content = element['content'] as Map<String, dynamic>;
    final backgroundColor = content['backgroundColor'] as String?;

    if (backgroundColor != null && backgroundColor.isNotEmpty) {
      try {
        // 处理带#前缀的颜色代码
        final colorStr = backgroundColor.startsWith('#')
            ? backgroundColor.substring(1)
            : backgroundColor;

        // 添加FF前缀表示完全不透明
        final fullColorStr = colorStr.length == 6 ? 'FF$colorStr' : colorStr;

        // 解析颜色
        return Color(int.parse(fullColorStr, radix: 16));
      } catch (e) {
        debugPrint('解析背景颜色失败: $e');
      }
    }

    // 默认返回透明色
    return Colors.transparent;
  }

  // 获取适应模式
  BoxFit _getFitMode(String fitMode) {
    switch (fitMode) {
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      case 'none':
        return BoxFit.none;
      default:
        return BoxFit.contain;
    }
  }

  // 从URL加载图像数据
  Future<Uint8List?> _loadImageFromUrl(String imageUrl) async {
    try {
      if (imageUrl.startsWith('file://')) {
        // 修正Windows路径格式
        String filePath = imageUrl.substring(7); // 移除 'file://' 前缀

        // // 将URL编码的字符转换回原始字符
        // try {
        //   filePath = Uri.decodeComponent(filePath);
        // } catch (e) {
        //   debugPrint('URI解码失败，尝试手动替换: $e');
        //   // 手动替换常见的编码字符
        //   filePath = filePath
        //       .replaceAll('%20', ' ')
        //       .replaceAll('%2F', '/')
        //       .replaceAll('%3A', ':')
        //       .replaceAll('%5C', '\\')
        //       .replaceAll('%25', '%');
        // }

        // // 确保使用正确的路径分隔符
        // if (Platform.isWindows && filePath.startsWith('/')) {
        //   filePath = filePath.substring(1); // 移除开头的斜杠
        //   filePath = filePath.replaceAll('/', '\\'); // 替换路径分隔符
        // }

        debugPrint('加载图像数据的文件路径: $filePath');

        // 从本地文件加载
        final file = File(filePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        } else {
          debugPrint('文件不存在: $filePath');
          return null;
        }
      } else {
        // 从网络加载
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          debugPrint('HTTP请求失败: ${response.statusCode}');
          return null;
        }
      }
    } catch (e) {
      debugPrint('加载图像数据失败: $e');
    }
    return null;
  }

  // 重置变换
  void _resetTransform(BuildContext context) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    // 重置所有变换参数
    content['cropTop'] = 0.0;
    content['cropBottom'] = 0.0;
    content['cropLeft'] = 0.0;
    content['cropRight'] = 0.0;
    content['isFlippedHorizontally'] = false;
    content['isFlippedVertically'] = false;
    content['rotation'] = 0.0;
    content['isTransformApplied'] = false;

    // 删除变换后的图像数据
    content.remove('transformedImageData');
    content.remove('transformedImageUrl');
    content.remove('transformRect');

    // 更新内容
    _updateProperty('content', content);

    // 保持图片尺寸信息，但重置加载状态
    if (imageSize != null && renderSize != null) {
      updateImageState(imageSize, renderSize);
    }

    // 通知用户重置成功
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已重置所有变换'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 从本地选择图片
  Future<void> _selectImageFromLocal(BuildContext context) async {
    // 调用onSelectImage回调，该回调应该在上层实现文件选择功能
    onSelectImage();
  }

  // 更新内容属性
  void _updateContentProperty(String key, dynamic value) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    content[key] = value;

    // 注意：这里不设置 isTransformApplied = true
    // 只有在用户点击"应用变换"按钮时，才会设置该标志
    // 这样确保变换参数的变化不会立即影响画布上的图片元素

    _updateProperty('content', content);
  }

  // 更新属性
  void _updateProperty(String key, dynamic value) {
    // 创建更新对象
    final updates = {key: value};

    // 调用属性变更回调
    onElementPropertiesChanged(updates);

    // 保持图片尺寸信息
    final currentImageSize = imageSize;
    final currentRenderSize = renderSize;
    if (currentImageSize != null && currentRenderSize != null) {
      updateImageState(currentImageSize, currentRenderSize);
    }
  }
}

class _DashedDecorationPainter extends BoxPainter {
  final Color color;
  final BorderRadius? borderRadius;
  final double strokeWidth;
  final double gap;
  final Color dashedColor;
  final DashedDecoration decoration;

  _DashedDecorationPainter({
    required this.color,
    required this.borderRadius,
    required this.strokeWidth,
    required this.gap,
    required this.dashedColor,
    required this.decoration,
  }) : super(null);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 绘制填充背景
    if (borderRadius != null) {
      canvas.drawRRect(
        borderRadius!.toRRect(rect),
        paint,
      );
    } else {
      canvas.drawRect(rect, paint);
    }

    // 绘制虚线边框
    final dashPaint = Paint()
      ..color = dashedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // 绘制虚线
    final path = Path();
    if (borderRadius != null) {
      path.addRRect(borderRadius!.toRRect(rect));
    } else {
      path.addRect(rect);
    }

    // 使用DashPathEffect绘制虚线
    // 这里简化实现，实际项目中可以使用更高级的库来绘制虚线
    final dashPath = _dashPath(path, gap);
    canvas.drawPath(dashPath, dashPaint);
  }

  Path _dashPath(Path path, double gap) {
    final dashedPath = Path();
    const distance = 4.0; // 每段虚线的长度

    for (var i = 0.0; i < 1.0; i += distance + gap) {
      dashedPath.addPath(
        path,
        Offset.zero,
        matrix4: Matrix4.translationValues(i, i, 0.0).storage,
      );
    }

    return dashedPath;
  }
}

class _TransformPreviewPainter extends CustomPainter {
  final Size imageSize;
  final Size renderSize;
  final double cropTop;
  final double cropBottom;
  final double cropLeft;
  final double cropRight;
  final bool flipHorizontal;
  final bool flipVertical;
  final double contentRotation;
  final bool isTransformApplied;

  const _TransformPreviewPainter({
    required this.imageSize,
    required this.renderSize,
    required this.cropTop,
    required this.cropBottom,
    required this.cropLeft,
    required this.cropRight,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.contentRotation,
    required this.isTransformApplied,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 如果画布尺寸为0，无法绘制
    if (size.width <= 0 || size.height <= 0) {
      debugPrint('画布尺寸为0，无法绘制裁剪框');
      return;
    }

    debugPrint('=== 绘制裁剪预览框 ===');
    debugPrint('预览画布尺寸: ${size.width}x${size.height}');
    debugPrint(
        '图像尺寸: ${imageSize.width}x${imageSize.height}, 渲染尺寸: ${renderSize.width}x${renderSize.height}');
    debugPrint('裁剪值: 上=$cropTop, 下=$cropBottom, 左=$cropLeft, 右=$cropRight');
    debugPrint('旋转角度: $contentRotation°');

    // ============ 第1步：绘制整个画布的蓝色边框 ============
    final imageBorderPaint = Paint()
      ..color = Colors.blue.withAlpha(128)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final canvasRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(canvasRect, imageBorderPaint);
    debugPrint('绘制画布边框(蓝色): $canvasRect');

    // ============ 第2步：计算图像在画布上的显示位置 ============
    // 计算原始图像缩放到画布大小的比例
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = math.min(scaleX, scaleY); // 保持宽高比

    // 计算图像在画布上的实际尺寸
    final scaledImageWidth = imageSize.width * scale;
    final scaledImageHeight = imageSize.height * scale;

    // 计算图像在画布上的居中偏移量
    final offsetX = (size.width - scaledImageWidth) / 2;
    final offsetY = (size.height - scaledImageHeight) / 2;

    // 创建图像在画布上的实际矩形区域
    final actualImageRect =
        Rect.fromLTWH(offsetX, offsetY, scaledImageWidth, scaledImageHeight);

    debugPrint('缩放比例: scaleX=$scaleX, scaleY=$scaleY, 取最小值=$scale');
    debugPrint('缩放后的图像尺寸: ${scaledImageWidth}x$scaledImageHeight');
    debugPrint('图像偏移量: X=$offsetX, Y=$offsetY');
    debugPrint('实际图像区域(绿色): $actualImageRect');

    // 绘制图像区域的绿色边框
    final greenBorderPaint = Paint()
      ..color = Colors.green.withAlpha(179)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(actualImageRect, greenBorderPaint);

    // ============ 第3步：计算裁剪区域 ============
    // 计算UI坐标（渲染尺寸）到画布坐标（预览画布尺寸）的缩放比例
    // 注意：这不同于原始图像到画布的缩放比例

    // 获取图像实际显示区域的尺寸
    final displayWidth = actualImageRect.width;
    final displayHeight = actualImageRect.height;

    // 计算渲染尺寸到实际显示区域的比例
    // 这个比例用于将UI裁剪值（基于渲染尺寸）转换为画布上实际显示区域的坐标
    final uiToDisplayScaleX = displayWidth / renderSize.width;
    final uiToDisplayScaleY = displayHeight / renderSize.height;

    debugPrint('渲染尺寸: 宽=${renderSize.width}, 高=${renderSize.height}');
    debugPrint('实际显示尺寸: 宽=$displayWidth, 高=$displayHeight');
    debugPrint('UI到显示区域的缩放比例: X=$uiToDisplayScaleX, Y=$uiToDisplayScaleY');
    debugPrint(
        '图像偏移量(画布坐标): X=${actualImageRect.left}, Y=${actualImageRect.top}');

    // 重要：这里的关键是正确处理图像在画布中的偏移和缩放
    // 1. 先将UI裁剪值按照比例缩放到实际显示大小
    // 2. 然后考虑图像在画布中的偏移量（当图像不填满画布时会居中显示）

    // 修正：根据缩放比例将UI裁剪值转换为画布上的实际裁剪区域
    // 相对于图像实际显示区域的左上角计算裁剪区域
    final cropRectLeft = actualImageRect.left + (cropLeft * uiToDisplayScaleX);
    final cropRectTop = actualImageRect.top + (cropTop * uiToDisplayScaleY);
    final cropRectRight =
        actualImageRect.right - (cropRight * uiToDisplayScaleX);
    final cropRectBottom =
        actualImageRect.bottom - (cropBottom * uiToDisplayScaleY);

    // 创建裁剪矩形
    final cropRect =
        Rect.fromLTRB(cropRectLeft, cropRectTop, cropRectRight, cropRectBottom);

    debugPrint(
        '裁剪区域计算: Left=$cropRectLeft, Top=$cropRectTop, Right=$cropRectRight, Bottom=$cropRectBottom');
    debugPrint('最终裁剪区域: $cropRect, 宽=${cropRect.width}, 高=${cropRect.height}');

    // ============ 第4步：绘制裁剪区域和遮罩 ============
    // 只有当裁剪矩形有效时才绘制
    if (cropRect.width > 0 && cropRect.height > 0) {
      // 获取裁剪区域中心点（用于旋转）
      final centerX = cropRect.center.dx;
      final centerY = cropRect.center.dy;

      // 创建一个Path来表示旋转后的裁剪区域
      Path rotatedCropPath = Path();

      if (contentRotation != 0) {
        // 旋转角度转弧度
        final rotationRadians = contentRotation * (math.pi / 180.0);

        // 创建变换矩阵
        final matrix4 = Matrix4.identity()
          ..translate(centerX, centerY)
          ..rotateZ(rotationRadians)
          ..translate(-centerX, -centerY);

        // 创建裁剪区域路径并应用旋转变换
        rotatedCropPath.addRect(cropRect);
        rotatedCropPath = rotatedCropPath.transform(matrix4.storage);
      } else {
        // 无旋转，直接使用原始矩形
        rotatedCropPath.addRect(cropRect);
      }

      // 绘制遮罩层 - 不会随旋转而旋转
      final maskPaint = Paint()
        ..color = Colors.black.withAlpha(128)
        ..style = PaintingStyle.fill;

      // 创建遮罩路径：整个图像区域减去旋转后的裁剪区域
      final maskPath = Path()..addRect(actualImageRect);
      maskPath.addPath(rotatedCropPath, Offset.zero);
      maskPath.fillType = PathFillType.evenOdd;

      canvas.drawPath(maskPath, maskPaint);
      debugPrint('绘制裁剪区域外的半透明遮罩');

      // 绘制旋转的裁剪框和标记点
      canvas.save();

      if (contentRotation != 0) {
        // 应用旋转变换
        canvas.translate(centerX, centerY);
        canvas.rotate(contentRotation * (math.pi / 180.0));
        canvas.translate(-centerX, -centerY);
      }

      // 绘制裁剪区域的红色边框
      final borderPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(cropRect, borderPaint);
      debugPrint('绘制裁剪区域红色边框');

      // 绘制四个角落的标记
      const cornerSize = 8.0;
      final cornerPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      // 左上角
      canvas.drawRect(
          Rect.fromLTWH(cropRect.left - cornerSize / 2,
              cropRect.top - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // 右上角
      canvas.drawRect(
          Rect.fromLTWH(cropRect.right - cornerSize / 2,
              cropRect.top - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // 左下角
      canvas.drawRect(
          Rect.fromLTWH(cropRect.left - cornerSize / 2,
              cropRect.bottom - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // 右下角
      canvas.drawRect(
          Rect.fromLTWH(cropRect.right - cornerSize / 2,
              cropRect.bottom - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      debugPrint('绘制四个红色角标');

      // 恢复画布状态
      canvas.restore();
    } else {
      debugPrint('裁剪矩形无效，宽度或高度小于等于0');
    }

    debugPrint('=== 裁剪预览框绘制完成 ===');
  }

  @override
  bool shouldRepaint(covariant _TransformPreviewPainter oldDelegate) {
    return imageSize != oldDelegate.imageSize ||
        renderSize != oldDelegate.renderSize ||
        cropTop != oldDelegate.cropTop ||
        cropBottom != oldDelegate.cropBottom ||
        cropLeft != oldDelegate.cropLeft ||
        cropRight != oldDelegate.cropRight ||
        flipHorizontal != oldDelegate.flipHorizontal ||
        flipVertical != oldDelegate.flipVertical ||
        contentRotation != oldDelegate.contentRotation ||
        isTransformApplied != oldDelegate.isTransformApplied;
  }
}
