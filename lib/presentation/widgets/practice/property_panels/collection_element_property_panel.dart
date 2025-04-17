import 'package:flutter/material.dart';

import '../../../../domain/models/practice/practice_element.dart';
import 'property_panel_base.dart';

/// 集字内容元素的属性面板
class CollectionElementPropertyPanel extends StatelessWidget {
  final CollectionElement element;
  final Function(PracticeElement) onElementChanged;

  const CollectionElementPropertyPanel({
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
            // 集字内容元素标题
            const Text(
              '集字内容属性',
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

            // 集字排版属性
            const PropertyGroupTitle(title: '排版属性'),

            // 书写方向（行内）
            DropdownPropertyRow(
              label: '行内方向',
              value: element.direction.toShortString(),
              options: const [
                'horizontal',
                'vertical',
                'horizontalReversed',
                'verticalReversed'
              ],
              displayLabels: const {
                'horizontal': '从左向右',
                'vertical': '从上到下',
                'horizontalReversed': '从右向左',
                'verticalReversed': '从下到上',
              },
              onChanged: (value) {
                if (value != null) {
                  onElementChanged(element.copyWith(
                      direction: CollectionDirectionExt.fromString(value)));
                }
              },
            ),

            // 书写方向（行间）
            DropdownPropertyRow(
              label: '行间方向',
              value: element.flowDirection.toShortString(),
              options: const [
                'horizontal',
                'vertical',
                'horizontalReversed',
                'verticalReversed'
              ],
              displayLabels: const {
                'horizontal': '从左向右',
                'vertical': '从上到下',
                'horizontalReversed': '从右向左',
                'verticalReversed': '从下到上',
              },
              onChanged: (value) {
                if (value != null) {
                  onElementChanged(element.copyWith(
                      flowDirection: CollectionDirectionExt.fromString(value)));
                }
              },
            ),

            // 对齐方式
            DropdownPropertyRow(
              label: '对齐方式',
              value: _alignmentToString(element.alignment),
              options: const [
                'topLeft',
                'topCenter',
                'topRight',
                'centerLeft',
                'center',
                'centerRight',
                'bottomLeft',
                'bottomCenter',
                'bottomRight',
              ],
              displayLabels: const {
                'topLeft': '左上',
                'topCenter': '上中',
                'topRight': '右上',
                'centerLeft': '左中',
                'center': '居中',
                'centerRight': '右中',
                'bottomLeft': '左下',
                'bottomCenter': '下中',
                'bottomRight': '右下',
              },
              onChanged: (value) {
                if (value != null) {
                  onElementChanged(
                      element.copyWith(alignment: _parseAlignment(value)));
                }
              },
            ),

            // 字间距
            SliderPropertyRow(
              label: '字间距',
              value: element.characterSpacing,
              min: 0.0,
              max: 50.0,
              onChanged: (value) {
                onElementChanged(element.copyWith(characterSpacing: value));
              },
              valueLabel: '${element.characterSpacing.toInt()}',
            ),

            // 行间距
            SliderPropertyRow(
              label: '行间距',
              value: element.lineSpacing,
              min: 0.0,
              max: 50.0,
              onChanged: (value) {
                onElementChanged(element.copyWith(lineSpacing: value));
              },
              valueLabel: '${element.lineSpacing.toInt()}',
            ),

            // 内边距
            const PropertyGroupTitle(title: '边距'),
            _buildPaddingControls(element.padding, (padding) {
              onElementChanged(element.copyWith(padding: padding));
            }),

            // 外观设置
            const PropertyGroupTitle(title: '外观设置'),

            // 字体颜色
            ColorPropertyRow(
              label: '字体颜色',
              color: _parseColor(element.fontColor),
              onChanged: (color) {
                onElementChanged(element.copyWith(
                    fontColor:
                        '#${color.value.toRadixString(16).substring(2).toUpperCase()}'));
              },
            ),

            // 背景颜色
            ColorPropertyRow(
              label: '背景颜色',
              color: _parseColor(element.backgroundColor),
              onChanged: (color) {
                onElementChanged(element.copyWith(
                    backgroundColor:
                        '#${color.value.toRadixString(16).substring(2).toUpperCase()}'));
              },
            ),

            // 字体大小
            SliderPropertyRow(
              label: '字体大小',
              value: element.characterSize,
              min: 10.0,
              max: 100.0,
              onChanged: (value) {
                onElementChanged(element.copyWith(characterSize: value));
              },
              valueLabel: '${element.characterSize.toInt()}',
            ),

            // 默认集字图片类型
            DropdownPropertyRow(
              label: '默认字型',
              value: element.defaultImageType,
              options: const ['standard', 'kai', 'song', 'hei', 'fangsong'],
              displayLabels: const {
                'standard': '标准',
                'kai': '楷体',
                'song': '宋体',
                'hei': '黑体',
                'fangsong': '仿宋',
              },
              onChanged: (value) {
                if (value != null) {
                  onElementChanged(element.copyWith(defaultImageType: value));
                }
              },
            ),

            // 集字内容区
            const PropertyGroupTitle(title: '集字内容'),

            // 汉字输入框
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: TextEditingController(text: element.characters),
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '请输入要展示的汉字',
                ),
                onChanged: (value) {
                  onElementChanged(element.copyWith(characters: value));
                },
              ),
            ),

            // 集字预览列表
            const PropertyGroupTitle(title: '集字预览'),
            element.characters.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('请在上方输入汉字以预览集字效果'),
                    ),
                  )
                : _buildCharacterPreviewGrid(),

            // 候选集字列表 (简化版，实际情况应当支持筛选和选择)
            if (element.characters.isNotEmpty) ...[
              const PropertyGroupTitle(title: '候选集字'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '此区域会显示匹配的候选集字图片，单击可选择替换预览区对应字符的图片。',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              // 简化的候选集字UI，实际应用中会更复杂
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text('候选集字加载中...'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 对齐方式转字符串
  String _alignmentToString(Alignment alignment) {
    if (alignment == Alignment.topLeft) return 'topLeft';
    if (alignment == Alignment.topCenter) return 'topCenter';
    if (alignment == Alignment.topRight) return 'topRight';
    if (alignment == Alignment.centerLeft) return 'centerLeft';
    if (alignment == Alignment.centerRight) return 'centerRight';
    if (alignment == Alignment.bottomLeft) return 'bottomLeft';
    if (alignment == Alignment.bottomCenter) return 'bottomCenter';
    if (alignment == Alignment.bottomRight) return 'bottomRight';
    return 'center';
  }

  // 构建字符预览网格
  Widget _buildCharacterPreviewGrid() {
    final characters = element.characters.split('');
    final characterImages = element.characterImages;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final char = characters[index];
        // 查找该字对应的图片
        final charImage = characterImages.firstWhere(
          (img) => img['character'] == char,
          orElse: () => <String, dynamic>{},
        );

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
            color: Colors.white,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 字符图片或占位符
              Center(
                child: charImage.isNotEmpty && charImage.containsKey('imageUrl')
                    ? Image.network(
                        charImage['imageUrl'] as String,
                        fit: BoxFit.contain,
                      )
                    : Text(
                        char,
                        style: TextStyle(
                          fontSize: 32,
                          color: _parseColor(element.fontColor),
                        ),
                      ),
              ),
              // 字符信息
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    char,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建内边距控制UI
  Widget _buildPaddingControls(
      EdgeInsets padding, Function(EdgeInsets) onChanged) {
    return Column(
      children: [
        TextPropertyRow(
          label: '上边距',
          value: padding.top.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final top = double.tryParse(value) ?? padding.top;
            onChanged(EdgeInsets.only(
              top: top,
              left: padding.left,
              right: padding.right,
              bottom: padding.bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '右边距',
          value: padding.right.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final right = double.tryParse(value) ?? padding.right;
            onChanged(EdgeInsets.only(
              top: padding.top,
              left: padding.left,
              right: right,
              bottom: padding.bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '下边距',
          value: padding.bottom.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final bottom = double.tryParse(value) ?? padding.bottom;
            onChanged(EdgeInsets.only(
              top: padding.top,
              left: padding.left,
              right: padding.right,
              bottom: bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '左边距',
          value: padding.left.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final left = double.tryParse(value) ?? padding.left;
            onChanged(EdgeInsets.only(
              top: padding.top,
              left: left,
              right: padding.right,
              bottom: padding.bottom,
            ));
          },
          divider: false,
        ),
      ],
    );
  }

  // 字符串转对齐方式
  Alignment _parseAlignment(String align) {
    switch (align) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topCenter':
        return Alignment.topCenter;
      case 'topRight':
        return Alignment.topRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'centerRight':
        return Alignment.centerRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'bottomRight':
        return Alignment.bottomRight;
      default:
        return Alignment.center;
    }
  }

  // 颜色字符串转Color对象
  Color _parseColor(String colorString) {
    return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
  }
}
