import 'package:flutter/material.dart';

import '../../../common/editable_number_field.dart';

/// 文本格式设置面板，包含字体大小、行列间距等设置
class TextFormatPanel extends StatelessWidget {
  final Map<String, dynamic> content;
  final Function(String, dynamic) onContentPropertyChanged;

  const TextFormatPanel({
    Key? key,
    required this.content,
    required this.onContentPropertyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 36.0;
    final lineSpacing = (content['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 5.0;
    final textAlign = content['textAlign'] as String? ?? 'left';
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final writingMode = content['writingMode'] as String? ?? 'horizontal-l';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 字号设置
        const Text('字号:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: fontSize,
                min: 1,
                max: 100,
                divisions: 99,
                label: '${fontSize.round()}px',
                onChanged: (value) {
                  onContentPropertyChanged('fontSize', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: '字号',
                value: fontSize,
                suffix: 'px',
                min: 1,
                max: 200,
                onChanged: (value) {
                  onContentPropertyChanged('fontSize', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 字间距设置
        const Text('字间距:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: letterSpacing,
                min: 0,
                max: 50,
                divisions: 50,
                label: '${letterSpacing.round()}px',
                onChanged: (value) {
                  onContentPropertyChanged('letterSpacing', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: '字间距',
                value: letterSpacing,
                suffix: 'px',
                min: 0,
                max: 100,
                decimalPlaces: 1,
                onChanged: (value) {
                  onContentPropertyChanged('letterSpacing', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 行（列）间距设置
        const Text('行（列）间距:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: lineSpacing,
                min: 0,
                max: 50,
                divisions: 50,
                label: '${lineSpacing.round()}px',
                onChanged: (value) {
                  onContentPropertyChanged('lineSpacing', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: '行（列）间距',
                value: lineSpacing,
                suffix: 'px',
                min: 0,
                max: 100,
                decimalPlaces: 1,
                onChanged: (value) {
                  onContentPropertyChanged('lineSpacing', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 水平对齐方式
        const Text('水平对齐:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ToggleButtons(
            isSelected: [
              textAlign == 'left',
              textAlign == 'center',
              textAlign == 'right',
              textAlign == 'justify',
            ],
            onPressed: (index) {
              String newAlign;
              switch (index) {
                case 0:
                  newAlign = 'left';
                  break;
                case 1:
                  newAlign = 'center';
                  break;
                case 2:
                  newAlign = 'right';
                  break;
                case 3:
                  newAlign = 'justify';
                  break;
                default:
                  newAlign = 'left';
              }
              onContentPropertyChanged('textAlign', newAlign);
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Icon(Icons.align_horizontal_left),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Icon(Icons.align_horizontal_center),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Icon(Icons.align_horizontal_right),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Icon(Icons.format_align_justify),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16.0),

        // 垂直对齐
        const Text('垂直对齐:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ToggleButtons(
            isSelected: [
              verticalAlign == 'top',
              verticalAlign == 'middle',
              verticalAlign == 'bottom',
              verticalAlign == 'justify',
            ],
            onPressed: (index) {
              String newAlign;
              switch (index) {
                case 0:
                  newAlign = 'top';
                  break;
                case 1:
                  newAlign = 'middle';
                  break;
                case 2:
                  newAlign = 'bottom';
                  break;
                case 3:
                  newAlign = 'justify';
                  break;
                default:
                  newAlign = 'top';
              }
              onContentPropertyChanged('verticalAlign', newAlign);
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Icon(Icons.vertical_align_top),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Icon(Icons.vertical_align_center),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Icon(Icons.vertical_align_bottom),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Icon(Icons.format_align_justify),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16.0),

        // 书写方向
        const Text('书写方向:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          children: [
            _buildWritingModeButton(
              mode: 'horizontal-l',
              label: '横排左起',
              currentMode: writingMode,
              icon: Icons.format_textdirection_l_to_r,
            ),
            _buildWritingModeButton(
              mode: 'vertical-r',
              label: '竖排右起',
              currentMode: writingMode,
              icon: Icons.format_textdirection_r_to_l,
            ),
            _buildWritingModeButton(
              mode: 'horizontal-r',
              label: '横排右起',
              currentMode: writingMode,
              icon: Icons.keyboard_double_arrow_left,
            ),
            _buildWritingModeButton(
              mode: 'vertical-l',
              label: '竖排左起',
              currentMode: writingMode,
              icon: Icons.keyboard_double_arrow_right,
            ),
          ],
        ),
      ],
    );
  }

  // 构建书写模式按钮
  Widget _buildWritingModeButton({
    required String mode,
    required String label,
    required String currentMode,
    required IconData icon,
  }) {
    final isSelected = currentMode == mode;

    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
      onPressed: () {
        onContentPropertyChanged('writingMode', mode);
      },
    );
  }
}
