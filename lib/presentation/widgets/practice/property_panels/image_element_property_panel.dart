import 'package:flutter/material.dart';

import '../../../../domain/models/practice/practice_element.dart';
import 'property_panel_base.dart';

/// A property row with a checkbox input
class CheckboxPropertyRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final bool divider;

  const CheckboxPropertyRow({
    Key? key,
    required this.label,
    required this.value,
    this.onChanged,
    this.divider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget row = Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );

    if (divider) {
      return Column(
        children: [
          row,
          const Divider(),
        ],
      );
    }
    return row;
  }
}

/// 图片内容元素的属性面板
class ImageElementPropertyPanel extends StatelessWidget {
  final ImageElement element;
  final Function(PracticeElement) onElementChanged;

  const ImageElementPropertyPanel({
    Key? key,
    required this.element,
    required this.onElementChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片内容元素标题
            const Text(
              '图片内容属性',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 基础属性（位置、大小、旋转、透明度、锁定）
            BasicPropertyPanel(
              element: element,
              onElementChanged: onElementChanged,
            ),

            const SizedBox(height: 16),

            // 图片特有属性
            const PropertyGroupTitle(title: '图片属性'),

            // 图片选择
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text(
                    '图片路径',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: element.imageUrl,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                      hintText: '图片URL或本地路径',
                    ),
                    onChanged: (value) {
                      onElementChanged(element.copyWith(imageUrl: value));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    // 这里应该打开文件选择器
                    // 简化实现，使用一个示例图片
                    onElementChanged(element.copyWith(
                        imageUrl: 'assets/images/sample_image.jpg'));
                  },
                  child: const Text('浏览...'),
                ),
              ],
            ),
            const Divider(),

            // 适配方式
            DropdownPropertyRow(
              label: '适配方式',
              value: _boxFitToString(element.fit),
              options: const [
                'contain',
                'cover',
                'fill',
                'fitWidth',
                'fitHeight',
                'none',
                'scaleDown'
              ],
              displayLabels: const {
                'contain': '包含',
                'cover': '覆盖',
                'fill': '填充',
                'fitWidth': '适应宽度',
                'fitHeight': '适应高度',
                'none': '无',
                'scaleDown': '缩小适应',
              },
              onChanged: (value) {
                if (value != null) {
                  onElementChanged(element.copyWith(fit: _parseBoxFit(value)));
                }
              },
            ),

            // 图片变换属性
            const PropertyGroupTitle(title: '图片变换'),

            // 翻转控制
            CheckboxPropertyRow(
              label: '水平翻转',
              value: element.flipHorizontal,
              onChanged: (value) {
                if (value != null) {
                  onElementChanged(element.copyWith(flipHorizontal: value));
                }
              },
            ),

            CheckboxPropertyRow(
              label: '垂直翻转',
              value: element.flipVertical,
              onChanged: (value) {
                if (value != null) {
                  onElementChanged(element.copyWith(flipVertical: value));
                }
              },
            ),

            // 裁剪控制
            const PropertyGroupTitle(title: '裁剪'),
            _buildCropControls(element.crop, (crop) {
              onElementChanged(element.copyWith(crop: crop));
            }),

            // 图片预览
            const PropertyGroupTitle(title: '预览'),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.grey.withOpacity(0.1),
              ),
              child: element.imageUrl.isNotEmpty
                  ? _buildImagePreview()
                  : const Center(
                      child: Text('未选择图片'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // BoxFit枚举转字符串
  String _boxFitToString(BoxFit fit) {
    switch (fit) {
      case BoxFit.fill:
        return 'fill';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fitWidth:
        return 'fitWidth';
      case BoxFit.fitHeight:
        return 'fitHeight';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scaleDown';
      default:
        return 'contain';
    }
  }

  // 构建裁剪控制UI
  Widget _buildCropControls(EdgeInsets crop, Function(EdgeInsets) onChanged) {
    return Column(
      children: [
        TextPropertyRow(
          label: '上边距',
          value: crop.top.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final top = double.tryParse(value) ?? crop.top;
            onChanged(EdgeInsets.only(
              top: top,
              left: crop.left,
              right: crop.right,
              bottom: crop.bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '右边距',
          value: crop.right.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final right = double.tryParse(value) ?? crop.right;
            onChanged(EdgeInsets.only(
              top: crop.top,
              left: crop.left,
              right: right,
              bottom: crop.bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '下边距',
          value: crop.bottom.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final bottom = double.tryParse(value) ?? crop.bottom;
            onChanged(EdgeInsets.only(
              top: crop.top,
              left: crop.left,
              right: crop.right,
              bottom: bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '左边距',
          value: crop.left.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final left = double.tryParse(value) ?? crop.left;
            onChanged(EdgeInsets.only(
              top: crop.top,
              left: left,
              right: crop.right,
              bottom: crop.bottom,
            ));
          },
          divider: false,
        ),
      ],
    );
  }

  // 构建图片预览
  Widget _buildImagePreview() {
    Widget image = element.imageUrl.startsWith('http')
        ? Image.network(element.imageUrl, fit: element.fit)
        : Image.asset(element.imageUrl, fit: element.fit);

    // 应用裁剪
    if (element.crop != EdgeInsets.zero) {
      image = ClipRect(
        child: Padding(
          padding: EdgeInsets.only(
            left: -element.crop.left,
            top: -element.crop.top,
            right: -element.crop.right,
            bottom: -element.crop.bottom,
          ),
          child: image,
        ),
      );
    }

    // 应用水平/垂直翻转
    if (element.flipHorizontal || element.flipVertical) {
      image = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(
            element.flipHorizontal ? -1.0 : 1.0,
            element.flipVertical ? -1.0 : 1.0,
          ),
        child: image,
      );
    }

    return image;
  }

  // 字符串转BoxFit枚举
  BoxFit _parseBoxFit(String fit) {
    switch (fit) {
      case 'fill':
        return BoxFit.fill;
      case 'cover':
        return BoxFit.cover;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaleDown':
        return BoxFit.scaleDown;
      default:
        return BoxFit.contain;
    }
  }
}
