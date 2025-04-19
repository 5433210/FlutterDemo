import 'package:flutter/material.dart';

/// 文本元素渲染器
class TextElementRenderer extends StatelessWidget {
  final Map<String, dynamic> element;
  final bool isEditing;
  final double scale;

  const TextElementRenderer({
    Key? key,
    required this.element,
    this.isEditing = false,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = element['content'] as Map<String, dynamic>;
    final String text = content['text'] as String? ?? '';
    final double fontSize =
        ((content['fontSize'] as num?) ?? 16.0).toDouble() * scale;
    final String fontFamily = content['fontFamily'] as String? ?? 'sans-serif';
    final String textColorStr = content['textColor'] as String? ?? '#000000';
    final Color textColor = _hexToColor(textColorStr);
    final String alignment = content['alignment'] as String? ?? 'left';

    TextAlign textAlign;
    switch (alignment) {
      case 'center':
        textAlign = TextAlign.center;
        break;
      case 'right':
        textAlign = TextAlign.right;
        break;
      case 'justify':
        textAlign = TextAlign.justify;
        break;
      case 'left':
      default:
        textAlign = TextAlign.left;
    }

    final TextStyle textStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: textColor,
      height: 1.2,
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(4),
      child: isEditing
          ? TextField(
              controller: TextEditingController(text: text),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: textStyle,
              textAlign: textAlign,
              maxLines: null,
              onChanged: (value) {
                // 实际应用中，这里应该触发一个回调来更新文本内容
              },
            )
          : Text(
              text,
              style: textStyle,
              textAlign: textAlign,
            ),
    );
  }

  /// 将十六进制颜色字符串转换为Color对象
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
