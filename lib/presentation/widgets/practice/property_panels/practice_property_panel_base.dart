import 'dart:async';

import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';
import 'practice_property_panel_page.dart';

/// 属性面板组件基类
abstract class PracticePropertyPanel extends StatelessWidget {
  // 防抖动计时器和上次值的静态变量
  static Timer? _debounceTimer;
  static String _lastProcessedValue = '';

  // 使用静态变量保存控制器实例，以保持焦点
  static final Map<String, TextEditingController> _numberControllers = {};

  final PracticeEditController controller;

  const PracticePropertyPanel({
    Key? key,
    required this.controller,
  }) : super(key: key);

  /// 构建通用几何属性区域
  Widget buildGeometrySection({
    required String title,
    required double x,
    required double y,
    required double width,
    required double height,
    required double rotation,
    required Function(double) onXChanged,
    required Function(double) onYChanged,
    required Function(double) onWidthChanged,
    required Function(double) onHeightChanged,
    required Function(double) onRotationChanged,
  }) {
    return materialExpansionTile(
      title: Text(title),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // 位置控制
              Row(
                children: [
                  Expanded(
                    child: _buildOptimizedNumberField(
                      label: 'X',
                      value: x,
                      onChanged: onXChanged,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildOptimizedNumberField(
                      label: 'Y',
                      value: y,
                      onChanged: onYChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // 尺寸控制
              Row(
                children: [
                  Expanded(
                    child: _buildOptimizedNumberField(
                      label: '宽度',
                      value: width,
                      onChanged: (value) {
                        if (value > 0) {
                          onWidthChanged(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildOptimizedNumberField(
                      label: '高度',
                      value: height,
                      onChanged: (value) {
                        if (value > 0) {
                          onHeightChanged(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // 旋转控制
              _buildOptimizedNumberField(
                label: '旋转角度',
                value: rotation,
                suffix: '°',
                onChanged: onRotationChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建通用视觉属性区域
  Widget buildVisualSection({
    required String title,
    required double opacity,
    required Function(double) onOpacityChanged,
  }) {
    // 使用静态变量保存当前值，以便在拖动结束时记录操作
    double currentOpacity = 0.0;

    return materialExpansionTile(
      title: Text(title),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('透明度'),
              StatefulBuilder(
                builder: (context, setState) {
                  // 初始化当前值
                  if (currentOpacity != opacity) {
                    currentOpacity = opacity;
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: currentOpacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label:
                              '${(currentOpacity * 100).toStringAsFixed(0)}%',
                          // 在拖动过程中只更新UI，不记录操作
                          onChanged: (value) {
                            setState(() {
                              currentOpacity = value;
                            });
                          },
                          // 在拖动结束时记录操作
                          onChangeEnd: (value) {
                            onOpacityChanged(value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                            '${(currentOpacity * 100).toStringAsFixed(0)}%'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 将十六进制颜色字符串转换为Color对象
  Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Helper method to create Material-wrapped ExpansionTile
  Widget materialExpansionTile({
    required Widget title,
    List<Widget> children = const <Widget>[],
    bool initiallyExpanded = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        title: title,
        initiallyExpanded: initiallyExpanded,
        children: children,
      ),
    );
  }

  /// 构建优化的数字输入字段
  Widget _buildOptimizedNumberField({
    required String label,
    required double value,
    String? suffix,
    required Function(double) onChanged,
  }) {
    // 使用唯一的键来标识控制器
    final String key = label;
    final String valueStr = value.toStringAsFixed(0);

    // 初始化控制器，如果不存在
    if (!_numberControllers.containsKey(key)) {
      _numberControllers[key] = TextEditingController(text: valueStr);
    }
    // 只在外部值与当前输入值不同时更新，避免光标重置
    else if (_numberControllers[key]!.text != valueStr &&
        !_numberControllers[key]!.text.contains(RegExp(r'[^0-9.-]'))) {
      // 保存当前光标位置
      final selection = _numberControllers[key]!.selection;

      // 更新文本
      _numberControllers[key]!.value = TextEditingValue(
        text: valueStr,
        selection: TextSelection(
          baseOffset: selection.baseOffset.clamp(0, valueStr.length),
          extentOffset: selection.extentOffset.clamp(0, valueStr.length),
        ),
      );
    }

    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        suffixText: suffix,
      ),
      controller: _numberControllers[key],
      keyboardType: TextInputType.number,
      onChanged: (text) {
        // 使用防抖动处理
        _debounceNumberInput(text, onChanged);
      },
    );
  }

  /// 防抖动处理数字输入
  void _debounceNumberInput(String text, Function(double) onChanged) {
    // 取消之前的定时器
    _debounceTimer?.cancel();

    // 验证输入是否为有效数字
    final numValue = double.tryParse(text);
    if (numValue == null && text.isNotEmpty) {
      return; // 无效数字输入，不处理
    }

    // 如果值没有变化，不处理
    if (text == _lastProcessedValue) {
      return;
    }

    // 设置新的定时器
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (numValue != null) {
        onChanged(numValue);
        _lastProcessedValue = text;
      }
    });
  }

  /// 创建集字属性面板
  static Widget forCollection({
    required PracticeEditController controller,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
    required Function(String) onUpdateChars,
  }) {
    return _CollectionPropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
      onUpdateChars: onUpdateChars,
    );
  }

  /// 创建组合属性面板
  static Widget forGroup({
    required PracticeEditController controller,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
  }) {
    return _GroupPropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
    );
  }

  /// 创建图片属性面板
  static Widget forImage({
    required PracticeEditController controller,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
    required VoidCallback onSelectImage,
  }) {
    return _ImagePropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
      onSelectImage: onSelectImage,
    );
  }

  /// 创建图层属性面板
  static Widget forLayer({
    required PracticeEditController controller,
    required Map<String, dynamic> layer,
    required Function(Map<String, dynamic>) onLayerPropertiesChanged,
  }) {
    return _LayerPropertyPanel(
      controller: controller,
      layer: layer,
      onLayerPropertiesChanged: onLayerPropertiesChanged,
    );
  }

  /// 创建多选属性面板
  static Widget forMultiSelection({
    required PracticeEditController controller,
    required List<String> selectedIds,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
  }) {
    return _MultiSelectionPropertyPanel(
      controller: controller,
      selectedIds: selectedIds,
      onElementPropertiesChanged: onElementPropertiesChanged,
    );
  }

  /// 创建页面属性面板
  static Widget forPage({
    required PracticeEditController controller,
    required Map<String, dynamic>? page,
    required Function(Map<String, dynamic>) onPagePropertiesChanged,
  }) {
    return PagePropertyPanel(
      controller: controller,
      page: page,
      onPagePropertiesChanged: onPagePropertiesChanged,
    );
  }

  /// 创建文本属性面板
  static Widget forText({
    required PracticeEditController controller,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
  }) {
    return _TextPropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
    );
  }
}

class _CollectionPropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;

  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final Function(String) onUpdateChars;
  // 前向声明，实际实现在 practice_property_panel_collection.dart
  const _CollectionPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onUpdateChars,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('实现在 practice_property_panel_collection.dart 中');
  }
}

class _GroupPropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;

  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  // 前向声明，实际实现在 practice_property_panel_group.dart
  const _GroupPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('实现在 practice_property_panel_group.dart 中');
  }
}

class _ImagePropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;

  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final VoidCallback onSelectImage;
  // 前向声明，实际实现在 practice_property_panel_image.dart
  const _ImagePropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onSelectImage,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('实现在 practice_property_panel_image.dart 中');
  }
}

class _LayerPropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> layer;

  final Function(Map<String, dynamic>) onLayerPropertiesChanged;
  // 前向声明，实际实现在 practice_property_panel_layer.dart
  const _LayerPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.layer,
    required this.onLayerPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('实现在 practice_property_panel_layer.dart 中');
  }
}

class _MultiSelectionPropertyPanel extends PracticePropertyPanel {
  final List<String> selectedIds;

  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  // 前向声明，实际实现在 practice_property_panel_multi.dart
  const _MultiSelectionPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.selectedIds,
    required this.onElementPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('实现在 practice_property_panel_multi.dart 中');
  }
}

// 导入各个面板类的前向声明

class _TextPropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;

  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  // 前向声明，实际实现在 practice_property_panel_text.dart
  const _TextPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('实现在 practice_property_panel_text.dart 中');
  }
}
