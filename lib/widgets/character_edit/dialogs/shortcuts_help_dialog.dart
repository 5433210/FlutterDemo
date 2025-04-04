import 'package:flutter/material.dart';

import '../keyboard/shortcut_handler.dart';

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
    return AlertDialog(
      title: const Text('快捷键帮助'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutSection('基本操作', {
              EditorShortcuts.save: '保存',
              EditorShortcuts.openInput: '打开输入框',
            }),
            const Divider(),
            _buildShortcutSection('编辑操作', {
              EditorShortcuts.undo: '撤销',
              EditorShortcuts.redo: '重做',
            }),
            const Divider(),
            _buildShortcutSection('显示选项', {
              EditorShortcuts.toggleInvert: '反转模式',
              EditorShortcuts.toggleImageInvert: '图像反转',
              EditorShortcuts.toggleContour: '轮廓显示',
              EditorShortcuts.togglePanMode: '平移模式',
            }),
            const Divider(),
            _buildBrushSizePresets(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildBrushSizePresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '笔刷大小预设',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(
          EditorShortcuts.brushSizePresets.length,
          (index) {
            final shortcut = EditorShortcuts.brushSizePresets[index];
            final size = EditorShortcuts.brushSizes[index];
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Text(
                    EditorShortcuts.getShortcutLabel(shortcut),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('笔刷大小 ${size.toInt()}'),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShortcutSection(
    String title,
    Map<SingleActivator, String> shortcuts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...shortcuts.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              children: [
                Text(
                  EditorShortcuts.getShortcutLabel(entry.key),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Text(entry.value),
              ],
            ),
          );
        }),
      ],
    );
  }
}
