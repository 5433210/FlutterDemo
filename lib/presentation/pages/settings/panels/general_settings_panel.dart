import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeneralSettingsPanel extends ConsumerWidget {
  const GeneralSettingsPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('界面设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildThemeSettings(context),
          const Divider(height: 32),
          
          const Text('视图设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildViewSettings(context),
          const Divider(height: 32),
          
          const Text('语言设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildLanguageSettings(context),
          const Divider(height: 32),
          
          const Text('更新设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildUpdateSettings(context),
        ],
      ),
    );
  }

  Widget _buildThemeSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: '主题模式',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'system', child: Text('跟随系统')),
            DropdownMenuItem(value: 'light', child: Text('明亮模式')),
            DropdownMenuItem(value: 'dark', child: Text('暗黑模式')),
          ],
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('界面缩放'),
            Expanded(
              child: Slider(
                value: 1.0,
                min: 0.75,
                max: 1.5,
                divisions: 15,
                label: '100%',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: '默认视图模式',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'grid', child: Text('网格视图')),
            DropdownMenuItem(value: 'list', child: Text('列表视图')),
          ],
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: '缩略图尺寸',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 100, child: Text('小 (100px)')),
            DropdownMenuItem(value: 150, child: Text('中 (150px)')),
            DropdownMenuItem(value: 200, child: Text('大 (200px)')),
          ],
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildLanguageSettings(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: '界面语言',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'system', child: Text('跟随系统')),
        DropdownMenuItem(value: 'zh_CN', child: Text('简体中文')),
        DropdownMenuItem(value: 'en_US', child: Text('English')),
      ],
      onChanged: (value) {},
    );
  }

  Widget _buildUpdateSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('自动检查更新'),
          value: true,
          onChanged: (value) {},
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: '更新提醒方式',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'immediate', child: Text('立即提醒')),
            DropdownMenuItem(value: 'daily', child: Text('每天提醒一次')),
            DropdownMenuItem(value: 'weekly', child: Text('每周提醒一次')),
          ],
          onChanged: (value) {},
        ),
      ],
    );
  }
}
