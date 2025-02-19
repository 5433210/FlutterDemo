import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageSettingsPanel extends ConsumerWidget {
  const StorageSettingsPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoragePathSettings(context),
          const Divider(height: 32),
          _buildStorageManagement(context),
          const Divider(height: 32),
          _buildBackupSettings(context),
        ],
      ),
    );
  }

  Widget _buildStoragePathSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('存储路径设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildPathSelector(
          context,
          label: '默认存储位置',
          value: 'C:/Users/Documents/Demo/Storage',
          onSelectPath: () async {
            // TODO: 实现路径选择
          },
        ),
        const SizedBox(height: 16),
        _buildPathSelector(
          context,
          label: '临时文件位置',
          value: 'C:/Users/AppData/Local/Demo/Temp',
          onSelectPath: () async {
            // TODO: 实现路径选择
          },
        ),
        const SizedBox(height: 16),
        _buildPathSelector(
          context,
          label: '导出文件默认位置',
          value: 'C:/Users/Documents/Demo/Exports',
          onSelectPath: () async {
            // TODO: 实现路径选择
          },
        ),
      ],
    );
  }

  Widget _buildStorageManagement(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('存储管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        // 存储空间使用统计
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('存储空间使用统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildStorageUsageRow('作品文件', '1.2 GB'),
                _buildStorageUsageRow('临时文件', '156 MB'),
                _buildStorageUsageRow('缓存文件', '328 MB'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: 实现清理临时文件
                      },
                      child: const Text('清理临时文件'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        // TODO: 实现清理缓存
                      },
                      child: const Text('清理缓存'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: 实现一键清理
                      },
                      child: const Text('一键清理'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 自动清理设置
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('自动清理设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '定期清理临时文件',
                    border: OutlineInputBorder(),
                  ),
                  value: 'week',
                  items: const [
                    DropdownMenuItem(value: 'week', child: Text('每周')),
                    DropdownMenuItem(value: 'month', child: Text('每月')),
                    DropdownMenuItem(value: 'quarter', child: Text('每季度')),
                    DropdownMenuItem(value: 'never', child: Text('从不')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: '缓存文件大小限制',
                    border: OutlineInputBorder(),
                  ),
                  value: 1024,
                  items: const [
                    DropdownMenuItem(value: 1024, child: Text('1 GB')),
                    DropdownMenuItem(value: 5120, child: Text('5 GB')),
                    DropdownMenuItem(value: 10240, child: Text('10 GB')),
                    DropdownMenuItem(value: -1, child: Text('不限制')),
                  ],
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('备份设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('启用自动备份'),
                  value: true,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '备份周期',
                    border: OutlineInputBorder(),
                  ),
                  value: 'daily',
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('每天')),
                    DropdownMenuItem(value: 'weekly', child: Text('每周')),
                    DropdownMenuItem(value: 'monthly', child: Text('每月')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: '保留备份数量',
                    border: OutlineInputBorder(),
                  ),
                  value: 5,
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('保留3个')),
                    DropdownMenuItem(value: 5, child: Text('保留5个')),
                    DropdownMenuItem(value: 10, child: Text('保留10个')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                _buildPathSelector(
                  context,
                  label: '本地备份路径',
                  value: 'C:/Users/Documents/Demo/Backups',
                  onSelectPath: () async {
                    // TODO: 实现路径选择
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('启用云端备份'),
                  subtitle: const Text('需要登录账号'),
                  value: false,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPathSelector(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onSelectPath,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSelectPath,
              child: const Text('选择'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStorageUsageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }
}
