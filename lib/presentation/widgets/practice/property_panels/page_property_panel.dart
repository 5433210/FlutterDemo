import 'package:flutter/material.dart';

import '../../../../domain/models/practice/practice_page.dart';
import 'property_panel_base.dart';

/// 页面属性面板
class PagePropertyPanel extends StatelessWidget {
  final PracticePage page;
  final Function(PracticePage) onPageChanged;

  const PagePropertyPanel({
    Key? key,
    required this.page,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面属性标题
            const Text(
              '页面属性',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 尺寸设置
            const PropertyGroupTitle(title: '页面尺寸'),

            // 预设尺寸选择
            DropdownPropertyRow(
              label: '预设尺寸',
              value: _getSizePreset(),
              options: const ['A4', 'A5', 'Square', 'Custom'],
              displayLabels: const {
                'A4': 'A4 (210 × 297 mm)',
                'A5': 'A5 (148 × 210 mm)',
                'Square': '方形 (210 × 210 mm)',
                'Custom': '自定义尺寸',
              },
              onChanged: (value) {
                if (value != null) {
                  switch (value) {
                    case 'A4':
                      onPageChanged(page.setSize(210, 297));
                      break;
                    case 'A5':
                      onPageChanged(page.setSize(148, 210));
                      break;
                    case 'Square':
                      onPageChanged(page.setSize(210, 210));
                      break;
                    case 'Custom':
                      // 自定义尺寸，保持当前值
                      break;
                  }
                }
              },
            ),

            // 宽度高度
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text(
                    '宽度',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: page.width.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                      suffix: Text('mm'),
                    ),
                    onChanged: (value) {
                      final width = double.tryParse(value);
                      if (width != null && width > 0) {
                        onPageChanged(page.copyWith(width: width));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const SizedBox(
                  width: 100,
                  child: Text(
                    '高度',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: page.height.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                      suffix: Text('mm'),
                    ),
                    onChanged: (value) {
                      final height = double.tryParse(value);
                      if (height != null && height > 0) {
                        onPageChanged(page.copyWith(height: height));
                      }
                    },
                  ),
                ),
              ],
            ),
            const Divider(),

            // 页边距设置
            const PropertyGroupTitle(title: '页边距'),
            _buildMarginControls(page.margin, (margin) {
              onPageChanged(page.copyWith(margin: margin));
            }),

            // 背景设置
            const PropertyGroupTitle(title: '背景设置'),

            // 背景类型
            DropdownPropertyRow(
              label: '背景类型',
              value: page.backgroundType,
              options: const ['color', 'image', 'texture'],
              displayLabels: const {
                'color': '纯色',
                'image': '图片',
                'texture': '纹理',
              },
              onChanged: (value) {
                if (value != null) {
                  onPageChanged(page.copyWith(backgroundType: value));
                }
              },
            ),

            // 根据背景类型显示对应设置
            if (page.backgroundType == 'color')
              ColorPropertyRow(
                label: '背景颜色',
                color: _parseColor(page.backgroundColor),
                onChanged: (color) {
                  onPageChanged(page.copyWith(
                      backgroundColor:
                          '#${color.value.toRadixString(16).substring(2).toUpperCase()}'));
                },
              ),

            if (page.backgroundType == 'image') _buildBackgroundImageSelector(),

            if (page.backgroundType == 'texture') _buildTextureSelector(),

            // 背景透明度
            SliderPropertyRow(
              label: '透明度',
              value: page.backgroundOpacity,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                onPageChanged(page.copyWith(backgroundOpacity: value));
              },
              valueLabel: '${(page.backgroundOpacity * 100).toInt()}%',
            ),

            // 预览
            const PropertyGroupTitle(title: '预览'),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.grey.withOpacity(0.1),
              ),
              child: Center(
                child: AspectRatio(
                  aspectRatio: page.width / page.height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _parseColor(page.backgroundColor)
                          .withOpacity(page.backgroundOpacity),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(page.margin.top),
                      child: Container(
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.5)),
                        ),
                        child: const Center(
                          child: Text('内容区域'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建背景图片选择器
  Widget _buildBackgroundImageSelector() {
    return Row(
      children: [
        const SizedBox(
          width: 100,
          child: Text(
            '背景图片',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: TextFormField(
            initialValue: page.backgroundImage ?? '',
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
              hintText: '图片URL或本地路径',
            ),
            onChanged: (value) {
              onPageChanged(page.copyWith(backgroundImage: value));
            },
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            // 这里应该打开文件选择器
            // 简化实现，使用一个示例图片
            onPageChanged(
                page.copyWith(backgroundImage: 'assets/images/background.jpg'));
          },
          child: const Text('浏览...'),
        ),
      ],
    );
  }

  // 构建边距控制UI
  Widget _buildMarginControls(
      EdgeInsets margin, Function(EdgeInsets) onChanged) {
    return Column(
      children: [
        TextPropertyRow(
          label: '上边距',
          value: margin.top.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final top = double.tryParse(value) ?? margin.top;
            onChanged(EdgeInsets.only(
              top: top,
              left: margin.left,
              right: margin.right,
              bottom: margin.bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '右边距',
          value: margin.right.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final right = double.tryParse(value) ?? margin.right;
            onChanged(EdgeInsets.only(
              top: margin.top,
              left: margin.left,
              right: right,
              bottom: margin.bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '下边距',
          value: margin.bottom.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final bottom = double.tryParse(value) ?? margin.bottom;
            onChanged(EdgeInsets.only(
              top: margin.top,
              left: margin.left,
              right: margin.right,
              bottom: bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '左边距',
          value: margin.left.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final left = double.tryParse(value) ?? margin.left;
            onChanged(EdgeInsets.only(
              top: margin.top,
              left: left,
              right: margin.right,
              bottom: margin.bottom,
            ));
          },
          divider: false,
        ),
      ],
    );
  }

  // 构建纹理选择器
  Widget _buildTextureSelector() {
    final textures = [
      {'name': '无纹理', 'value': ''},
      {'name': '米字格', 'value': 'grid_mi'},
      {'name': '田字格', 'value': 'grid_tian'},
      {'name': '回字格', 'value': 'grid_hui'},
      {'name': '九宫格', 'value': 'grid_nine'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                '纹理样式',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: DropdownButton<String>(
                value: page.backgroundTexture ?? '',
                isExpanded: true,
                hint: const Text('选择纹理'),
                items: textures.map((texture) {
                  return DropdownMenuItem<String>(
                    value: texture['value']!,
                    child: Text(texture['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  onPageChanged(page.copyWith(backgroundTexture: value));
                },
              ),
            ),
          ],
        ),
        const Divider(),

        // 纹理预览
        if (page.backgroundTexture != null &&
            page.backgroundTexture!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text(
                    '纹理预览',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    image: DecorationImage(
                      image: AssetImage(
                          'assets/textures/${page.backgroundTexture}.png'),
                      repeat: ImageRepeat.repeat,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 确定当前页面尺寸对应哪个预设
  String _getSizePreset() {
    if (page.width == 210 && page.height == 297) return 'A4';
    if (page.width == 148 && page.height == 210) return 'A5';
    if (page.width == 210 && page.height == 210) return 'Square';
    return 'Custom';
  }

  // 颜色字符串转Color对象
  Color _parseColor(String colorString) {
    return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
  }
}
