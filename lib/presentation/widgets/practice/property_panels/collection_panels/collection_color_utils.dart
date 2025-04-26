import 'package:flutter/material.dart';

/// 显示颜色选择器对话框
Future<void> showColorPickerDialog(
  BuildContext context,
  String initialColor,
  Function(Color) onColorSelected,
) async {
  // 预设颜色列表
  final presetColors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.transparent,
  ];

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('选择颜色'),
      content: SizedBox(
        width: 300,
        height: 300,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: presetColors.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                final color = presetColors[index];
                onColorSelected(color);
                Navigator.of(context).pop();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: presetColors[index],
                  border: Border.all(
                    color: presetColors[index] == Colors.white ||
                            presetColors[index] == Colors.transparent
                        ? Colors.grey
                        : presetColors[index],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: presetColors[index] == Colors.transparent
                    ? const Center(
                        child: Text('透明', style: TextStyle(fontSize: 10)))
                    : null,
              ),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('取消'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}

/// 集字面板中使用的颜色和绘制辅助工具
class CollectionColorUtils {
  /// 将颜色转换为十六进制字符串
  static String colorToHex(Color color) {
    // 处理透明色
    if (color == Colors.transparent) {
      return 'transparent';
    }

    // 处理常见颜色
    if (color == Colors.black) return '#000000';
    if (color == Colors.white) return '#ffffff';
    if (color == Colors.red) return '#ff0000';
    if (color == Colors.green) return '#00ff00';
    if (color == Colors.blue) return '#0000ff';
    if (color == Colors.yellow) return '#ffff00';
    if (color == Colors.cyan) return '#00ffff';
    if (color == Colors.purple.shade200) return '#ff00ff'; // 近似品红色
    if (color == Colors.orange) return '#ffa500';
    if (color == Colors.purple) return '#800080';
    if (color == Colors.pink) return '#ffc0cb';
    if (color == Colors.brown) return '#a52a2a';
    if (color == Colors.grey) return '#808080';

    try {
      // 获取颜色的RGB值
      final int r = color.red;
      final int g = color.green;
      final int b = color.blue;

      // 转换为十六进制字符串，确保每个颜色分量都是2位
      final String hexR = r.toRadixString(16).padLeft(2, '0');
      final String hexG = g.toRadixString(16).padLeft(2, '0');
      final String hexB = b.toRadixString(16).padLeft(2, '0');

      // 组合成完整的十六进制颜色字符串
      return '#$hexR$hexG$hexB'; // 包含 # 前缀
    } catch (e) {
      return '#000000'; // 出错时返回默认黑色
    }
  }

  /// 获取下标显示字符
  static String getSubscript(int number) {
    const Map<String, String> subscripts = {
      '0': '₀',
      '1': '₁',
      '2': '₂',
      '3': '₃',
      '4': '₄',
      '5': '₅',
      '6': '₆',
      '7': '₇',
      '8': '₈',
      '9': '₉',
    };

    final String numberStr = number.toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < numberStr.length; i++) {
      result.write(subscripts[numberStr[i]] ?? numberStr[i]);
    }

    return result.toString();
  }

  /// 将十六进制颜色字符串转换为Color对象
  static Color hexToColor(String hexString) {
    // 处理透明色
    if (hexString == 'transparent') {
      return Colors.transparent;
    }

    // 处理常见颜色名称
    switch (hexString.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'cyan':
        return Colors.cyan;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
    }

    // 处理特定的十六进制颜色
    switch (hexString.toLowerCase()) {
      case '#000000':
        return Colors.black;
      case '#ffffff':
        return Colors.white;
      case '#ff0000':
        return Colors.red;
      case '#00ff00':
        return Colors.green;
      case '#0000ff':
        return Colors.blue;
      case '#ffff00':
        return Colors.yellow;
      case '#00ffff':
        return Colors.cyan;
      case '#ff00ff':
        return Colors.purple.shade200; // 近似品红色
      case '#ffa500':
        return Colors.orange;
      case '#800080':
        return Colors.purple;
      case '#ffc0cb':
        return Colors.pink;
      case '#a52a2a':
        return Colors.brown;
      case '#808080':
        return Colors.grey;
    }

    try {
      // 去除可能的#前缀
      String cleanHex =
          hexString.startsWith('#') ? hexString.substring(1) : hexString;

      // 处理不同长度的十六进制颜色
      if (cleanHex.length == 6) {
        // RRGGBB格式，添加完全不透明的Alpha通道
        cleanHex = 'ff$cleanHex';
      } else if (cleanHex.length == 8) {
        // AARRGGBB格式，已经包含Alpha通道
      } else if (cleanHex.length == 3) {
        // RGB格式，扩展为RRGGBB并添加完全不透明的Alpha通道
        cleanHex =
            'ff${cleanHex[0]}${cleanHex[0]}${cleanHex[1]}${cleanHex[1]}${cleanHex[2]}${cleanHex[2]}';
      } else {
        return Colors.black; // 无效格式，返回黑色
      }

      // 解析十六进制值
      final int colorValue = int.parse(cleanHex, radix: 16);
      return Color(colorValue);
    } catch (e) {
      return Colors.black; // 出错时返回黑色
    }
  }
}
