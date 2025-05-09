import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Material 3 风格的导航抽屉
class M3NavigationDrawer extends StatelessWidget {
  const M3NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return NavigationDrawer(
      children: [
        // 字符管理
        NavigationDrawerDestination(
          icon: const Icon(Icons.text_fields),
          label: Text(l10n.characters),
        ),
        // 作品管理
        NavigationDrawerDestination(
          icon: const Icon(Icons.collections),
          label: Text(l10n.works),
        ),
        // 图库管理
        NavigationDrawerDestination(
          icon: const Icon(Icons.photo_library),
          label: Text(l10n.libraryManagement),
        ),
        // 字帖管理
        NavigationDrawerDestination(
          icon: const Icon(Icons.book),
          label: Text(l10n.practices),
        ),
        // 设置
        NavigationDrawerDestination(
          icon: const Icon(Icons.settings),
          label: Text(l10n.settings),
        ),
      ],
    );
  }
}
