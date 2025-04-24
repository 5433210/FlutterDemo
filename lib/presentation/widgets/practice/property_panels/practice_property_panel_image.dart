import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:demo/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

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

class ImagePreview extends StatefulWidget {
  final String imageUrl;
  final String fitMode;
  final double cropTop;
  final double cropBottom;
  final double cropLeft;
  final double cropRight;
  final bool flipHorizontal;
  final bool flipVertical;
  final double contentRotation;
  final bool isTransformApplied;

  const ImagePreview({
    Key? key,
    required this.imageUrl,
    required this.fitMode,
    required this.cropTop,
    required this.cropBottom,
    required this.cropLeft,
    required this.cropRight,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.contentRotation,
    required this.isTransformApplied,
  }) : super(key: key);

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
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
    // 首先尝试获取原始图片尺寸
    final imageSize = this.imageSize;
    if (imageSize != null) {
      return imageSize.height;
    }

    // 如果原始图片尺寸不可用，则使用属性中记录的尺寸
    final content = element['content'] as Map<String, dynamic>;
    final height = content['originalHeight'] as num?;
    if (height != null) {
      return height.toDouble();
    }

    // 如果都没有，返回一个默认值
    return 0.0;
  }

  // 获取最大裁剪值
  double get maxCropWidth {
    // 首先尝试获取原始图片尺寸
    final imageSize = this.imageSize;
    if (imageSize != null) {
      return imageSize.width;
    }

    // 如果原始图片尺寸不可用，则使用属性中记录的尺寸
    final content = element['content'] as Map<String, dynamic>;
    final width = content['originalWidth'] as num?;
    if (width != null) {
      return width.toDouble();
    }

    // 如果都没有，返回一个默认值
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
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
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: const Text(
                      '注意: 长时间显示重复日志属于正常现象，不影响功能',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ImagePreview(
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
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
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

                  // 上下裁剪滑块
                  const Text('上下裁剪:'),
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
                      SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                '上: ${cropTop.toStringAsFixed(0)}/${maxCropHeight.toStringAsFixed(0)}px'),
                            Text(
                                '下: ${cropBottom.toStringAsFixed(0)}/${maxCropHeight.toStringAsFixed(0)}px'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 左右裁剪滑块
                  const Text('左右裁剪:'),
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
                      SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                '左: ${cropLeft.toStringAsFixed(0)}/${maxCropWidth.toStringAsFixed(0)}px'),
                            Text(
                                '右: ${cropRight.toStringAsFixed(0)}/${maxCropWidth.toStringAsFixed(0)}px'),
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
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            // 获取图片内容旋转值
                            final contentRotation =
                                (content['rotation'] as num?)?.toDouble() ??
                                    0.0;
                            // 确保旋转值在滑块范围内
                            final safeRotation =
                                contentRotation.clamp(-180.0, 180.0);
                            return Slider(
                              value: safeRotation,
                              min: -180.0,
                              max: 180.0,
                              divisions: 360,
                              label: '${safeRotation.toStringAsFixed(0)}°',
                              onChanged: (value) {
                                setState(() {});
                                _updateContentProperty('rotation', value);
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                            '${(content['rotation'] as num?)?.toDouble() ?? 0.0}°'),
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

      // 根据裁剪方向计算最大值
      double maxValue;
      if (key == 'cropTop' || key == 'cropBottom') {
        maxValue = imageSize.height / 2;
      } else {
        maxValue = imageSize.width / 2;
      }

      // 确保裁剪值在有效范围内
      final safeValue = value.clamp(0.0, maxValue);

      // 更新裁剪值
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
      // 限制裁剪值不超过图片尺寸的一半
      final maxCropWidth = renderSize.width / 2;
      final maxCropHeight = renderSize.height / 2;

      // 确保裁剪值在有效范围内
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

      // 更新裁剪值
      content['cropTop'] = safeCropTop;
      content['cropBottom'] = safeCropBottom;
      content['cropLeft'] = safeCropLeft;
      content['cropRight'] = safeCropRight;

      // 判断是否是初始状态（没有裁剪）
      final bool noCropping = safeCropLeft == 0 &&
          safeCropRight == 0 &&
          safeCropTop == 0 &&
          safeCropBottom == 0;

      // 判断是否有其他变换
      final bool hasOtherTransforms =
          flipHorizontal || flipVertical || contentRotation != 0.0;

      // 保存变换区域信息 - 这些参数将用于在画布上绘制时提取变换区域
      content['transformRect'] = {
        'x': safeCropLeft,
        'y': safeCropTop,
        'width': renderSize.width - safeCropLeft - safeCropRight,
        'height': renderSize.height - safeCropTop - safeCropBottom,
        'originalWidth': renderSize.width,
        'originalHeight': renderSize.height,
      };

      // 如果没有任何变换，则直接标记应用变换并返回
      if (noCropping && !hasOtherTransforms) {
        // 标记已应用变换，但不需要实际生成变换后的图像
        content['isTransformApplied'] = true;
        // 确保删除任何之前的变换图像数据
        content.remove('transformedImageData');
        content.remove('transformedImageUrl');

        // 更新内容
        _updateProperty('content', content);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无需应用变换：使用原始图像'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 使用 Future 处理异步操作
      Future(() async {
        try {
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
          final croppedImage = ref
              .read(imageProcessorProvider)
              .rotateAndCropImage(
                  image,
                  Rect.fromLTRB(
                      safeCropLeft,
                      safeCropTop,
                      imageSize.width - safeCropRight,
                      imageSize.height - safeCropBottom),
                  contentRotation);

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
                ' (裁剪: 左${safeCropLeft.toInt()}px, 上${safeCropTop.toInt()}px, 右${safeCropRight.toInt()}px, 下${safeCropBottom.toInt()}px)';
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('应用变换失败: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
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

                    // 只有在图像尺寸信息可用时才显示变换预览矩形线框
                    if (isImageLoaded)
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

                // 调用回调
                onImageSizeAvailable(imageSize, renderSize);
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

              // 调用回调
              onImageSizeAvailable(imageSize, renderSize);
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
      return const SizedBox();
    }

    return CustomPaint(
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

  // 修改_forceUpdateCropSliders方法
  void _forceUpdateCropSliders(Map<String, dynamic> content) {
    final cropTop = (content['cropTop'] as num?)?.toDouble() ?? 0.0;
    final cropBottom = (content['cropBottom'] as num?)?.toDouble() ?? 0.0;
    final cropLeft = (content['cropLeft'] as num?)?.toDouble() ?? 0.0;
    final cropRight = (content['cropRight'] as num?)?.toDouble() ?? 0.0;

    // debugPrint(
    //     '强制更新裁剪滑块: top=$cropTop, bottom=$cropBottom, left=$cropLeft, right=$cropRight, isLoaded=${_imageSizeStateHolder.isImageLoaded}');

    // 确保图片加载状态为true
    if (!isImageLoaded) {
      updateImageState(imageSize, renderSize);
    }

    // 设置裁剪值通知器
    updateCropValue('cropTop', cropTop);
    updateCropValue('cropBottom', cropBottom);
    updateCropValue('cropLeft', cropLeft);
    updateCropValue('cropRight', cropRight);
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

  // 获取图片尺寸的辅助方法
  Future<Size> _getImageSize(ImageProvider provider) async {
    final Completer<Size> completer = Completer<Size>();
    final ImageStream stream = provider.resolve(const ImageConfiguration());

    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) {
        final Size size = Size(
          imageInfo.image.width.toDouble(),
          imageInfo.image.height.toDouble(),
        );
        completer.complete(size);
      },
      onError: (exception, stackTrace) {
        completer.complete(const Size(0, 0));
      },
    );

    stream.addListener(listener);

    return completer.future.then((Size size) {
      stream.removeListener(listener);
      return size;
    });
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

  // 修改图片尺寸监听方法
  void _onImageSizeAvailable(Size imageSize, Size renderSize) {
    updateImageSizeInfo(imageSize, renderSize);
  }

  // 预加载并测量图片尺寸
  void _preloadAndMeasureImage(
      String imageUrl, Function(Size) onSizeAvailable) {
    if (imageUrl.startsWith('file://')) {
      // 修正Windows路径格式
      String filePath = imageUrl.substring(7); // 移除 'file://' 前缀

      // 将URL编码的字符转换回原始字符
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

      debugPrint('预加载图片路径: $filePath');

      try {
        final file = File(filePath);
        if (!file.existsSync()) {
          debugPrint('文件不存在: $filePath');
          onSizeAvailable(const Size(0, 0));
          return;
        }

        // 使用dart:ui的Image类来获取图片尺寸
        final bytes = file.readAsBytesSync();
        ui.instantiateImageCodec(bytes).then((codec) {
          return codec.getNextFrame();
        }).then((frame) {
          final image = frame.image;
          onSizeAvailable(
              Size(image.width.toDouble(), image.height.toDouble()));
        }).catchError((error) {
          debugPrint('解码图片失败: $error');
          onSizeAvailable(const Size(0, 0));
        });
      } catch (e) {
        debugPrint('读取文件失败: $e');
        onSizeAvailable(const Size(0, 0));
      }
    } else {
      // 处理网络图片
      final imageProvider = NetworkImage(imageUrl);
      _getImageSize(imageProvider).then((Size imageSize) {
        if (imageSize.width > 0 && imageSize.height > 0) {
          onSizeAvailable(imageSize);
        } else {
          debugPrint('获取图片尺寸失败: 宽度或高度为0');
          onSizeAvailable(const Size(0, 0));
        }
      }).catchError((error) {
        debugPrint('获取图片尺寸时出错: $error');
        onSizeAvailable(const Size(0, 0));
      });
    }
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

  void _updateContentProperties() {
    final selectedElement = controller.state.getSelectedElements().first;
    final content = Map<String, dynamic>.from(
        selectedElement['content'] as Map<String, dynamic>);

    // 更新裁剪值
    content['cropTop'] = topCrop;
    content['cropBottom'] = bottomCrop;
    content['cropLeft'] = leftCrop;
    content['cropRight'] = rightCrop;

    // 更新内容
    _updatePropertySafely('content', content);
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

  // 添加一个安全的属性更新方法
  void _updatePropertySafely(String key, dynamic value) {
    // debugPrint('开始更新属性: $key = $value');
    // debugPrint('更新前状态: isImageLoaded=${_imageSizeStateHolder.isImageLoaded}');
    // debugPrint(
    //     '更新前裁剪值: left=${_imageSizeStateHolder.leftCropNotifier.value}, right=${_imageSizeStateHolder.rightCropNotifier.value}');

    // 在更新前强制保持图片加载状态
    forceKeepLoadedState();

    // 更新属性
    _updateProperty('content', value);

    // 更新后再次检查并保持状态
    forceKeepLoadedState();

    // debugPrint('更新后状态: isImageLoaded=${_imageSizeStateHolder.isImageLoaded}');
    // debugPrint(
    //     '更新后裁剪值: left=${_imageSizeStateHolder.leftCropNotifier.value}, right=${_imageSizeStateHolder.rightCropNotifier.value}');
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

class _ImagePreviewState extends State<ImagePreview>
    with AutomaticKeepAliveClientMixin {
  Size? _imageSize;
  Size? _renderSize;
  bool _isLoading = false;
  bool _isTransformApplied = false;
  final bool _isPreloading = false; // 添加预加载标志

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            _buildImageWithSizeListener(
              imageUrl: widget.imageUrl,
              fitMode: _getFitMode(),
              onImageSizeAvailable: _onImageSizeAvailable,
            ),
            if (_imageSize != null && _renderSize != null)
              _buildTransformPreviewRect(
                containerConstraints: constraints,
                cropTop: widget.cropTop,
                cropBottom: widget.cropBottom,
                cropLeft: widget.cropLeft,
                cropRight: widget.cropRight,
              ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _isTransformApplied = widget.isTransformApplied;
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

                // 调用回调
                onImageSizeAvailable(imageSize, renderSize);
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

              // 调用回调
              onImageSizeAvailable(imageSize, renderSize);
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

  // 构建变换预览矩形
  Widget _buildTransformPreviewRect({
    required BoxConstraints containerConstraints,
    required double cropTop,
    required double cropBottom,
    required double cropLeft,
    required double cropRight,
  }) {
    if (_imageSize == null || _renderSize == null) {
      return const SizedBox();
    }

    return CustomPaint(
      painter: _TransformPreviewPainter(
        imageSize: _imageSize!,
        renderSize: _renderSize!,
        cropTop: cropTop,
        cropBottom: cropBottom,
        cropLeft: cropLeft,
        cropRight: cropRight,
        flipHorizontal: widget.flipHorizontal,
        flipVertical: widget.flipVertical,
        contentRotation: widget.contentRotation,
        isTransformApplied: _isTransformApplied,
      ),
    );
  }

  // 获取适应模式
  BoxFit _getFitMode() {
    switch (widget.fitMode) {
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

  // 获取图片尺寸的辅助方法
  Future<Size> _getImageSize(ImageProvider provider) async {
    final Completer<Size> completer = Completer<Size>();
    final ImageStream stream = provider.resolve(const ImageConfiguration());

    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) {
        final Size size = Size(
          imageInfo.image.width.toDouble(),
          imageInfo.image.height.toDouble(),
        );
        completer.complete(size);
      },
      onError: (exception, stackTrace) {
        completer.complete(const Size(0, 0));
      },
    );

    stream.addListener(listener);

    return completer.future.then((Size size) {
      stream.removeListener(listener);
      return size;
    });
  }

  // 图片尺寸可用时的回调
  void _onImageSizeAvailable(Size imageSize, Size renderSize) {
    _updateImageSizeInfo(imageSize, renderSize);
  }

  // 预加载并测量图片尺寸
  void _preloadAndMeasureImage(
      String imageUrl, Function(Size) onSizeAvailable) {
    if (imageUrl.startsWith('file://')) {
      // 修正Windows路径格式
      String filePath = imageUrl.substring(7); // 移除 'file://' 前缀

      // 将URL编码的字符转换回原始字符
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

      debugPrint('预加载图片路径: $filePath');

      try {
        final file = File(filePath);
        if (!file.existsSync()) {
          debugPrint('文件不存在: $filePath');
          onSizeAvailable(const Size(0, 0));
          return;
        }

        // 使用dart:ui的Image类来获取图片尺寸
        final bytes = file.readAsBytesSync();
        ui.instantiateImageCodec(bytes).then((codec) {
          return codec.getNextFrame();
        }).then((frame) {
          final image = frame.image;
          onSizeAvailable(
              Size(image.width.toDouble(), image.height.toDouble()));
        }).catchError((error) {
          debugPrint('解码图片失败: $error');
          onSizeAvailable(const Size(0, 0));
        });
      } catch (e) {
        debugPrint('读取文件失败: $e');
        onSizeAvailable(const Size(0, 0));
      }
    } else {
      // 处理网络图片
      final imageProvider = NetworkImage(imageUrl);
      _getImageSize(imageProvider).then((Size imageSize) {
        if (imageSize.width > 0 && imageSize.height > 0) {
          onSizeAvailable(imageSize);
        } else {
          debugPrint('获取图片尺寸失败: 宽度或高度为0');
          onSizeAvailable(const Size(0, 0));
        }
      }).catchError((error) {
        debugPrint('获取图片尺寸时出错: $error');
        onSizeAvailable(const Size(0, 0));
      });
    }
  }

  // 更新图片尺寸信息
  void _updateImageSizeInfo(Size imageSize, Size renderSize) {
    if (mounted) {
      setState(() {
        _imageSize = imageSize;
        _renderSize = renderSize;
        _isLoading = false;
      });
    }
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
}

// 用于监听子部件尺寸变化的部件
class _SizeReportingWidget extends StatefulWidget {
  final Widget child;
  final Function(Size size) onSizeChange;

  const _SizeReportingWidget({
    required this.child,
    required this.onSizeChange,
  });

  @override
  _SizeReportingWidgetState createState() => _SizeReportingWidgetState();
}

class _SizeReportingWidgetState extends State<_SizeReportingWidget> {
  final _widgetKey = GlobalKey();
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _notifySize();
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: Container(
          key: _widgetKey,
          child: widget.child,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  void _notifySize() {
    final context = _widgetKey.currentContext;
    if (context == null) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    if (_oldSize != size) {
      _oldSize = size;
      widget.onSizeChange(size);
    }
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
    if (!isTransformApplied) {
      return;
    }

    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTRB(
      cropLeft,
      cropTop,
      imageSize.width - cropRight,
      imageSize.height - cropBottom,
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
