import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';
import 'practice_property_panel_base.dart';

/// 页面属性面板
class PagePropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic>? page;
  final Function(Map<String, dynamic>) onPagePropertiesChanged;

  const PagePropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.page,
    required this.onPagePropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    if (page == null) {
      return const Center(child: Text('未选择页面'));
    }

    final width = (page!['width'] as num?)?.toDouble() ?? 595.0;
    final height = (page!['height'] as num?)?.toDouble() ?? 842.0;
    final orientation = page!['orientation'] as String? ?? 'portrait';
    final backgroundColor = page!['backgroundColor'] as String? ?? '#ffffff';
    final gridVisible = page!['gridVisible'] as bool? ?? false;
    final gridSize = (page!['gridSize'] as num?)?.toDouble() ?? 20.0;

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
        materialExpansionTile(
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
                              if (width > height) {
                                // 如果当前宽度大于高度，交换宽高
                                _updateProperty('width', height);
                                _updateProperty('height', width);
                              }
                              _updateProperty('orientation', value);
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
                              if (width < height) {
                                // 如果当前宽度小于高度，交换宽高
                                _updateProperty('width', height);
                                _updateProperty('height', width);
                              }
                              _updateProperty('orientation', value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // 自定义尺寸输入
                  const Text('自定义尺寸 (像素)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '宽度',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller:
                              TextEditingController(text: width.toString()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null && newValue > 0) {
                              _updateProperty('width', newValue);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '高度',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller:
                              TextEditingController(text: height.toString()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null && newValue > 0) {
                              _updateProperty('height', newValue);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 背景设置
        materialExpansionTile(
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: hexToColor(backgroundColor),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '颜色代码',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller:
                              TextEditingController(text: backgroundColor),
                          onChanged: (value) {
                            if (value.startsWith('#') && value.length <= 7) {
                              _updateProperty('backgroundColor', value);
                            }
                          },
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
        materialExpansionTile(
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
                        value: gridVisible,
                        onChanged: (value) {
                          if (value != null) {
                            _updateProperty('gridVisible', value);
                          }
                        },
                      ),
                      const Text('显示网格'),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  const Text('网格大小'),
                  Slider(
                    value: gridSize,
                    min: 5.0,
                    max: 50.0,
                    divisions: 9,
                    label: gridSize.toStringAsFixed(0),
                    onChanged: (value) {
                      _updateProperty('gridSize', value);
                    },
                  ),
                  Text('${gridSize.toStringAsFixed(0)} 像素'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 获取页面尺寸预设
  String _getPageSizePreset(double width, double height) {
    if ((width - 595).abs() < 1 && (height - 842).abs() < 1) {
      return 'A4';
    } else if ((width - 420).abs() < 1 && (height - 595).abs() < 1) {
      return 'A5';
    } else {
      return 'custom';
    }
  }

  /// 处理页面尺寸预设变更
  void _handlePageSizePresetChange(String preset, String orientation) {
    double width, height;

    switch (preset) {
      case 'A4':
        width = 595.0; // A4 width (72dpi)
        height = 842.0; // A4 height (72dpi)
        break;
      case 'A5':
        width = 420.0; // A5 width (72dpi)
        height = 595.0; // A5 height (72dpi)
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

    _updateProperty('width', width);
    _updateProperty('height', height);
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onPagePropertiesChanged(updates);
  }
}
