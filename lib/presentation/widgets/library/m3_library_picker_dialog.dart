import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/library_item.dart';
import '../../../l10n/app_localizations.dart';
import 'm3_library_browsing_panel.dart';

/// 图库选择对话框 - 用于在其他页面中选择图库项目
class M3LibraryPickerDialog extends ConsumerWidget {
  /// 是否可以多选
  final bool enableMultiSelect;

  /// 对话框标题
  final String? title;

  /// 构造函数
  const M3LibraryPickerDialog({
    super.key,
    this.enableMultiSelect = false,
    this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.0),
        child: SizedBox(
          width: 1200,
          height: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16.0),
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    Text(
                      title ?? l10n.imagePropertyPanelSelectFromLibrary,
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: l10n.windowButtonClose,
                    ),
                  ],
                ),
              ),

              // 图库检索面板
              Expanded(
                child: M3LibraryBrowsingPanel(
                  enableFileDrop: true,
                  enableMultiSelect: enableMultiSelect,
                  showConfirmButtons: true,
                  onItemSelected: (LibraryItem item) {
                    Navigator.of(context).pop(item);
                  },
                  onItemsSelected: (List<LibraryItem> items) {
                    Navigator.of(context).pop(items);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示图库选择对话框的静态方法 (单选)
  static Future<LibraryItem?> show(BuildContext context,
      {String? title}) async {
    return await showDialog<LibraryItem>(
      context: context,
      builder: (context) => M3LibraryPickerDialog(
        title: title,
      ),
    );
  }

  /// 显示图库选择对话框的静态方法 (多选)
  static Future<List<LibraryItem>?> showMulti(BuildContext context,
      {String? title}) async {
    return await showDialog<List<LibraryItem>>(
      context: context,
      builder: (context) => M3LibraryPickerDialog(
        enableMultiSelect: true,
        title: title,
      ),
    );
  }
}
