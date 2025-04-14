import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_collection_provider.dart';

class CharacterNavigationBar extends ConsumerWidget {
  final String workId;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  const CharacterNavigationBar({
    Key? key,
    required this.workId,
    required this.onBack,
    this.onHelp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collectionState = ref.watch(characterCollectionProvider);

    // 计算状态信息文本
    String statusText = '';
    if (collectionState.processing) {
      statusText = '处理中...';
    } else if (collectionState.error != null) {
      statusText = '错误：${collectionState.error}';
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回',
            onPressed: () {
              onBack();
            },
          ),

          const SizedBox(width: 16),

          // 标题
          Text(
            '集字功能',
            style: theme.textTheme.titleLarge,
          ),

          // 状态文本（条件显示）
          if (statusText.isNotEmpty) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: collectionState.error != null
                    ? theme.colorScheme.error.withOpacity(0.1)
                    : theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: collectionState.error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ],

          const Spacer(),

          // 帮助按钮
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '帮助',
            onPressed: onHelp ?? () => _showHelpDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  item,
                  style: const TextStyle(height: 1.5),
                ),
              )),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('集字功能使用帮助'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '集字功能使用指南',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '集字功能让您能够从图片中提取、编辑和管理文字。以下是详细的操作指南：',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildHelpSection(
                '1. 选择与浏览',
                [
                  '• 框选工具（S键）：创建新字符区域',
                  '• 多选工具（M键）：选择多个已有区域',
                  '• 拖拽工具（V键）：移动和缩放图片',
                  '• 单击区域选中，再次点击可取消选择',
                  '• 按住Shift键可进行多选操作',
                  '• 使用鼠标滚轮或触控板进行缩放',
                  '• 按住空格键并拖动可平移图片',
                ],
              ),
              _buildHelpSection(
                '2. 区域调整',
                [
                  '• 选中区域后可拖动边框调整大小',
                  '• 拖动角部控制点可等比例缩放',
                  '• 拖动边部控制点可单向调整尺寸',
                  '• 拖动区域内部可移动整个区域',
                  '• 方向键可微调位置（Shift+方向键调整幅度更大）',
                  '• ESC键可取消当前操作',
                ],
              ),
              _buildHelpSection(
                '3. 擦除功能',
                [
                  '• E键激活擦除工具',
                  '• 拖动鼠标擦除字符内不需要的部分',
                  '• 擦除后字符区域会标记为已修改',
                  '• 使用Ctrl+Z撤销擦除操作',
                  '• 使用Ctrl+Shift+Z重做擦除操作',
                ],
              ),
              _buildHelpSection(
                '4. 数据保存',
                [
                  '• 修改后的字符会自动标记为未保存状态',
                  '• 按Ctrl+S手动保存所有修改',
                  '• 编辑区域顶部会显示当前工作状态',
                  '• 离开页面前会提示保存未保存的修改',
                ],
              ),
              _buildHelpSection(
                '5. 快捷键一览',
                [
                  '• V：切换到拖拽工具（默认）',
                  '• S：切换到框选工具',
                  '• M：切换到多选工具',
                  '• E：切换到擦除工具',
                  '• Delete：删除选中区域',
                  '• Ctrl+Z：撤销操作',
                  '• Ctrl+Y/Ctrl+Shift+Z：重做操作',
                  '• 方向键：微调选区位置',
                  '• Shift+方向键：大幅度调整位置',
                  '• Space+拖动：平移图片',
                  '• Ctrl+S：保存修改',
                  '• Esc：取消当前操作',
                ],
              ),
              _buildHelpSection(
                '注意事项',
                [
                  '• 选中区域会显示蓝色边框和控制点',
                  '• 未保存的修改会在状态栏显示',
                  '• 多选模式下可以进行批量删除',
                  '• 图片处理可能需要一定时间，请耐心等待',
                  '• 操作结束后建议及时保存更改',
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 实现导出帮助文档功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('帮助文档导出功能即将推出'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('导出帮助文档'),
          ),
        ],
      ),
    );
  }

  void _showUnsavedChangesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('您有未保存的更改，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onBack();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('放弃更改'),
          ),
        ],
      ),
    );
  }
}
