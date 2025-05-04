import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/feature_flag_provider.dart';
import '../../../../routes/app_routes.dart';
import '../../../widgets/settings/settings_section.dart';

class DeveloperSettings extends ConsumerWidget {
  const DeveloperSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureFlags = ref.watch(featureFlagsProvider);

    return SettingsSection(
      title: '开发者选项',
      icon: Icons.code,
      children: [
        SwitchListTile(
          title: const Text('使用Material 3界面'),
          subtitle: const Text('启用新的界面设计（实验性）'),
          value: featureFlags.useMaterial3UI,
          onChanged: (value) async {
            await ref
                .read(featureFlagsProvider.notifier)
                .setUseMaterial3UI(value);
            // 显示需要重启应用的提示
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请重启应用以应用新的界面设置')),
              );
            }
          },
        ),
        ListTile(
          title: const Text('字体测试工具'),
          subtitle: const Text('测试不同字体的显示效果'),
          leading: const Icon(Icons.font_download),
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.fontTester);
          },
        ),
      ],
    );
  }
}
