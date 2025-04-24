import 'package:flutter/material.dart';

import '../../../widgets/common/color_picker_dialog.dart';
import '../practice_edit_controller.dart';

/// 页面属性面板
class PagePropertyPanel extends StatefulWidget {
  final Map<String, dynamic>? page;
  final Function(Map<String, dynamic>) onPagePropertiesChanged;
  final PracticeEditController controller;

  const PagePropertyPanel({
    Key? key,
    required this.controller,
    required this.page,
    required this.onPagePropertiesChanged,
  }) : super(key: key);

  @override
  State<PagePropertyPanel> createState() => _PagePropertyPanelState();
}

class _PagePropertyPanelState extends State<PagePropertyPanel> {
  // 宽度、高度和DPI输入控制器
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _dpiController;
  late TextEditingController _backgroundColorController; // 添加背景颜色控制器
  late FocusNode _widthFocusNode;
  late FocusNode _heightFocusNode;
  late FocusNode _dpiFocusNode;

  @override
  Widget build(BuildContext context) {
    if (widget.page == null) {
      return const Center(child: Text('未选择页面'));
    }

    final width = (widget.page!['width'] as num?)?.toDouble() ?? 595.0;
    final height = (widget.page!['height'] as num?)?.toDouble() ?? 842.0;
    final orientation = widget.page!['orientation'] as String? ?? 'portrait';
    final dpi = (widget.page!['dpi'] as num?)?.toInt() ?? 300;

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '页面属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 页面尺寸设置
        ExpansionTile(
          title: const Text('页面尺寸'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 预设尺寸选择
                  const Text('预设尺寸'),
                  DropdownButton<String>(
                    value: _getPageSizePreset(width, height),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'A4', child: Text('A4 (210×297mm)')),
                      DropdownMenuItem(
                          value: 'A5', child: Text('A5 (148×210mm)')),
                      DropdownMenuItem(value: 'custom', child: Text('自定义尺寸')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _handlePageSizePresetChange(value, orientation);
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // 页面方向设置
                  const Text('页面方向'),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('纵向'),
                          value: 'portrait',
                          groupValue: orientation,
                          onChanged: (value) {
                            if (value != null && value != orientation) {
                              final Map<String, dynamic> updates = {
                                'orientation': value
                              };
                              // 如果当前宽度大于高度，交换宽高
                              if (width > height) {
                                updates['width'] = height;
                                updates['height'] = width;

                                // 更新控制器的值
                                _widthController.text = height.toString();
                                _heightController.text = width.toString();
                              }
                              widget.onPagePropertiesChanged(updates);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('横向'),
                          value: 'landscape',
                          groupValue: orientation,
                          onChanged: (value) {
                            if (value != null && value != orientation) {
                              final Map<String, dynamic> updates = {
                                'orientation': value
                              };
                              // 如果当前宽度小于高度，交换宽高
                              if (width < height) {
                                updates['width'] = height;
                                updates['height'] = width;

                                // 更新控制器的值
                                _widthController.text = height.toString();
                                _heightController.text = width.toString();
                              }
                              widget.onPagePropertiesChanged(updates);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // 自定义尺寸输入
                  const Text('自定义尺寸 (毫米)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '宽度',
                            suffixText: 'mm', // 添加毫米后缀
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 8.0,
                            ),
                          ),
                          controller: _widthController,
                          focusNode: _widthFocusNode,
                          keyboardType: TextInputType.number,
                          onSubmitted: _updateWidth,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '高度',
                            suffixText: 'mm', // 添加毫米后缀
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 8.0,
                            ),
                          ),
                          controller: _heightController,
                          focusNode: _heightFocusNode,
                          keyboardType: TextInputType.number,
                          onSubmitted: _updateHeight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // DPI设置
                  const Text('DPI设置 (每英寸点数)'),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'DPI',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      helperText: '用于计算画布像素尺寸，默认300dpi',
                    ),
                    controller: _dpiController,
                    focusNode: _dpiFocusNode,
                    keyboardType: TextInputType.number,
                    onSubmitted: _updateDpi,
                  ),
                  const SizedBox(height: 8.0),

                  // 像素尺寸显示
                  Text(
                    '画布像素尺寸: ${_calculatePixelSize(width, height, dpi)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 背景设置
        ExpansionTile(
          title: const Text('背景设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('背景颜色'),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showEnhancedColorPicker(
                            context, '#${_backgroundColorController.text}'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: hexToColor(
                                '#${_backgroundColorController.text}'),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '颜色代码',
                            prefixText: '#',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller: _backgroundColorController,
                          readOnly: true, // 设置为只读
                          onTap: () => _showEnhancedColorPicker(
                              context, '#${_backgroundColorController.text}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 网格设置
        ExpansionTile(
          title: const Text('网格设置'),
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
                      Checkbox(
                        value:
                            widget.controller.state.gridVisible, // 从控制器直接获取当前状态
                        onChanged: (value) {
                          if (value != null) {
                            // 更新页面属性
                            widget.onPagePropertiesChanged(
                                {'gridVisible': value});
                            // 同步更新控制器的网格显示状态
                            widget.controller.state.gridVisible = value;
                            // 不直接调用 notifyListeners，而是通过属性更新触发控制器的更新
                          }
                        },
                      ),
                      const Text('显示网格'),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  const Text('网格大小'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: widget.controller.state.gridSize, // 从控制器获取当前值
                        min: 5.0,
                        max: 50.0,
                        divisions: 9,
                        label:
                            widget.controller.state.gridSize.toStringAsFixed(0),
                        onChanged: (value) {
                          setState(() {
                            // 更新页面属性
                            widget.onPagePropertiesChanged({'gridSize': value});
                            // 同步更新控制器的网格大小
                            widget.controller.state.gridSize = value;
                            // 不直接调用 notifyListeners，而是通过属性更新触发控制器的更新
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          '${widget.controller.state.gridSize.toStringAsFixed(0)} 像素',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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

  @override
  void didUpdateWidget(PagePropertyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当页面属性更新时，更新输入框的值
    if (widget.page != null && oldWidget.page != widget.page) {
      _widthController.text =
          ((widget.page!['width'] as num?)?.toDouble() ?? 210.0).toString();
      _heightController.text =
          ((widget.page!['height'] as num?)?.toDouble() ?? 297.0).toString();
      _dpiController.text =
          ((widget.page!['dpi'] as num?)?.toInt() ?? 300).toString();

      // 更新背景颜色控制器
      final backgroundColor =
          widget.page!['backgroundColor'] as String? ?? '#FFFFFF';
      _backgroundColorController.text = backgroundColor.startsWith('#')
          ? backgroundColor.substring(1)
          : backgroundColor;
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _dpiController.dispose();
    _backgroundColorController.dispose(); // 释放背景颜色控制器
    _widthFocusNode.removeListener(_handleWidthFocusChange);
    _heightFocusNode.removeListener(_handleHeightFocusChange);
    _dpiFocusNode.removeListener(_handleDpiFocusChange);
    _widthFocusNode.dispose();
    _heightFocusNode.dispose();
    _dpiFocusNode.dispose();
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  /// 将十六进制颜色字符串转换为Color对象
  Color hexToColor(String hexString) {
    try {
      // 处理空字符串或无效输入
      if (hexString.isEmpty) {
        debugPrint('Empty color string, returning default white');
        return Colors.white;
      }

      // 验证字符串是否包含有效的十六进制字符
      // 先移除 # 前缀
      String cleanHexString = hexString.replaceFirst('#', '');

      // 检查是否包含非十六进制字符
      final validHexPattern = RegExp(r'^[0-9A-Fa-f]+$');
      if (!validHexPattern.hasMatch(cleanHexString)) {
        // 如果包含无效字符，尝试提取有效部分
        final hexCharsOnly = RegExp(r'[0-9A-Fa-f]+')
            .allMatches(cleanHexString)
            .map((m) => m.group(0))
            .join('');

        if (hexCharsOnly.isEmpty) {
          debugPrint(
              'No valid hex characters found in "$hexString", returning default white');
          return Colors.white;
        }

        // 使用提取的有效字符
        cleanHexString = hexCharsOnly;
        debugPrint(
            'Extracted valid hex characters: "$cleanHexString" from "$hexString"');
      }

      // 处理不同长度的十六进制字符串
      if (cleanHexString.length == 3) {
        // 将 RGB 转换为 RRGGBB
        cleanHexString = cleanHexString.split('').map((e) => e + e).join('');
      }

      // 确保字符串长度正确
      if (cleanHexString.length > 8) {
        cleanHexString = cleanHexString.substring(0, 8);
      } else if (cleanHexString.length < 6) {
        // 如果字符串太短，填充为有效的颜色
        cleanHexString = cleanHexString.padRight(6, 'F');
      }

      // 添加透明度通道（如果需要）
      if (cleanHexString.length == 6) {
        cleanHexString = 'FF$cleanHexString'; // 添加完全不透明的 alpha 通道
      }

      // 解析颜色
      final colorValue = int.parse(cleanHexString, radix: 16);
      return Color(colorValue);
    } catch (e) {
      debugPrint('Error parsing color: $e');
      debugPrint('Problematic color string: "$hexString"');
      // 出错时返回默认颜色
      return Colors.white;
    }
  }

  @override
  void initState() {
    super.initState();

    // 初始化控制器和焦点节点
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _dpiController = TextEditingController();
    _backgroundColorController = TextEditingController();
    _widthFocusNode = FocusNode();
    _heightFocusNode = FocusNode();
    _dpiFocusNode = FocusNode();

    // 设置初始值
    if (widget.page != null) {
      _widthController.text =
          ((widget.page!['width'] as num?)?.toDouble() ?? 210.0).toString();
      _heightController.text =
          ((widget.page!['height'] as num?)?.toDouble() ?? 297.0).toString();
      _dpiController.text =
          ((widget.page!['dpi'] as num?)?.toInt() ?? 300).toString();

      // 设置背景颜色初始值
      final backgroundColor =
          widget.page!['backgroundColor'] as String? ?? '#FFFFFF';
      _backgroundColorController.text = backgroundColor.startsWith('#')
          ? backgroundColor.substring(1)
          : backgroundColor;
    }

    // 添加焦点监听器
    _widthFocusNode.addListener(_handleWidthFocusChange);
    _heightFocusNode.addListener(_handleHeightFocusChange);
    _dpiFocusNode.addListener(_handleDpiFocusChange);

    // 监听控制器状态变化，用于同步网格状态
    widget.controller.addListener(_handleControllerChange);
  }

  /// 计算像素尺寸
  String _calculatePixelSize(double width, double height, int dpi) {
    // 毫米转英寸，1英寸 = 25.4毫米
    final widthInches = width / 25.4;
    final heightInches = height / 25.4;

    // 计算像素尺寸
    final widthPixels = (widthInches * dpi).round();
    final heightPixels = (heightInches * dpi).round();

    return '$widthPixels × $heightPixels 像素';
  }

  /// 将颜色转换为十六进制字符串
  String _colorToHex(Color color) {
    try {
      // 使用安全的方式转换颜色
      final hex = color.toString();
      // 格式会是 Color(0xAARRGGBB) 或 Color(0xFFRRGGBB)
      final hexCode = hex.split('(0x')[1].split(')')[0];
      // 取后6位，即RRGGBB
      final colorCode =
          hexCode.length > 6 ? hexCode.substring(hexCode.length - 6) : hexCode;
      return '#$colorCode'; // 包含 # 前缀
    } catch (e) {
      debugPrint('Error converting color to hex: $e');
      return '#FFFFFF'; // 出错时返回默认白色
    }
  }

  /// 获取页面尺寸预设
  String _getPageSizePreset(double width, double height) {
    double portraitWidth = width;
    double portraitHeight = height;

    // 确保比较时使用纵向尺寸
    if (width > height) {
      portraitWidth = height;
      portraitHeight = width;
    }

    // 使用毫米单位进行比较
    if ((portraitWidth - 210.0).abs() < 1 &&
        (portraitHeight - 297.0).abs() < 1) {
      return 'A4';
    } else if ((portraitWidth - 148.0).abs() < 1 &&
        (portraitHeight - 210.0).abs() < 1) {
      return 'A5';
    } else {
      return 'custom';
    }
  }

  // 处理控制器状态变化
  void _handleControllerChange() {
    // 只在控制器的网格状态变化时重建UI
    setState(() {});
  }

  /// 处理DPI焦点变化
  void _handleDpiFocusChange() {
    if (!_dpiFocusNode.hasFocus) {
      _updateDpi(_dpiController.text);
    }
  }

  // 处理高度焦点变化
  void _handleHeightFocusChange() {
    if (!_heightFocusNode.hasFocus) {
      _updateHeight(_heightController.text);
    }
  }

  /// 处理页面尺寸预设变更
  void _handlePageSizePresetChange(String preset, String orientation) {
    double width, height;

    switch (preset) {
      case 'A4':
        width = 210.0; // A4 width in mm
        height = 297.0; // A4 height in mm
        break;
      case 'A5':
        width = 148.0; // A5 width in mm
        height = 210.0; // A5 height in mm
        break;
      case 'custom':
        // 不做任何操作，让用户自行输入
        return;
      default:
        return;
    }

    // 根据方向调整宽高
    if (orientation == 'landscape') {
      // 横向时交换宽高
      final temp = width;
      width = height;
      height = temp;
    }

    // 更新控制器的值
    _widthController.text = width.toString();
    _heightController.text = height.toString();

    // 一次性更新所有属性
    widget.onPagePropertiesChanged({
      'width': width,
      'height': height,
    });
  }

  // 处理宽度焦点变化
  void _handleWidthFocusChange() {
    if (!_widthFocusNode.hasFocus) {
      _updateWidth(_widthController.text);
    }
  }

  /// 显示增强的颜色选择器
  void _showEnhancedColorPicker(BuildContext context, String colorStr) {
    try {
      // 调试信息
      debugPrint('打开颜色选择器，初始颜色: $colorStr');

      // 解析颜色
      final color = hexToColor(colorStr);

      showDialog(
        context: context,
        builder: (context) => ColorPickerDialog(
          initialColor: color,
          onColorSelected: (selectedColor) {
            // 调试信息
            debugPrint('选择的颜色: $selectedColor');

            // 将颜色转换为十六进制字符串
            final hexColor = _colorToHex(selectedColor);
            debugPrint('转换后的颜色字符串: $hexColor');

            // 获取当前的不透明度
            final backgroundOpacity =
                (widget.page!['backgroundOpacity'] as num?)?.toDouble() ?? 1.0;

            // 更新页面属性，同时确保设置背景类型和不透明度
            widget.onPagePropertiesChanged({
              'backgroundColor': hexColor,
              'backgroundType': 'color',
              'backgroundOpacity': backgroundOpacity,
            });

            // 更新颜色代码控制器
            _backgroundColorController.text =
                hexColor.startsWith('#') ? hexColor.substring(1) : hexColor;

            // 强制刷新控制器状态，确保画布更新
            // 使用setState触发UI更新
            setState(() {});
          },
        ),
      );
    } catch (e) {
      // 如果出错，显示错误信息
      debugPrint('打开颜色选择器时出错: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打开颜色选择器时出错: $e')),
      );
    }
  }

  /// 更新DPI
  void _updateDpi(String value) {
    final newValue = int.tryParse(value);
    if (newValue != null && newValue > 0) {
      widget.onPagePropertiesChanged({'dpi': newValue});
    } else {
      // 如果输入无效，恢复原来的值
      if (widget.page != null) {
        _dpiController.text =
            ((widget.page!['dpi'] as num?)?.toInt() ?? 300).toString();
      }
    }
  }

  // 更新高度（毫米）
  void _updateHeight(String value) {
    final newValue = double.tryParse(value);
    if (newValue != null && newValue > 0) {
      // 直接传递毫米值，不需要转换
      // 实际的像素转换将在渲染时进行
      widget.onPagePropertiesChanged({'height': newValue});

      // 调试信息
      debugPrint('更新页面高度: $newValue 毫米');

      // 获取当前DPI
      final dpi = (widget.page!['dpi'] as num?)?.toInt() ?? 300;

      // 计算像素尺寸（仅用于调试）
      final heightInches = newValue / 25.4;
      final heightPixels = (heightInches * dpi).round();
      debugPrint('对应像素高度: $heightPixels 像素 (DPI: $dpi)');
    } else {
      // 如果输入无效，恢复原来的值
      if (widget.page != null) {
        _heightController.text =
            ((widget.page!['height'] as num?)?.toDouble() ?? 297.0).toString();
      }
    }
  }

  // 更新宽度（毫米）
  void _updateWidth(String value) {
    final newValue = double.tryParse(value);
    if (newValue != null && newValue > 0) {
      // 直接传递毫米值，不需要转换
      // 实际的像素转换将在渲染时进行
      widget.onPagePropertiesChanged({'width': newValue});

      // 调试信息
      debugPrint('更新页面宽度: $newValue 毫米');

      // 获取当前DPI
      final dpi = (widget.page!['dpi'] as num?)?.toInt() ?? 300;

      // 计算像素尺寸（仅用于调试）
      final widthInches = newValue / 25.4;
      final widthPixels = (widthInches * dpi).round();
      debugPrint('对应像素宽度: $widthPixels 像素 (DPI: $dpi)');
    } else {
      // 如果输入无效，恢复原来的值
      if (widget.page != null) {
        _widthController.text =
            ((widget.page!['width'] as num?)?.toDouble() ?? 210.0).toString();
      }
    }
  }
}
