import 'package:flutter/material.dart';

class PracticePropertyPanel extends StatelessWidget {
  final Map<String, dynamic>? selectedElement;
  final Function(Map<String, dynamic>) onPropertyChanged;

  const PracticePropertyPanel({
    super.key,
    this.selectedElement,
    required this.onPropertyChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedElement == null) {
      return const Center(
        child: Text('请选择一个元素'),
      );
    }

    // 根据选中元素类型显示不同的属性编辑器
    switch (selectedElement!['type']) {
      case 'chars':
        return _buildCharsProperties(context);
      case 'text':
        return _buildTextProperties(context);
      case 'image':
        return _buildImageProperties(context);
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
                      onChanged: (value) => _updateProperty('fontSize', int.tryParse(value)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: '间距'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _updateProperty('spacing', int.tryParse(value)),
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
                      onChanged: (value) => _updateProperty('x', double.tryParse(value)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Y'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _updateProperty('y', double.tryParse(value)),
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
                      onChanged: (value) => _updateProperty('width', double.tryParse(value)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: '高度'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _updateProperty('height', double.tryParse(value)),
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

  Widget _buildTextProperties(BuildContext context) {
    // TODO: 实现文本元素属性编辑器
    return Container();
  }

  Widget _buildImageProperties(BuildContext context) {
    // TODO: 实现图片元素属性编辑器
    return Container();
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

  void _updateProperty(String key, dynamic value) {
    final updatedElement = Map<String, dynamic>.from(selectedElement!);
    updatedElement[key] = value;
    onPropertyChanged(updatedElement);
  }
}
