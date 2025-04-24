import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

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

  // 创建一个可变的状态持有者来存储图片尺寸信息
  // 这样可以在不违反@immutable约束的情况下修改尺寸
  final _imageStateHolder = _ImageSizeStateHolder();

  ImagePropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onSelectImage,
  }) : super(key: key, controller: controller);

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

    // 翻转属性
    final flipHorizontal = content['flipHorizontal'] as bool? ?? false;
    final flipVertical = content['flipVertical'] as bool? ?? false;

    // 内容旋转属性
    final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

    // 绘制模式
    final fitMode = content['fitMode'] as String? ?? 'contain';

    // 是否已应用变换
    final isTransformApplied = content['isTransformApplied'] as bool? ?? false;

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
                  _buildImagePreviewWithTransformBox(
                    imageUrl: imageUrl,
                    fitMode: fitMode,
                    cropTop: cropTop,
                    cropBottom: cropBottom,
                    cropLeft: cropLeft,
                    cropRight: cropRight,
                    flipHorizontal: flipHorizontal,
                    flipVertical: flipVertical,
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
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            // 计算最大裁剪值 - 图片高度的一半
                            final maxCropHeight =
                                _imageStateHolder.renderSize != null
                                    ? _imageStateHolder.renderSize!.height / 2
                                    : 100.0;

                            // 确保当前值不超过最大值
                            final safeCropTop =
                                cropTop.clamp(0.0, maxCropHeight);
                            final safeCropBottom =
                                cropBottom.clamp(0.0, maxCropHeight);

                            return Column(
                              children: [
                                Slider(
                                  value: safeCropTop,
                                  min: 0.0,
                                  max: maxCropHeight,
                                  divisions: 100,
                                  label:
                                      '上: ${safeCropTop.toStringAsFixed(0)}px',
                                  onChanged: (value) {
                                    setState(() {});
                                    _updateContentProperty('cropTop', value);
                                  },
                                ),
                                Slider(
                                  value: safeCropBottom,
                                  min: 0.0,
                                  max: maxCropHeight,
                                  divisions: 100,
                                  label:
                                      '下: ${safeCropBottom.toStringAsFixed(0)}px',
                                  onChanged: (value) {
                                    setState(() {});
                                    _updateContentProperty('cropBottom', value);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('上: ${cropTop.toStringAsFixed(0)}px'),
                            Text('下: ${cropBottom.toStringAsFixed(0)}px'),
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
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            // 计算最大裁剪值 - 图片宽度的一半
                            final maxCropWidth =
                                _imageStateHolder.renderSize != null
                                    ? _imageStateHolder.renderSize!.width / 2
                                    : 100.0;

                            // 确保当前值不超过最大值
                            final safeCropLeft =
                                cropLeft.clamp(0.0, maxCropWidth);
                            final safeCropRight =
                                cropRight.clamp(0.0, maxCropWidth);

                            return Column(
                              children: [
                                Slider(
                                  value: safeCropLeft,
                                  min: 0.0,
                                  max: maxCropWidth,
                                  divisions: 100,
                                  label:
                                      '左: ${safeCropLeft.toStringAsFixed(0)}px',
                                  onChanged: (value) {
                                    setState(() {});
                                    _updateContentProperty('cropLeft', value);
                                  },
                                ),
                                Slider(
                                  value: safeCropRight,
                                  min: 0.0,
                                  max: maxCropWidth,
                                  divisions: 100,
                                  label:
                                      '右: ${safeCropRight.toStringAsFixed(0)}px',
                                  onChanged: (value) {
                                    setState(() {});
                                    _updateContentProperty('cropRight', value);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('左: ${cropLeft.toStringAsFixed(0)}px'),
                            Text('右: ${cropRight.toStringAsFixed(0)}px'),
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
                                flipHorizontal ? Colors.blue : null,
                            foregroundColor:
                                flipHorizontal ? Colors.white : null,
                          ),
                          onPressed: () => _updateContentProperty(
                              'flipHorizontal', !flipHorizontal),
                          label: const Text('水平翻转'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flip),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: flipVertical ? Colors.blue : null,
                            foregroundColor: flipVertical ? Colors.white : null,
                          ),
                          onPressed: () => _updateContentProperty(
                              'flipVertical', !flipVertical),
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

  // 获取字符串的最小长度
  int min(int a, int b) => a < b ? a : b;

  // 应用变换
  void _applyTransform(BuildContext context) {
    // 获取当前变换参数
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    // 获取图片尺寸信息（如果可用）
    final imageSize = _imageStateHolder.imageSize;
    final renderSize = _imageStateHolder.renderSize;

    if (imageSize != null && renderSize != null) {
      // 限制裁剪值不超过图片尺寸的一半
      final maxCropWidth = renderSize.width / 2;
      final maxCropHeight = renderSize.height / 2;

      // 确保裁剪值在有效范围内
      content['cropTop'] =
          (content['cropTop'] as num?)?.toDouble().clamp(0.0, maxCropHeight) ??
              0.0;
      content['cropBottom'] = (content['cropBottom'] as num?)
              ?.toDouble()
              .clamp(0.0, maxCropHeight) ??
          0.0;
      content['cropLeft'] =
          (content['cropLeft'] as num?)?.toDouble().clamp(0.0, maxCropWidth) ??
              0.0;
      content['cropRight'] =
          (content['cropRight'] as num?)?.toDouble().clamp(0.0, maxCropWidth) ??
              0.0;

      // 标记已应用变换
      content['isTransformApplied'] = true;

      // 更新内容
      _updateProperty('content', content);

      // 通知外部应用变换
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('变换已应用到图片'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  // 构建带有变换预览框的图片预览
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
                              fitMode: previewFitMode, // 在预览中始终使用contain适应模式
                              onImageSizeAvailable:
                                  (Size imageSize, Size renderSize) {
                                // 保存图片尺寸信息供变换线框使用
                                _imageStateHolder.imageSize = imageSize;
                                _imageStateHolder.renderSize = renderSize;
                              }),
                        ),
                      ),
                    ),

                    // 始终显示变换预览矩形线框
                    _buildTransformPreviewRect(
                      containerConstraints: constraints,
                      cropTop: cropTop,
                      cropBottom: cropBottom,
                      cropLeft: cropLeft,
                      cropRight: cropRight,
                      contentRotation: contentRotation,
                      fitMode: previewFitMode, // 在预览中始终使用contain适应模式
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

  // 构建图片小部件，根据URL类型选择不同的加载方式
  Widget _buildImageWidget(String imageUrl, String fitMode) {
    final BoxFit fit = _getFitMode(fitMode);

    // 检查是否是本地文件路径
    if (imageUrl.startsWith('file://')) {
      // 提取文件路径（去掉file://前缀）
      final filePath = imageUrl.substring(7);

      // 使用File.image加载本地文件
      return Image.file(
        File(filePath),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('加载本地图片失败: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text('加载本地图片失败: ${error.toString()}'),
              ],
            ),
          );
        },
      );
    } else {
      // 使用网络图片加载
      return Image.network(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text(
                    '加载网络图片失败: ${error.toString().substring(0, min(30, error.toString().length))}...'),
              ],
            ),
          );
        },
      );
    }
  }

  // 带有图片尺寸监听的图片构建方法
  Widget _buildImageWithSizeListener({
    required String imageUrl,
    required String fitMode,
    required Function(Size imageSize, Size renderSize) onImageSizeAvailable,
  }) {
    final BoxFit fit = _getFitMode(fitMode);

    // 构建合适的图片控件
    Widget imageWidget;

    if (imageUrl.startsWith('file://')) {
      final filePath = imageUrl.substring(7);

      imageWidget = Image.file(
        File(filePath),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('加载本地图片失败: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text('加载本地图片失败: ${error.toString()}'),
              ],
            ),
          );
        },
      );
    } else {
      imageWidget = Image.network(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text(
                    '加载网络图片失败: ${error.toString().substring(0, min(30, error.toString().length))}...'),
              ],
            ),
          );
        },
      );
    }

    // 包装图片以监听尺寸
    return LayoutBuilder(builder: (context, constraints) {
      return _SizeReportingWidget(
        onSizeChange: (Size renderSize) {
          ImageProvider imageProvider;
          if (imageUrl.startsWith('file://')) {
            imageProvider = FileImage(File(imageUrl.substring(7)));
          } else {
            imageProvider = NetworkImage(imageUrl);
          }

          // 获取图片实际尺寸
          _getImageSize(imageProvider).then((Size imageSize) {
            if (imageSize.width > 0 && imageSize.height > 0) {
              onImageSizeAvailable(imageSize, renderSize);
            }
          });
        },
        child: imageWidget,
      );
    });
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

  // 构建变换后的图片
  Widget _buildTransformedImage({
    required String imageUrl,
    required String fitMode,
    required double cropTop,
    required double cropBottom,
    required double cropLeft,
    required double cropRight,
    required double contentRotation,
    bool applyTransform = false, // 是否应用变换到画布元素
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final containerHeight = constraints.maxHeight;

        // 如果有图片尺寸信息，使用图片的实际尺寸进行裁剪
        if (_imageStateHolder.imageSize != null &&
            _imageStateHolder.renderSize != null) {
          // 计算图片实际渲染尺寸和位置
          final imageRenderSize = _calculateRenderSize(
            _imageStateHolder.imageSize!,
            Size(containerWidth, containerHeight),
            fitMode,
          );

          // 计算图片在容器中的位置（居中显示）
          final imageLeft = (containerWidth - imageRenderSize.width) / 2;
          final imageTop = (containerHeight - imageRenderSize.height) / 2;

          // 根据裁剪值计算实际显示区域的位置和大小
          final rectLeft = cropLeft;
          final rectTop = cropTop;
          final rectWidth = imageRenderSize.width - cropLeft - cropRight;
          final rectHeight = imageRenderSize.height - cropTop - cropBottom;

          // 如果裁剪值使得矩形尺寸为负或过小，返回原始图片
          if (rectWidth <= 5 || rectHeight <= 5) {
            return _buildImageWidget(imageUrl, fitMode);
          }

          // 返回变换后的图片
          return Center(
            child: Transform.rotate(
              angle: contentRotation * math.pi / 180,
              alignment: Alignment.center,
              child: SizedBox(
                width: applyTransform ? rectWidth : imageRenderSize.width,
                height: applyTransform ? rectHeight : imageRenderSize.height,
                child: applyTransform
                    ? ClipRect(
                        child: Transform.translate(
                          offset: Offset(-cropLeft, -cropTop),
                          child: SizedBox(
                            width: imageRenderSize.width,
                            height: imageRenderSize.height,
                            child: _buildImageWidget(imageUrl, fitMode),
                          ),
                        ),
                      )
                    : _buildImageWidget(imageUrl, fitMode),
              ),
            ),
          );
        } else {
          // 如果没有图片尺寸信息，使用简化方法
          return Center(
            child: _buildImageWidget(imageUrl, fitMode),
          );
        }
      },
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
    required String fitMode,
  }) {
    final containerWidth = containerConstraints.maxWidth;
    final containerHeight = containerConstraints.maxHeight;

    // 获取图片尺寸信息（如果可用）
    final imageSize = _imageStateHolder.imageSize;
    final renderSize = _imageStateHolder.renderSize;

    // 如果有图片尺寸信息，使用它们来计算变换框
    if (imageSize != null && renderSize != null) {
      // 计算图片渲染尺寸
      final imageRenderSize = _calculateRenderSize(
        imageSize,
        Size(containerWidth, containerHeight),
        fitMode,
      );

      // 计算图片在容器中的位置（居中显示）
      final imageLeft = (containerWidth - imageRenderSize.width) / 2;
      final imageTop = (containerHeight - imageRenderSize.height) / 2;

      // 限制裁剪值不超过图片尺寸的一半
      final maxCropWidth = imageRenderSize.width / 2;
      final maxCropHeight = imageRenderSize.height / 2;

      final safeCropLeft = cropLeft.clamp(0.0, maxCropWidth);
      final safeCropRight = cropRight.clamp(0.0, maxCropWidth);
      final safeCropTop = cropTop.clamp(0.0, maxCropHeight);
      final safeCropBottom = cropBottom.clamp(0.0, maxCropHeight);

      // 根据裁剪值计算预览矩形的位置和大小
      final rectLeft = imageLeft + safeCropLeft;
      final rectTop = imageTop + safeCropTop;
      final rectWidth = imageRenderSize.width - safeCropLeft - safeCropRight;
      final rectHeight = imageRenderSize.height - safeCropTop - safeCropBottom;

      // 如果裁剪值使得矩形尺寸过小，则不显示
      if (rectWidth <= 5 || rectHeight <= 5) {
        return Container(); // 返回空容器
      }

      // 计算旋转后的矩形是否会超出图片边界
      // 旋转后的矩形对角线长度
      final diagonalLength =
          math.sqrt(rectWidth * rectWidth + rectHeight * rectHeight);

      // 计算旋转后的矩形是否会超出图片边界
      final rotatedRectFitsInImage = diagonalLength <=
          math.min(imageRenderSize.width, imageRenderSize.height);

      // 返回完整的变换预览框和虚线原始图片区域
      return Stack(
        children: [
          // 显示原始图片区域的虚线框
          Positioned(
            left: imageLeft,
            top: imageTop,
            width: imageRenderSize.width,
            height: imageRenderSize.height,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.withAlpha(179), // 使用withAlpha替代withOpacity
                  width: 1.0,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),

          // 显示裁剪后的区域
          Positioned(
            left: rectLeft,
            top: rectTop,
            width: rectWidth,
            height: rectHeight,
            child: Transform.rotate(
              angle: contentRotation * math.pi / 180,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red,
                    width: 2.0,
                  ),
                  color: Colors.red
                      .withAlpha(26), // 使用withAlpha替代withOpacity，0.1 * 255 ≈ 26
                ),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rotatedRectFitsInImage ? '变换后区域' : '警告: 旋转后可能超出边界',
                      style: TextStyle(
                        color:
                            rotatedRectFitsInImage ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // 如果没有图片尺寸信息，使用简化方法（临时显示，直到尺寸加载完成）
      final rectWidth = containerWidth - cropLeft - cropRight;
      final rectHeight = containerHeight - cropTop - cropBottom;

      if (rectWidth <= 5 || rectHeight <= 5) {
        return Container();
      }

      return Center(
        child: Transform.rotate(
          angle: contentRotation * math.pi / 180,
          alignment: Alignment.center,
          child: Container(
            margin: EdgeInsets.only(
              left: cropLeft,
              top: cropTop,
              right: cropRight,
              bottom: cropBottom,
            ),
            width: rectWidth,
            height: rectHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 2.0,
              ),
              color: Colors.red
                  .withAlpha(26), // 使用withAlpha替代withOpacity，0.1 * 255 ≈ 26
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '变换后区域',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
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
          // 图片较宽，以容器宽度为准
          return Size(
            containerSize.width,
            containerSize.width / imageRatio,
          );
        } else {
          // 图片较高，以容器高度为准
          return Size(
            containerSize.height * imageRatio,
            containerSize.height,
          );
        }
      case 'cover':
        if (imageRatio > containerRatio) {
          // 图片较宽，以容器高度为准
          return Size(
            containerSize.height * imageRatio,
            containerSize.height,
          );
        } else {
          // 图片较高，以容器宽度为准
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

  // 重置变换
  void _resetTransform(BuildContext context) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    // 重置所有变换参数
    content['cropTop'] = 0.0;
    content['cropBottom'] = 0.0;
    content['cropLeft'] = 0.0;
    content['cropRight'] = 0.0;
    content['flipHorizontal'] = false;
    content['flipVertical'] = false;
    content['rotation'] = 0.0; // 重置图片内容旋转
    content['fitMode'] = 'contain'; // 重置适应模式
    content['isTransformApplied'] = false; // 重置应用状态

    _updateProperty('content', content);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('图片变换已重置'),
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
    _updateProperty('content', content);
  }

  // 更新属性
  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
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

// 用于存储图片尺寸信息的状态持有者
class _ImageSizeStateHolder {
  Size? imageSize;
  Size? renderSize;
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
