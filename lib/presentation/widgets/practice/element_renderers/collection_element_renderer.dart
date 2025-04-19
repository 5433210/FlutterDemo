import 'package:flutter/material.dart';

/// 集字元素渲染器
class CollectionElementRenderer extends StatelessWidget {
  final Map<String, dynamic> element;
  final double scale;

  const CollectionElementRenderer({
    Key? key,
    required this.element,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = element['content'] as Map<String, dynamic>;
    final String characters = content['characters'] as String? ?? '';
    final double fontSize =
        ((content['fontSize'] as num?) ?? 24.0).toDouble() * scale;
    final String fontColorStr = content['fontColor'] as String? ?? '#000000';
    final String backgroundColorStr =
        content['backgroundColor'] as String? ?? '#FFFFFF';
    final String direction = content['direction'] as String? ?? 'horizontal';
    final double charSpacing =
        ((content['charSpacing'] as num?) ?? 10.0).toDouble() * scale;
    final double lineSpacing =
        ((content['lineSpacing'] as num?) ?? 10.0).toDouble() * scale;
    final bool showGrid = content['gridLines'] as bool? ?? false;
    final bool showBackground = content['showBackground'] as bool? ?? true;

    final Color fontColor = _hexToColor(fontColorStr);
    final Color backgroundColor =
        showBackground ? _hexToColor(backgroundColorStr) : Colors.transparent;

    final width = (element['width'] as num).toDouble() * scale;
    final height = (element['height'] as num).toDouble() * scale;

    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: direction == 'horizontal'
          ? _buildHorizontalLayout(characters, fontSize, fontColor, charSpacing,
              lineSpacing, showGrid)
          : _buildVerticalLayout(characters, fontSize, fontColor, charSpacing,
              lineSpacing, showGrid),
    );
  }

  /// 构建单个字符框
  Widget _buildCharacterBox(
    String char,
    double fontSize,
    Color fontColor,
    bool showGrid,
  ) {
    final boxSize = fontSize * 1.5;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        border: showGrid
            ? Border.all(color: Colors.grey.withOpacity(0.5), width: 0.5)
            : null,
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize: fontSize,
            color: fontColor,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  /// 构建水平排列的字符
  Widget _buildHorizontalLayout(
    String characters,
    double fontSize,
    Color fontColor,
    double charSpacing,
    double lineSpacing,
    bool showGrid,
  ) {
    final charList = characters.split('');

    return Wrap(
      spacing: charSpacing,
      runSpacing: lineSpacing,
      children: charList.map((char) {
        return _buildCharacterBox(char, fontSize, fontColor, showGrid);
      }).toList(),
    );
  }

  /// 构建垂直排列的字符
  Widget _buildVerticalLayout(
    String characters,
    double fontSize,
    Color fontColor,
    double charSpacing,
    double lineSpacing,
    bool showGrid,
  ) {
    final charList = characters.split('');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: charList.map((char) {
        return Padding(
          padding: EdgeInsets.only(bottom: lineSpacing),
          child: _buildCharacterBox(char, fontSize, fontColor, showGrid),
        );
      }).toList(),
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
