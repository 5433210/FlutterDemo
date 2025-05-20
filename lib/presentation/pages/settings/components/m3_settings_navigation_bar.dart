import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/m3_page_navigation_bar.dart';

class M3SettingsNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onSave;
  final bool hasChanges;
  final VoidCallback? onBackPressed;

  const M3SettingsNavigationBar({
    super.key,
    required this.onSave,
    required this.hasChanges,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return M3PageNavigationBar(
      title: l10n.settings,
      onBackPressed: onBackPressed,
      actions: [
        if (hasChanges)
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: Text(l10n.save),
          ),
      ],
    );
  }
}
