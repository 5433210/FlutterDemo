import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/page_layout.dart';
import 'components/appearance_settings.dart';
import 'components/storage_settings.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageLayout(
      toolbar: const Text('设置'),
      body: _buildSettingsContent(context, ref),
    );
  }

  Widget _buildSettingsContent(BuildContext context, WidgetRef ref) {
    return ListView(
      children: const [
        AppearanceSettings(),
        Divider(),
        StorageSettings(),
      ],
    );
  }
}
