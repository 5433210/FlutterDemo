import 'package:flutter/material.dart';

import '../../../pages/practices/adapters/page_property_adapter.dart';

/// 页面属性面板包装类，专为Canvas适配器设计
class M3PracticePropertyPanelPage extends StatelessWidget {
  final double pageWidth;
  final double pageHeight;
  final PageOrientation orientation;
  final double dpi;
  final Color backgroundColor;
  final String? backgroundImageUrl;
  final bool gridVisible;
  final double gridSize;
  final Color gridColor;
  final bool snapToGrid;
  final double pageMargin;

  final Function(double width, double height) onPageSizeChanged;
  final Function(PageOrientation orientation) onOrientationChanged;
  final Function(double dpi) onDpiChanged;
  final Function(Color color) onBackgroundColorChanged;
  final Function(String? imageUrl) onBackgroundImageChanged;
  final Function(bool visible) onGridVisibilityChanged;
  final Function(double size) onGridSizeChanged;
  final Function(Color color) onGridColorChanged;
  final Function(bool snap) onSnapToGridChanged;
  final Function(double margin) onPageMarginChanged;

  const M3PracticePropertyPanelPage({
    super.key,
    required this.pageWidth,
    required this.pageHeight,
    required this.orientation,
    required this.dpi,
    required this.backgroundColor,
    this.backgroundImageUrl,
    required this.gridVisible,
    required this.gridSize,
    required this.gridColor,
    required this.snapToGrid,
    required this.pageMargin,
    required this.onPageSizeChanged,
    required this.onOrientationChanged,
    required this.onDpiChanged,
    required this.onBackgroundColorChanged,
    required this.onBackgroundImageChanged,
    required this.onGridVisibilityChanged,
    required this.onGridSizeChanged,
    required this.onGridColorChanged,
    required this.onSnapToGridChanged,
    required this.onPageMarginChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面设置标题
            const Text(
              '页面设置',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),

            // 页面尺寸
            _buildSectionTitle('页面尺寸'),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    '宽度',
                    pageWidth.toString(),
                    (value) {
                      final width = double.tryParse(value);
                      if (width != null) {
                        onPageSizeChanged(width, pageHeight);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: _buildTextField(
                    '高度',
                    pageHeight.toString(),
                    (value) {
                      final height = double.tryParse(value);
                      if (height != null) {
                        onPageSizeChanged(pageWidth, height);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // 页面方向
            _buildSectionTitle('页面方向'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<PageOrientation>(
                    title: const Text('纵向'),
                    value: PageOrientation.portrait,
                    groupValue: orientation,
                    onChanged: (value) {
                      if (value != null) {
                        onOrientationChanged(value);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<PageOrientation>(
                    title: const Text('横向'),
                    value: PageOrientation.landscape,
                    groupValue: orientation,
                    onChanged: (value) {
                      if (value != null) {
                        onOrientationChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // 分辨率设置
            _buildSectionTitle('分辨率设置'),
            Slider(
              value: dpi,
              min: 72.0,
              max: 300.0,
              divisions: 4,
              label: '$dpi DPI',
              onChanged: (value) {
                onDpiChanged(value);
              },
            ),
            const SizedBox(height: 16.0),

            // 背景设置
            _buildSectionTitle('背景设置'),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // 在实际应用中，这里应该弹出颜色选择器
                    // 这里简化处理，只是通知颜色已经改变
                    onBackgroundColorChanged(Colors.blue);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                const Text('点击更改背景颜色'),
              ],
            ),

            // 网格设置
            _buildSectionTitle('网格设置'),
            SwitchListTile(
              title: const Text('显示网格'),
              value: gridVisible,
              onChanged: (value) {
                onGridVisibilityChanged(value);
              },
            ),
            if (gridVisible) ...[
              _buildSectionTitle('网格大小'),
              Slider(
                value: gridSize,
                min: 5.0,
                max: 50.0,
                divisions: 9,
                label: '${gridSize.toInt()} px',
                onChanged: (value) {
                  onGridSizeChanged(value);
                },
              ),
            ],

            // 网格吸附
            SwitchListTile(
              title: const Text('吸附到网格'),
              value: snapToGrid,
              onChanged: (value) {
                onSnapToGridChanged(value);
              },
            ),

            // 页面边距
            _buildSectionTitle('页面边距'),
            Slider(
              value: pageMargin,
              min: 0.0,
              max: 50.0,
              divisions: 10,
              label: '${pageMargin.toInt()} px',
              onChanged: (value) {
                onPageMarginChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16.0,
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String initialValue, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      controller: TextEditingController(text: initialValue),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }
}
