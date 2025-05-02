import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../practice_edit_controller.dart';
import 'm3_collection_property_panel.dart';
import 'm3_element_common_property_panel.dart';
import 'm3_layer_info_panel.dart';
import 'm3_practice_property_panel_group.dart';
import 'm3_practice_property_panel_image.dart';
import 'm3_practice_property_panel_layer.dart';
import 'm3_practice_property_panel_multi.dart';
import 'm3_practice_property_panel_page.dart';
import 'm3_practice_property_panel_text.dart';

/// Material 3 属性面板组件基类
abstract class M3PracticePropertyPanel extends StatelessWidget {
  // 防抖动计时器和上次值的静态变量
  static Timer? _debounceTimer;
  static String _lastProcessedValue = '';

  // 使用静态变量保存控制器实例，以保持焦点
  static final Map<String, TextEditingController> _numberControllers = {};

  final PracticeEditController controller;

  const M3PracticePropertyPanel({
    super.key,
    required this.controller,
  });

  /// 构建通用几何属性区域
  Widget buildGeometrySection({
    required BuildContext context,
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
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return m3ExpansionTile(
      context: context,
      title: title,
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
                      context: context,
                      label: 'X',
                      value: x,
                      onChanged: onXChanged,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildOptimizedNumberField(
                      context: context,
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
                      context: context,
                      label: l10n.width,
                      value: width,
                      onChanged: onWidthChanged,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildOptimizedNumberField(
                      context: context,
                      label: l10n.height,
                      value: height,
                      onChanged: onHeightChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // 旋转控制
              _buildOptimizedNumberField(
                context: context,
                label: l10n.rotation,
                value: rotation,
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
    required BuildContext context,
    required String title,
    required double opacity,
    required Function(double) onOpacityChanged,
  }) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 使用静态变量保存当前值，以便在拖动结束时记录操作
    double currentOpacity = 0.0;

    return m3ExpansionTile(
      context: context,
      title: title,
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.opacity),
              StatefulBuilder(
                builder: (context, setState) {
                  // 初始化当前值
                  if (currentOpacity != opacity) {
                    currentOpacity = opacity;
                  }

                  return Column(
                    children: [
                      Slider(
                        value: currentOpacity,
                        min: 0.0,
                        max: 1.0,
                        divisions: 100,
                        label: '${(currentOpacity * 100).toStringAsFixed(0)}%',
                        onChanged: (value) {
                          setState(() {
                            currentOpacity = value;
                          });
                          // 实时更新UI，但不记录操作
                          onOpacityChanged(value);
                        },
                        onChangeEnd: (value) {
                          // 拖动结束时记录操作
                          onOpacityChanged(value);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0%', style: textTheme.bodySmall),
                          Text('50%', style: textTheme.bodySmall),
                          Text('100%', style: textTheme.bodySmall),
                        ],
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

  /// Helper method to create Material 3 ExpansionTile
  Widget m3ExpansionTile({
    required BuildContext context,
    required String title,
    List<Widget> children = const <Widget>[],
    bool initiallyExpanded = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          initiallyExpanded: initiallyExpanded,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          iconColor: colorScheme.primary,
          backgroundColor: colorScheme.surfaceContainerLow,
          collapsedBackgroundColor: colorScheme.surfaceContainerLow,
          childrenPadding: EdgeInsets.zero,
          children: children,
        ),
      ),
    );
  }

  /// 构建优化的数字输入字段
  Widget _buildOptimizedNumberField({
    required BuildContext context,
    required String label,
    required double value,
    String? suffix,
    required Function(double) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 使用唯一的键来标识控制器
    final String key = label;
    final String valueStr = value.toStringAsFixed(0);

    // 初始化控制器，如果不存在
    if (!_numberControllers.containsKey(key)) {
      _numberControllers[key] = TextEditingController(text: valueStr);
    }

    // 如果值发生变化，更新控制器文本
    if (_numberControllers[key]!.text != valueStr) {
      _numberControllers[key]!.text = valueStr;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4.0),
        TextField(
          controller: _numberControllers[key],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color: colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color: colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2.0,
              ),
            ),
            suffixText: suffix,
          ),
          onChanged: (text) {
            // 防抖动处理
            if (_debounceTimer?.isActive ?? false) {
              _debounceTimer!.cancel();
            }

            // 如果值没有变化，不处理
            if (text == _lastProcessedValue) {
              return;
            }

            _lastProcessedValue = text;
            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
              final value = double.tryParse(text);
              if (value != null) {
                onChanged(value);
              }
            });
          },
        ),
      ],
    );
  }

  /// 创建集字属性面板
  static Widget forCollection({
    required PracticeEditController controller,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
    required Function(String) onUpdateChars,
    WidgetRef? ref,
  }) {
    return M3CollectionPropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
      onUpdateChars: onUpdateChars,
      ref: ref,
    );
  }

  /// 创建元素通用属性面板
  static Widget forElementCommon({
    required PracticeEditController controller,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
  }) {
    return M3ElementCommonPropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
    );
  }

  /// 创建组合属性面板
  static Widget forGroup({
    required PracticeEditController controller,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
  }) {
    return M3GroupPropertyPanel(
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
    required WidgetRef ref,
  }) {
    return M3ImagePropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
      onSelectImage: onSelectImage,
      ref: ref,
    );
  }

  /// 创建图层属性面板
  static Widget forLayer({
    required PracticeEditController controller,
    required Map<String, dynamic> layer,
    required Function(Map<String, dynamic>) onLayerPropertiesChanged,
  }) {
    return M3LayerPropertyPanel(
      controller: controller,
      layer: layer,
      onLayerPropertiesChanged: onLayerPropertiesChanged,
    );
  }

  /// 创建图层信息面板
  static Widget forLayerInfo({
    required Map<String, dynamic>? layer,
  }) {
    return M3LayerInfoPanel(
      layer: layer,
    );
  }

  /// 创建多选属性面板
  static Widget forMultiSelection({
    required PracticeEditController controller,
    required List<String> selectedIds,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
  }) {
    return M3MultiSelectionPropertyPanel(
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
    return M3PagePropertyPanel(
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
    return M3TextPropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
    );
  }
}
