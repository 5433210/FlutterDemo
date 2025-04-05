import 'package:flutter/material.dart';

Future<void> showShortcutsHelp(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const ShortcutsHelpDialog(),
  );
}

class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            const Row(
              children: [
                Icon(Icons.keyboard, size: 24),
                SizedBox(width: 8),
                Text(
                  '快捷键帮助',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 工具切换
            _buildSection('工具切换', [
              const _ShortcutItem(
                shortcut: 'V',
                description: '拖拽工具：移动和缩放图片',
                icon: Icons.pan_tool,
              ),
              const _ShortcutItem(
                shortcut: 'R',
                description: '框选工具：创建和调整字符框',
                icon: Icons.crop_square,
              ),
              const _ShortcutItem(
                shortcut: 'M',
                description: '多选工具：选择多个字符框',
                icon: Icons.select_all,
              ),
            ]),

            const Divider(height: 32),

            // 选区操作
            _buildSection('选区操作', [
              const _ShortcutItem(
                shortcut: '↑ ↓ ← →',
                description: '微调选区位置',
                icon: Icons.move_down,
              ),
              const _ShortcutItem(
                shortcut: 'Shift + 方向键',
                description: '大幅调整选区位置',
                icon: Icons.expand,
              ),
              const _ShortcutItem(
                shortcut: 'Enter',
                description: '确认选区调整',
                icon: Icons.check_circle_outline,
              ),
              const _ShortcutItem(
                shortcut: 'Esc',
                description: '取消选区调整',
                icon: Icons.cancel_outlined,
              ),
              const _ShortcutItem(
                shortcut: 'Delete / Backspace',
                description: '删除选中的字符框',
                icon: Icons.delete_outline,
              ),
            ]),

            const Divider(height: 32),

            // 其他操作
            _buildSection('其他操作', [
              const _ShortcutItem(
                shortcut: 'Alt + D',
                description: '切换调试模式',
                icon: Icons.bug_report_outlined,
              ),
              const _ShortcutItem(
                shortcut: '鼠标滚轮',
                description: '缩放图片',
                icon: Icons.zoom_in,
              ),
            ]),

            const SizedBox(height: 24),

            // 确定按钮
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<_ShortcutItem> items) {
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
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  final String shortcut;
  final String description;
  final IconData icon;

  const _ShortcutItem({
    required this.shortcut,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
