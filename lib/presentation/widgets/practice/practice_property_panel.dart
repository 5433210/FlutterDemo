import 'package:flutter/material.dart';

class PracticePropertyPanel extends StatelessWidget {
  final Map<String, dynamic>? selectedElement;
  final Function(Map<String, dynamic>) onPropertyChanged;
  final bool isGroupSelection;

  const PracticePropertyPanel({
    super.key,
    this.selectedElement,
    required this.onPropertyChanged,
    this.isGroupSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedElement == null) {
      return const Center(
        child: Text('请选择一个元素'),
      );
    }

    // 如果是多选模式
    if (isGroupSelection) {
      return _buildGroupSelectionProperties(context);
    }

    // 根据选中元素类型显示不同的属性编辑器
    switch (selectedElement!['type']) {
      case 'collection':
        return _buildCollectionProperties(context);
      case 'text':
        return _buildTextProperties(context);
      case 'image':
        return _buildImageProperties(context);
      case 'group':
        return _buildGroupProperties(context);
      default:
        return const Center(
          child: Text('未知元素类型'),
        );
    }
  }

  Widget _buildCharsProperties(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本属性
          _buildSection(
            '基本属性',
            [
              TextField(
                decoration: const InputDecoration(labelText: '内容'),
                onChanged: (value) => _updateProperty('content', value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: '字号'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          _updateProperty('fontSize', int.tryParse(value)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: '间距'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          _updateProperty('spacing', int.tryParse(value)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 位置和尺寸
          _buildSection(
            '位置和尺寸',
            [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'X'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          _updateProperty('x', double.tryParse(value)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Y'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          _updateProperty('y', double.tryParse(value)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: '宽度'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          _updateProperty('width', double.tryParse(value)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: '高度'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          _updateProperty('height', double.tryParse(value)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 样式
          _buildSection(
            '样式',
            [
              // TODO: 添加颜色选择器和其他样式属性
            ],
          ),
        ],
      ),
    );
  }

  /// 构建集字元素属性面板
  Widget _buildCollectionProperties(BuildContext context) {
    final characters = selectedElement!['characters'] as String? ?? '';
    final direction = selectedElement!['direction'] as String? ?? 'horizontal';
    final characterSpacing =
        (selectedElement!['characterSpacing'] as num?)?.toDouble() ?? 10.0;
    final lineSpacing =
        (selectedElement!['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final characterSize =
        (selectedElement!['characterSize'] as num?)?.toDouble() ?? 50.0;
    final fontColor = selectedElement!['fontColor'] as String? ?? '#000000';
    final backgroundColor =
        selectedElement!['backgroundColor'] as String? ?? '#FFFFFF';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本属性
          _buildSection('基本属性', [
            TextField(
              decoration: const InputDecoration(labelText: '字符'),
              controller: TextEditingController(text: characters),
              onChanged: (value) => _updateProperty('characters', value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '方向'),
              value: direction,
              items: const [
                DropdownMenuItem(value: 'horizontal', child: Text('水平')),
                DropdownMenuItem(value: 'vertical', child: Text('垂直')),
                DropdownMenuItem(
                    value: 'horizontalReversed', child: Text('水平反向')),
                DropdownMenuItem(
                    value: 'verticalReversed', child: Text('垂直反向')),
              ],
              onChanged: (value) => _updateProperty('direction', value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: '字符间距'),
                    controller: TextEditingController(
                        text: characterSpacing.toString()),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _updateProperty('characterSpacing',
                        double.tryParse(value) ?? characterSpacing),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: '行间距'),
                    controller:
                        TextEditingController(text: lineSpacing.toString()),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _updateProperty(
                        'lineSpacing', double.tryParse(value) ?? lineSpacing),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: '字符大小'),
              controller: TextEditingController(text: characterSize.toString()),
              keyboardType: TextInputType.number,
              onChanged: (value) => _updateProperty(
                  'characterSize', double.tryParse(value) ?? characterSize),
            ),
          ]),
          // 位置和尺寸
          _buildPositionAndSizeSection(),
          // 样式
          _buildSection('样式', [
            Row(
              children: [
                const Text('字体颜色：'),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(int.parse(fontColor.substring(1), radix: 16) +
                        0xFF000000),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                TextButton(
                  child: const Text('选择颜色'),
                  onPressed: () {
                    // 显示颜色选择器
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('背景颜色：'),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(
                        int.parse(backgroundColor.substring(1), radix: 16) +
                            0xFF000000),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                TextButton(
                  child: const Text('选择颜色'),
                  onPressed: () {
                    // 显示颜色选择器
                  },
                ),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  /// 构建组合元素属性面板
  Widget _buildGroupProperties(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本属性
          _buildSection('基本属性', [
            Text('组合元素 - ${selectedElement!['id']}'),
            const SizedBox(height: 8),
            Text(
                '包含 ${(selectedElement!['children'] as List<dynamic>).length} 个元素'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.group_work_outlined),
              label: const Text('取消组合'),
              onPressed: () {
                // 取消组合
                final updatedElement =
                    Map<String, dynamic>.from(selectedElement!);
                updatedElement['ungroup'] = true; // 标记为需要取消组合
                onPropertyChanged(updatedElement);
              },
            ),
          ]),
          // 位置和尺寸
          _buildPositionAndSizeSection(),
        ],
      ),
    );
  }

  /// 构建多选属性面板
  Widget _buildGroupSelectionProperties(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text('多选模式',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          // 共同属性
          _buildSection('共同属性', [
            // 透明度
            Row(
              children: [
                const Text('透明度：'),
                Expanded(
                  child: Slider(
                    value: 1.0, // 默认值
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '1.0',
                    onChanged: (value) {
                      // 更新所有选中元素的透明度
                    },
                  ),
                ),
              ],
            ),
            // 锁定状态
            Row(
              children: [
                const Text('锁定：'),
                Switch(
                  value: false, // 默认值
                  onChanged: (value) {
                    // 更新所有选中元素的锁定状态
                  },
                ),
              ],
            ),
          ]),
          // 组合操作
          _buildSection('组合操作', [
            ElevatedButton.icon(
              icon: const Icon(Icons.group_work),
              label: const Text('组合选中元素'),
              onPressed: () {
                // 组合选中元素
                final updatedElement =
                    Map<String, dynamic>.from(selectedElement!);
                updatedElement['group'] = true; // 标记为需要组合
                onPropertyChanged(updatedElement);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.align_horizontal_center),
              label: const Text('水平对齐'),
              onPressed: () {
                // 水平对齐
                final updatedElement =
                    Map<String, dynamic>.from(selectedElement!);
                updatedElement['alignHorizontal'] = true;
                onPropertyChanged(updatedElement);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.align_vertical_center),
              label: const Text('垂直对齐'),
              onPressed: () {
                // 垂直对齐
                final updatedElement =
                    Map<String, dynamic>.from(selectedElement!);
                updatedElement['alignVertical'] = true;
                onPropertyChanged(updatedElement);
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildImageProperties(BuildContext context) {
    final imageUrl = selectedElement!['imageUrl'] as String? ?? '';
    final opacity = (selectedElement!['opacity'] as num?)?.toDouble() ?? 1.0;
    final flipHorizontal = selectedElement!['flipHorizontal'] as bool? ?? false;
    final flipVertical = selectedElement!['flipVertical'] as bool? ?? false;
    final fit = selectedElement!['fit'] as String? ?? 'contain';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本属性
          _buildSection('基本属性', [
            TextField(
              decoration: const InputDecoration(labelText: '图片URL'),
              controller: TextEditingController(text: imageUrl),
              onChanged: (value) => _updateProperty('imageUrl', value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('透明度：'),
                Expanded(
                  child: Slider(
                    value: opacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: opacity.toStringAsFixed(1),
                    onChanged: (value) => _updateProperty('opacity', value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('水平翻转'),
                    value: flipHorizontal,
                    onChanged: (value) =>
                        _updateProperty('flipHorizontal', value),
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('垂直翻转'),
                    value: flipVertical,
                    onChanged: (value) =>
                        _updateProperty('flipVertical', value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '适应方式'),
              value: fit,
              items: const [
                DropdownMenuItem(value: 'contain', child: Text('包含')),
                DropdownMenuItem(value: 'cover', child: Text('覆盖')),
                DropdownMenuItem(value: 'fill', child: Text('填充')),
                DropdownMenuItem(value: 'fitWidth', child: Text('适应宽度')),
                DropdownMenuItem(value: 'fitHeight', child: Text('适应高度')),
                DropdownMenuItem(value: 'none', child: Text('无')),
              ],
              onChanged: (value) => _updateProperty('fit', value),
            ),
          ]),
          // 位置和尺寸
          _buildPositionAndSizeSection(),
        ],
      ),
    );
  }

  /// 构建位置和尺寸部分
  Widget _buildPositionAndSizeSection() {
    final x = (selectedElement!['x'] as num?)?.toDouble() ?? 0.0;
    final y = (selectedElement!['y'] as num?)?.toDouble() ?? 0.0;
    final width = (selectedElement!['width'] as num?)?.toDouble() ?? 100.0;
    final height = (selectedElement!['height'] as num?)?.toDouble() ?? 100.0;
    final rotation = (selectedElement!['rotation'] as num?)?.toDouble() ?? 0.0;

    return _buildSection('位置和尺寸', [
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(labelText: 'X'),
              controller: TextEditingController(text: x.toString()),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  _updateProperty('x', double.tryParse(value) ?? x),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(labelText: 'Y'),
              controller: TextEditingController(text: y.toString()),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  _updateProperty('y', double.tryParse(value) ?? y),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(labelText: '宽度'),
              controller: TextEditingController(text: width.toString()),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  _updateProperty('width', double.tryParse(value) ?? width),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(labelText: '高度'),
              controller: TextEditingController(text: height.toString()),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  _updateProperty('height', double.tryParse(value) ?? height),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextField(
        decoration: const InputDecoration(labelText: '旋转角度'),
        controller: TextEditingController(text: rotation.toString()),
        keyboardType: TextInputType.number,
        onChanged: (value) =>
            _updateProperty('rotation', double.tryParse(value) ?? rotation),
      ),
    ]);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextProperties(BuildContext context) {
    final text = selectedElement!['text'] as String? ?? '';
    final fontSize = (selectedElement!['fontSize'] as num?)?.toDouble() ?? 14.0;
    final fontFamily = selectedElement!['fontFamily'] as String? ?? 'Arial';
    final fontColor = selectedElement!['fontColor'] as String? ?? '#000000';
    final backgroundColor =
        selectedElement!['backgroundColor'] as String? ?? '#FFFFFF';
    final textAlign = selectedElement!['textAlign'] as String? ?? 'left';
    final lineSpacing =
        (selectedElement!['lineSpacing'] as num?)?.toDouble() ?? 1.0;
    final letterSpacing =
        (selectedElement!['letterSpacing'] as num?)?.toDouble() ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本属性
          _buildSection('基本属性', [
            TextField(
              decoration: const InputDecoration(labelText: '文本内容'),
              controller: TextEditingController(text: text),
              maxLines: 5,
              onChanged: (value) => _updateProperty('text', value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: '字号'),
                    controller:
                        TextEditingController(text: fontSize.toString()),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _updateProperty(
                        'fontSize', double.tryParse(value) ?? fontSize),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: '字体'),
                    value: fontFamily,
                    items: const [
                      DropdownMenuItem(value: 'Arial', child: Text('Arial')),
                      DropdownMenuItem(
                          value: 'Times New Roman',
                          child: Text('Times New Roman')),
                      DropdownMenuItem(
                          value: 'Courier New', child: Text('Courier New')),
                      DropdownMenuItem(value: 'SimSun', child: Text('宋体')),
                      DropdownMenuItem(value: 'KaiTi', child: Text('楷体')),
                    ],
                    onChanged: (value) => _updateProperty('fontFamily', value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '对齐方式'),
              value: textAlign,
              items: const [
                DropdownMenuItem(value: 'left', child: Text('左对齐')),
                DropdownMenuItem(value: 'center', child: Text('居中')),
                DropdownMenuItem(value: 'right', child: Text('右对齐')),
                DropdownMenuItem(value: 'justify', child: Text('两端对齐')),
              ],
              onChanged: (value) => _updateProperty('textAlign', value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: '行间距'),
                    controller:
                        TextEditingController(text: lineSpacing.toString()),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _updateProperty(
                        'lineSpacing', double.tryParse(value) ?? lineSpacing),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: '字间距'),
                    controller:
                        TextEditingController(text: letterSpacing.toString()),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _updateProperty('letterSpacing',
                        double.tryParse(value) ?? letterSpacing),
                  ),
                ),
              ],
            ),
          ]),
          // 位置和尺寸
          _buildPositionAndSizeSection(),
          // 样式
          _buildSection('样式', [
            Row(
              children: [
                const Text('字体颜色：'),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(int.parse(fontColor.substring(1), radix: 16) +
                        0xFF000000),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                TextButton(
                  child: const Text('选择颜色'),
                  onPressed: () {
                    // 显示颜色选择器
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('背景颜色：'),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(
                        int.parse(backgroundColor.substring(1), radix: 16) +
                            0xFF000000),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                TextButton(
                  child: const Text('选择颜色'),
                  onPressed: () {
                    // 显示颜色选择器
                  },
                ),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  void _updateProperty(String key, dynamic value) {
    final updatedElement = Map<String, dynamic>.from(selectedElement!);
    updatedElement[key] = value;
    onPropertyChanged(updatedElement);
  }
}
