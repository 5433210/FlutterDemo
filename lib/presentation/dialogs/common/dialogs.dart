import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../utils/dialog_navigation_helper.dart';

Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? cancelText,
  String? confirmText,
}) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => DialogNavigationHelper.safePop<bool>(
            context,
            result: false,
            dialogName: 'ConfirmDialog',
          ),
          child: Text(cancelText ?? l10n.cancel),
        ),
        FilledButton(
          onPressed: () => DialogNavigationHelper.safePop<bool>(
            context,
            result: true,
            dialogName: 'ConfirmDialog',
          ),
          child: Text(confirmText ?? l10n.confirm),
        ),
      ],
    ),
  );
}

Future<void> showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? buttonText,
}) async {
  final l10n = AppLocalizations.of(context);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => DialogNavigationHelper.safeCancel(
            context,
            dialogName: 'ErrorDialog',
          ),
          child: Text(buttonText ?? l10n.ok),
        ),
      ],
    ),
  );
}
