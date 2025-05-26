import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/expansion_tile_provider.dart';
import '../common/persistent_expansion_tile.dart';

/// 演示 ExpansionTile 持久化功能的测试页面
class ExpansionTileMemoryDemo extends ConsumerWidget {
  const ExpansionTileMemoryDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpansionTile 记忆功能演示'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(expansionTileProvider.notifier).reload();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('状态已重新加载')),
              );
            },
            tooltip: '重新加载状态',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              ref.read(expansionTileProvider.notifier).clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('所有状态已清除')),
              );
            },
            tooltip: '清除所有状态',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明文本
            Card(
              color: colorScheme.primaryContainer.withAlpha(76),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '功能说明',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 展开或折叠下方的面板\n'
                      '• 重启应用后，面板状态会自动恢复\n'
                      '• 点击右上角按钮可重新加载或清除状态',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 演示面板 1 - 默认展开
            PersistentPanelCard(
              panelId: 'demo_panel_1',
              title: '演示面板 1 (默认展开)',
              defaultExpanded: true,
              children: [
                Text(
                  '这是第一个演示面板的内容。',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '示例内容区域',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 演示面板 2 - 默认折叠
            PersistentPanelCard(
              panelId: 'demo_panel_2',
              title: '演示面板 2 (默认折叠)',
              defaultExpanded: false,
              children: [
                Text(
                  '这是第二个演示面板的内容。',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: const Text('标签 1'),
                      backgroundColor: colorScheme.secondaryContainer,
                    ),
                    Chip(
                      label: const Text('标签 2'),
                      backgroundColor: colorScheme.secondaryContainer,
                    ),
                    Chip(
                      label: const Text('标签 3'),
                      backgroundColor: colorScheme.secondaryContainer,
                    ),
                  ],
                ),
              ],
            ),

            // 演示面板 3 - 包含更多内容
            PersistentPanelCard(
              panelId: 'demo_panel_3',
              title: '演示面板 3 (复杂内容)',
              defaultExpanded: true,
              children: [
                Text(
                  '设置选项',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('启用功能 A'),
                  subtitle: const Text('这是一个示例开关'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('启用功能 B'),
                  subtitle: const Text('这是另一个示例开关'),
                  value: false,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                Text(
                  '滑块控制',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: 0.7,
                  onChanged: (value) {},
                  label: '70%',
                ),
              ],
            ),

            // 状态显示面板
            Card(
              margin: const EdgeInsets.only(top: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前状态',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final state = ref.watch(expansionTileProvider);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: state.tileStates.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '${entry.key}: ${entry.value ? "展开" : "折叠"}',
                                style: textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
