import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// 字帖覆盖确认对话框
/// 当用户尝试保存的标题已存在时，用于确认是否覆盖
class PracticeOverwriteConfirmDialog extends StatelessWidget {
  /// 要覆盖的字帖标题
  final String title;

  const PracticeOverwriteConfirmDialog({
    super.key,
    required this.title,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            Navigator.of(context).pop(true);
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop(false);
          }
        }
      },
      child: AlertDialog(
        title: Text(l10n.overwriteConfirm),
        content: Text(l10n.overwriteMessage(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.overwrite),
          ),
        ],
      ),
    );
  }
}
