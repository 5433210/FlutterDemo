import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/config/edit_page_logging_config.dart';
import '../../common/editable_number_field.dart';
import '../../common/m3_color_picker.dart';
import '../practice_edit_controller.dart';
import 'm3_panel_styles.dart';

/// Material 3 页面属性面板
class M3PagePropertyPanel extends StatefulWidget {
  final Map<String, dynamic>? page;
  final Function(Map<String, dynamic>) onPagePropertiesChanged;
  final PracticeEditController controller;

  const M3PagePropertyPanel({
    super.key,
    required this.controller,
    required this.page,
    required this.onPagePropertiesChanged,
  });

  @override
  State<M3PagePropertyPanel> createState() => _M3PagePropertyPanelState();
}

class _M3PagePropertyPanelState extends State<M3PagePropertyPanel> {
  // 宽度、高度和DPI输入控制器
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _dpiController;
  late TextEditingController _backgroundColorController;
  late FocusNode _widthFocusNode;
  late FocusNode _heightFocusNode;
  late FocusNode _dpiFocusNode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.page == null) {
      return Center(child: Text(l10n.noPageSelected));
    }

    final width = (widget.page!['width'] as num?)?.toDouble() ?? 595.0;
    final height = (widget.page!['height'] as num?)?.toDouble() ?? 842.0;
    final orientation = widget.page!['orientation'] as String? ?? 'portrait';
    final dpi = (widget.page!['dpi'] as num?)?.toInt() ?? 300;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        // 页面标题
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.description,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.practiceEditPageProperties,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // 页面尺寸设置
        M3PanelStyles.buildPersistentPanelCard(
          context: context,
          panelId: 'page_size_settings',
          title: l10n.pageSize,
          defaultExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 预设尺寸选择
                  Text('${l10n.presetSize}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        value: _getPageSizePreset(width, height),
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: colorScheme.outline,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'A4',
                            child: Text(l10n.a4Size),
                          ),
                          DropdownMenuItem(
                            value: 'A5',
                            child: Text(l10n.a5Size),
                          ),
                          DropdownMenuItem(
                            value: 'custom',
                            child: Text(l10n.customSize),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _handlePageSizePresetChange(value, orientation);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // 页面方向设置
                  Text('${l10n.pageOrientation}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(l10n.portrait),
                              value: 'portrait',
                              groupValue: orientation,
                              activeColor: colorScheme.primary,
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
                              title: Text(l10n.landscape),
                              value: 'landscape',
                              groupValue: orientation,
                              activeColor: colorScheme.primary,
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
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // 尺寸输入
                  Text('${l10n.dimensions}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: EditableNumberField(
                          label: l10n.width,
                          value: width,
                          suffix: 'mm',
                          min: 10,
                          max: 1000,
                          onChanged: (value) => _updateWidth(value.toString()),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: EditableNumberField(
                          label: l10n.height,
                          value: height,
                          suffix: 'mm',
                          min: 10,
                          max: 1000,
                          onChanged: (value) => _updateHeight(value.toString()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // DPI设置
                  Text('${l10n.ppiSetting}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: dpi.toDouble(),
                          min: 72,
                          max: 600,
                          divisions: 528, // 600-72 divisions
                          label: '${dpi.toString()} DPI',
                          activeColor: colorScheme.primary,
                          thumbColor: colorScheme.primary,
                          onChanged: (value) =>
                              _updateDpi(value.toInt().toString()),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: 'PPI',
                          value: dpi.toDouble(),
                          suffix: '',
                          min: 72,
                          max: 600,
                          decimalPlaces: 0,
                          onChanged: (value) =>
                              _updateDpi(value.toInt().toString()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),

                  // 像素尺寸显示
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: colorScheme.tertiary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l10n.canvasPixelSize}: ${_calculatePixelSize(width, height, dpi)}',
                            style: TextStyle(
                                fontSize: 14, color: colorScheme.tertiary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 背景颜色设置
        M3PanelStyles.buildPersistentPanelCard(
          context: context,
          panelId: 'page_background_color',
          title: l10n.backgroundColor,
          defaultExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          final color = await M3ColorPicker.show(
                            context,
                            initialColor: _getBackgroundColor(),
                            enableAlpha: false,
                          );
                          if (color != null) {
                            _updateBackgroundColor(color);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getBackgroundColor(),
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        l10n.backgroundColor,
                        style: TextStyle(
                          color: colorScheme.onSurface,
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
        M3PanelStyles.buildPersistentPanelCard(
          context: context,
          panelId: 'page_grid_settings',
          title: l10n.gridSettings,
          defaultExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 显示网格选项
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: SwitchListTile(
                      title: Text(l10n.showGrid),
                      value: widget.controller.state.gridVisible,
                      activeColor: colorScheme.primary,
                      onChanged: (value) {
                        // 更新页面属性
                        widget.onPagePropertiesChanged({'gridVisible': value});
                        // 同步更新控制器的网格显示状态
                        widget.controller.state.gridVisible = value;
                        // 不直接调用 notifyListeners，而是通过属性更新触发控制器的更新
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // 网格大小设置
                  Text('${l10n.gridSize}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: widget.controller.state.gridSize,
                          min: 5.0,
                          max: 50.0,
                          divisions: 9,
                          label: widget.controller.state.gridSize
                              .toStringAsFixed(0),
                          activeColor: colorScheme.primary,
                          thumbColor: colorScheme.primary,
                          onChanged: (value) {
                            setState(() {
                              // 更新页面属性
                              widget
                                  .onPagePropertiesChanged({'gridSize': value});
                              // 同步更新控制器的网格大小
                              widget.controller.state.gridSize = value;
                              // 不直接调用 notifyListeners，而是通过属性更新触发控制器的更新
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${widget.controller.state.gridSize.toStringAsFixed(0)} ${l10n.pixels}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
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
  void didUpdateWidget(M3PagePropertyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当页面属性更新时，更新输入框的值
    if (widget.page != null && oldWidget.page != widget.page) {
      _widthController.text =
          ((widget.page!['width'] as num?)?.toDouble() ?? 210.0).toString();
      _heightController.text =
          ((widget.page!['height'] as num?)?.toDouble() ?? 297.0).toString();
      _dpiController.text =
          ((widget.page!['dpi'] as num?)?.toInt() ?? 300).toString();

      // 更新背景颜色控制器 - 使用新格式
      String backgroundColor = '#FFFFFF';
      if (widget.page!.containsKey('background') &&
          (widget.page!['background'] as Map<String, dynamic>)
              .containsKey('value')) {
        backgroundColor = (widget.page!['background']
            as Map<String, dynamic>)['value'] as String;
      }
      _backgroundColorController.text = backgroundColor.startsWith('#')
          ? backgroundColor.substring(1)
          : backgroundColor;
    }
  }

  @override
  void dispose() {
    // 移除焦点监听器
    _widthFocusNode.removeListener(_handleWidthFocusChange);
    _heightFocusNode.removeListener(_handleHeightFocusChange);
    _dpiFocusNode.removeListener(_handleDpiFocusChange);

    // 移除控制器监听器
    widget.controller.removeListener(_handleControllerChange);

    // 释放控制器
    _widthController.dispose();
    _heightController.dispose();
    _dpiController.dispose();
    _backgroundColorController.dispose();

    // 释放焦点节点
    _widthFocusNode.dispose();
    _heightFocusNode.dispose();
    _dpiFocusNode.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _dpiController = TextEditingController();
    _backgroundColorController = TextEditingController();

    // 初始化焦点节点
    _widthFocusNode = FocusNode();
    _heightFocusNode = FocusNode();
    _dpiFocusNode = FocusNode();

    // 设置初始值
    if (widget.page != null) {
      _widthController.text =
          ((widget.page!['width'] as num?)?.toDouble() ?? 210.0).toString();
      _heightController.text =
          ((widget.page!['height'] as num?)?.toDouble() ?? 297.0).toString();

      // 设置DPI初始值 - 300 DPI是印刷品的行业标准，适合大多数高质量打印需求
      _dpiController.text =
          ((widget.page!['dpi'] as num?)?.toInt() ?? 300).toString();

      // 设置背景颜色初始值 - 使用新格式
      String backgroundColor = '#FFFFFF';
      if (widget.page!.containsKey('background') &&
          (widget.page!['background'] as Map<String, dynamic>)
              .containsKey('value')) {
        backgroundColor = (widget.page!['background']
            as Map<String, dynamic>)['value'] as String;
      }
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

    return '$widthPixels × $heightPixels ${AppLocalizations.of(context).pixels}';
  }

  /// 获取背景颜色
  Color _getBackgroundColor() {
    if (widget.page == null) {
      return Colors.white;
    }

    // 使用新格式
    if (widget.page!.containsKey('background') &&
        (widget.page!['background'] as Map<String, dynamic>)
            .containsKey('value')) {
      final background = widget.page!['background'] as Map<String, dynamic>;
      final colorStr = background['value'] as String;

      final color =
          Color(int.parse(colorStr.substring(1), radix: 16) | 0xFF000000);

      return color;
    }

    // 默认白色

    return Colors.white;
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

  /// 处理高度焦点变化
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

  /// 处理宽度焦点变化
  void _handleWidthFocusChange() {
    if (!_widthFocusNode.hasFocus) {
      _updateWidth(_widthController.text);
    }
  }

  /// 更新背景颜色
  void _updateBackgroundColor(Color color) {
    // 🔧 修复：使用正确的RGB属性（0-255整数）
    final colorHex =
        '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}';

    EditPageLogger.propertyPanelDebug(
      '更新页面背景颜色',
      tag: EditPageLoggingConfig.TAG_TEXT_PANEL,
      data: {
        'inputColor': color.toString(),
        'outputColorHex': colorHex,
        'red': color.red,
        'green': color.green,
        'blue': color.blue,
        'operation': 'update_background_color',
      },
    );

    // 使用新格式
    final background = {
      'type': 'color',
      'value': colorHex,
      'opacity': 1.0,
    };

    widget.onPagePropertiesChanged({'background': background});
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
      widget.onPagePropertiesChanged({'height': newValue});
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
      widget.onPagePropertiesChanged({'width': newValue});
    } else {
      // 如果输入无效，恢复原来的值
      if (widget.page != null) {
        _widthController.text =
            ((widget.page!['width'] as num?)?.toDouble() ?? 210.0).toString();
      }
    }
  }
}
