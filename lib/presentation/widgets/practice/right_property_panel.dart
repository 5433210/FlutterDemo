import 'package:flutter/material.dart';

import '../../../domain/models/practice/practice_element.dart';
import '../../../domain/models/practice/practice_page.dart';
import 'property_panels/collection_element_property_panel.dart';
import 'property_panels/group_element_property_panel.dart';
import 'property_panels/image_element_property_panel.dart';
import 'property_panels/page_property_panel.dart';
import 'property_panels/text_element_property_panel.dart';

/// 右侧属性面板容器
class RightPropertyPanel extends StatelessWidget {
  final PracticePage page;
  final Function(PracticePage) onPageChanged;
  final PracticeElement? selectedElement;
  final Function(PracticeElement)? onElementChanged;
  final bool isGroupSelection;
  final VoidCallback? onUngroup;

  const RightPropertyPanel({
    Key? key,
    required this.page,
    required this.onPageChanged,
    this.selectedElement,
    this.onElementChanged,
    this.isGroupSelection = false,
    this.onUngroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 如果没有选中元素，显示页面属性
    if (selectedElement == null) {
      return PagePropertyPanel(
        page: page,
        onPageChanged: onPageChanged,
      );
    }

    // 如果是多选状态，显示组合操作面板
    if (isGroupSelection) {
      return _buildGroupSelectionPanel();
    }

    // 根据选中元素类型显示对应的属性面板
    switch (selectedElement!.type) {
      case 'text':
        return TextElementPropertyPanel(
          element: selectedElement as TextElement,
          onElementChanged: _handleElementChanged,
        );
      case 'image':
        return ImageElementPropertyPanel(
          element: selectedElement as ImageElement,
          onElementChanged: _handleElementChanged,
        );
      case 'collection':
        return CollectionElementPropertyPanel(
          element: selectedElement as CollectionElement,
          onElementChanged: _handleElementChanged,
        );
      case 'group':
        return GroupElementPropertyPanel(
          element: selectedElement as GroupElement,
          onElementChanged: _handleElementChanged,
          onUngroup: onUngroup,
        );
      default:
        return const Center(child: Text('不支持的元素类型'));
    }
  }

  // 构建多选状态下的组操作面板
  Widget _buildGroupSelectionPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 多选状态标题
          Row(
            children: [
              const Text(
                '多选元素',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.group_work),
                tooltip: '组合所选元素',
                onPressed: () {
                  // 组合操作由父组件处理
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 提示信息
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '您已选择多个元素',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('可以对多个元素进行组合操作，组合后可以作为一个整体进行变换。'),
                SizedBox(height: 8),
                Text('也可以对多个元素进行批量删除、移动等操作。'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 基本操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOperationButton(
                icon: Icons.group_work,
                label: '组合',
                onPressed: () {
                  // 使用onUngroup回调，实际上是父组件处理
                },
              ),
              _buildOperationButton(
                icon: Icons.delete,
                label: '删除',
                onPressed: () {
                  // 删除操作由父组件处理
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOperationButton(
                icon: Icons.content_copy,
                label: '复制',
                onPressed: () {
                  // 复制操作由父组件处理
                },
              ),
              _buildOperationButton(
                icon: Icons.highlight_off,
                label: '取消选择',
                onPressed: () {
                  // 取消选择操作由父组件处理
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建操作按钮
  Widget _buildOperationButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(120, 48),
      ),
      onPressed: onPressed,
    );
  }

  // 处理元素变更
  void _handleElementChanged(PracticeElement updatedElement) {
    onElementChanged?.call(updatedElement);
  }
}
