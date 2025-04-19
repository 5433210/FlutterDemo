import 'package:flutter/material.dart';

/// 内容工具面板
class ContentToolsPanel extends StatelessWidget {
  final String currentTool;
  final Function(String) onToolSelected;
  final VoidCallback onAddTextElement;
  final Function(String) onAddCollectionElement;
  final Function(String) onAddImageElement;

  const ContentToolsPanel({
    Key? key,
    required this.currentTool,
    required this.onToolSelected,
    required this.onAddTextElement,
    required this.onAddCollectionElement,
    required this.onAddImageElement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '内容工具',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          _buildToolButtons(context),
        ],
      ),
    );
  }

  /// 构建工具按钮
  Widget _buildToolButtons(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildToolButton(
          context: context,
          icon: Icons.pan_tool,
          label: '选择',
          toolId: 'select',
          onPressed: () => onToolSelected('select'),
        ),
        _buildToolButton(
          context: context,
          icon: Icons.text_fields,
          label: '文本',
          toolId: 'text',
          onPressed: onAddTextElement,
        ),
        _buildToolButton(
          context: context,
          icon: Icons.grid_view,
          label: '集字',
          toolId: 'collection',
          onPressed: () => _showCollectionDialog(context),
        ),
        _buildToolButton(
          context: context,
          icon: Icons.image,
          label: '图片',
          toolId: 'image',
          onPressed: () => _showImageUrlDialog(context),
        ),
      ],
    );
  }

  /// 构建工具按钮
  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String toolId,
    required VoidCallback onPressed,
  }) {
    final isSelected = currentTool == toolId;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: IconButton(
            icon: Icon(icon),
            color: isSelected ? Theme.of(context).primaryColor : null,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Theme.of(context).primaryColor : null,
          ),
        ),
      ],
    );
  }

  /// 显示集字对话框
  void _showCollectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        
        return AlertDialog(
          title: const Text('添加集字内容'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: '请输入汉字',
              hintText: '例如：永字八法',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(context).pop();
                  onAddCollectionElement(text);
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  /// 显示图片URL对话框
  void _showImageUrlDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        
        return AlertDialog(
          title: const Text('添加图片'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: '请输入图片URL',
              hintText: 'https://example.com/image.jpg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final url = textController.text.trim();
                if (url.isNotEmpty) {
                  Navigator.of(context).pop();
                  onAddImageElement(url);
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }
}
