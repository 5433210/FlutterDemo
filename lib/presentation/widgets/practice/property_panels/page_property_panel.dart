import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';

/// 页面属性面板
class PagePropertyPanel extends StatefulWidget {
  final PracticeEditController controller;
  final Map<String, dynamic>? page;
  final Function(Map<String, dynamic>) onPagePropertiesChanged;

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
  // 背景颜色控制器
  late TextEditingController _backgroundColorController;

  // 页面尺寸
  late double _pageWidth;
  late double _pageHeight;

  // 页面方向
  late String _pageOrientation;

  // 背景透明度
  late double _backgroundOpacity;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '页面属性',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),

          // 尺寸设置
          _buildSection(
            title: '页面尺寸',
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: '宽度',
                        suffix: Text('px'),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller:
                          TextEditingController(text: _pageWidth.toString()),
                      onChanged: (value) {
                        final width = double.tryParse(value);
                        if (width != null && width > 0) {
                          setState(() {
                            _pageWidth = width;
                          });
                          _updatePageProperties();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: '高度',
                        suffix: Text('px'),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller:
                          TextEditingController(text: _pageHeight.toString()),
                      onChanged: (value) {
                        final height = double.tryParse(value);
                        if (height != null && height > 0) {
                          setState(() {
                            _pageHeight = height;
                          });
                          _updatePageProperties();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        // 设置A4尺寸，根据方向决定宽高
                        if (_pageOrientation == 'portrait') {
                          _pageWidth = 595.0; // A4 width (72dpi)
                          _pageHeight = 842.0; // A4 height (72dpi)
                        } else {
                          _pageWidth = 842.0; // A4 height as width
                          _pageHeight = 595.0; // A4 width as height
                        }
                      });
                      _updatePageProperties();
                    },
                    child: const Text('A4'),
                  ),
                  const SizedBox(width: 8.0),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        // 设置Letter尺寸，根据方向决定宽高
                        if (_pageOrientation == 'portrait') {
                          _pageWidth = 612.0; // Letter width (72dpi)
                          _pageHeight = 792.0; // Letter height (72dpi)
                        } else {
                          _pageWidth = 792.0; // Letter height as width
                          _pageHeight = 612.0; // Letter width as height
                        }
                      });
                      _updatePageProperties();
                    },
                    child: const Text('Letter'),
                  ),
                ],
              ),
            ],
          ),

          // 页面方向设置
          _buildSection(
            title: '页面方向',
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('纵向'),
                      value: 'portrait',
                      groupValue: _pageOrientation,
                      onChanged: (value) {
                        setState(() {
                          _pageOrientation = value!;
                          // 如果当前宽度大于高度，交换宽高
                          if (_pageWidth > _pageHeight) {
                            final temp = _pageWidth;
                            _pageWidth = _pageHeight;
                            _pageHeight = temp;
                          }
                        });
                        _updatePageProperties();
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('横向'),
                      value: 'landscape',
                      groupValue: _pageOrientation,
                      onChanged: (value) {
                        setState(() {
                          _pageOrientation = value!;
                          // 如果当前宽度小于高度，交换宽高
                          if (_pageWidth < _pageHeight) {
                            final temp = _pageWidth;
                            _pageWidth = _pageHeight;
                            _pageHeight = temp;
                          }
                        });
                        _updatePageProperties();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 背景设置
          _buildSection(
            title: '背景设置',
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: '背景颜色',
                        prefixText: '#',
                        border: OutlineInputBorder(),
                      ),
                      controller: _backgroundColorController,
                      onChanged: (value) {
                        // Update properties immediately when background color changes
                        _updatePageProperties();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _hexToColor(_backgroundColorController.text),
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.colorize, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  const Text('透明度:'),
                  Expanded(
                    child: Slider(
                      value: _backgroundOpacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      label: '${(_backgroundOpacity * 100).round()}%',
                      onChanged: (value) {
                        setState(() {
                          _backgroundOpacity = value;
                        });
                        // Update UI during sliding but mark as interactive
                        _updatePagePropertiesInteractive();
                      },
                      onChangeEnd: (value) {
                        // Record in undo/redo stack only when sliding ends
                        _updatePageProperties();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(_backgroundOpacity * 100).round()}%',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant PagePropertyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.page != oldWidget.page) {
      _initializeValues();
    }
  }

  @override
  void dispose() {
    _backgroundColorController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  // 构建面板分区
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ...children,
        const SizedBox(height: 16.0),
      ],
    );
  }

  /// 将十六进制颜色字符串转换为Color对象
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // 初始化值
  void _initializeValues() {
    final page = widget.page;
    if (page != null) {
      // 初始化尺寸
      _pageWidth = (page['width'] as num?)?.toDouble() ?? 595.0;
      _pageHeight = (page['height'] as num?)?.toDouble() ?? 842.0;

      // 初始化页面方向
      _pageOrientation = (page['orientation'] as String?) ?? 'portrait';

      // 初始化背景颜色
      String backgroundColor =
          (page['backgroundColor'] as String?) ?? '#FFFFFF';
      if (backgroundColor.startsWith('#')) {
        backgroundColor = backgroundColor.substring(1);
      }
      _backgroundColorController = TextEditingController(text: backgroundColor);

      // 初始化透明度
      _backgroundOpacity =
          (page['backgroundOpacity'] as num?)?.toDouble() ?? 1.0;
    } else {
      // 默认值
      _pageWidth = 595.0;
      _pageHeight = 842.0;
      _pageOrientation = 'portrait';
      _backgroundColorController = TextEditingController(text: 'FFFFFF');
      _backgroundOpacity = 1.0;
    }
  }

  /// 显示颜色选择器
  void _showColorPicker() {
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
    ];

    showDialog(
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
                  // 转换为十六进制字符串
                  final color = presetColors[index];
                  final hexColor =
                      '#${color.r.round().toRadixString(16).padLeft(2, '0')}${color.g.round().toRadixString(16).padLeft(2, '0')}${color.b.round().toRadixString(16).padLeft(2, '0')}'
                          .toUpperCase();
                  setState(() {
                    _backgroundColorController.text =
                        hexColor.substring(1); // 移除#前缀
                  });
                  _updatePageProperties();
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: presetColors[index],
                    border: Border.all(
                      color: presetColors[index] == Colors.white
                          ? Colors.grey
                          : presetColors[index],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // 更新页面属性 - 最终更新，记录撤销/重做历史
  void _updatePageProperties() {
    String backgroundColor = _backgroundColorController.text;
    if (!backgroundColor.startsWith('#')) {
      backgroundColor = '#$backgroundColor';
    }

    final properties = {
      'width': _pageWidth,
      'height': _pageHeight,
      'orientation': _pageOrientation,
      'backgroundColor': backgroundColor,
      'backgroundOpacity': _backgroundOpacity,
    };

    widget.onPagePropertiesChanged(properties);
  }

  // 更新页面属性 - 交互式更新，不记录撤销/重做历史
  void _updatePagePropertiesInteractive() {
    String backgroundColor = _backgroundColorController.text;
    if (!backgroundColor.startsWith('#')) {
      backgroundColor = '#$backgroundColor';
    }

    final properties = {
      'width': _pageWidth,
      'height': _pageHeight,
      'orientation': _pageOrientation,
      'backgroundColor': backgroundColor,
      'backgroundOpacity': _backgroundOpacity,
    };

    // Call the controller's method with isInteractive flag
    if (widget.controller.state.currentPageIndex >= 0) {
      final page = widget.controller.state.currentPage;
      if (page != null) {
        // Update the page properties directly without recording in undo/redo stack
        properties.forEach((key, value) {
          page[key] = value;
        });
        // Force a UI update without recording in undo/redo stack
        widget.controller.state.hasUnsavedChanges = true; // Mark as unsaved
        setState(() {}); // Update the UI
      }
    }
  }
}
