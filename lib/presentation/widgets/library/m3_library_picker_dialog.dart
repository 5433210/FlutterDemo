import 'package:charasgem/infrastructure/logging/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/library_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/library/library_management_provider.dart';
import 'm3_library_browsing_panel.dart';

/// 图库选择对话框静态方法类
class M3LibraryPickerDialog {
  /// 显示图库选择对话框的静态方法 (单选)
  static Future<LibraryItem?> show(BuildContext context,
      {String? title}) async {
    // 在显示对话框前清除之前的选择状态
    _clearPreviousSelections(context);

    // 使用 showDialog 而不是 showRootDialog 确保在当前对话框上下文中打开
    final result = await showDialog<_PickerResult>(
      context: context,
      useRootNavigator: false, // 重要：使用false确保只使用当前对话框的Navigator，不会关闭父对话框
      barrierDismissible: true, // 允许点击背景关闭对话框
      builder: (dialogContext) {
        return _LibraryPickerDialogView(
          enableMultiSelect: false,
          title: title,
        );
      },
    );

    if (result == null || !result.confirmed || result.items.isEmpty) {
      return null;
    }

    return result.items.first;
  }

  /// 显示图库选择对话框的静态方法 (多选)
  static Future<List<LibraryItem>?> showMulti(BuildContext context,
      {String? title}) async {
    // 在显示对话框前清除之前的选择状态
    _clearPreviousSelections(context);

    // 使用 showDialog 而不是 showRootDialog 确保在当前对话框上下文中打开
    AppLogger.debug('【M3LibraryPickerDialog】准备显示多选对话框: $title');

    final result = await showDialog<_PickerResult>(
      context: context,
      useRootNavigator: false, // 重要：使用false确保只使用当前对话框的Navigator，不会关闭父对话框
      barrierDismissible: true, // 允许点击背景关闭对话框
      barrierColor:
          Theme.of(context).colorScheme.scrim.withAlpha(128), // 使用半透明背景
      builder: (dialogContext) {
        AppLogger.debug(
            '【M3LibraryPickerDialog】构建多选对话框 - 是否相同上下文: ${identical(context, dialogContext)}');
        return _LibraryPickerDialogView(
          enableMultiSelect: true,
          title: title,
        );
      },
    );

    AppLogger.debug(
        '【M3LibraryPickerDialog】多选对话框关闭: ${result?.confirmed}, 选择项: ${result?.items.length ?? 0}');

    if (result == null || !result.confirmed || result.items.isEmpty) {
      return null;
    }

    return result.items;
  }

  /// 清除之前的选择状态
  static void _clearPreviousSelections(BuildContext context) {
    try {
      // 使用 ProviderScope.containerOf 获取 ProviderContainer
      final container = ProviderScope.containerOf(context);
      final notifier = container.read(libraryManagementProvider.notifier);
      final currentState = container.read(libraryManagementProvider);

      // 清空选择状态
      notifier.clearSelection();

      // 如果处于批量模式，退出批量模式
      if (currentState.isBatchMode) {
        notifier.toggleBatchMode();
      }

      // 重置搜索条件
      notifier.updateSearchQuery('');

      AppLogger.debug('【M3LibraryPickerDialog】已清除之前的选择状态');
    } catch (e) {
      AppLogger.warning('清除之前的选择状态失败', error: e);
    }
  }
}

/// 图库选择对话框视图实现
class _LibraryPickerDialogView extends ConsumerStatefulWidget {
  final bool enableMultiSelect;
  final String? title;

  const _LibraryPickerDialogView({
    Key? key,
    required this.enableMultiSelect,
    this.title,
  }) : super(key: key);

  @override
  ConsumerState<_LibraryPickerDialogView> createState() =>
      _LibraryPickerDialogViewState();
}

class _LibraryPickerDialogViewState
    extends ConsumerState<_LibraryPickerDialogView> {
  @override
  Widget build(BuildContext context) {
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
                      widget.title ?? l10n.fromGallery,
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        // 直接使用 Navigator.pop 而不是 Navigator.of
                        AppLogger.debug('【M3LibraryPickerDialog】关闭按钮被点击');
                        Navigator.pop(context, _PickerResult(items: []));
                      },
                      tooltip: l10n.close,
                    ),
                  ],
                ),
              ),

              // 图库检索面板
              Expanded(
                child: M3LibraryBrowsingPanel(
                  enableFileDrop: true,
                  enableMultiSelect: widget.enableMultiSelect,
                  showConfirmButtons: true,
                  onItemSelected: (item) {
                    if (!widget.enableMultiSelect) {
                      // 使用 rootNavigator: false 来确保只关闭当前的图库选择对话框
                      // 使用 Navigator.pop(context) 而不是 Navigator.of(context).pop()
                      // 避免可能的导航器混淆
                      if (mounted) {
                        Navigator.pop(
                            context,
                            _PickerResult(
                              items: [item],
                              confirmed: true,
                            ));
                      }
                    }
                  },
                  onItemsSelected: (items) {
                    if (items.isNotEmpty && mounted) {
                      // 使用 rootNavigator: false 来确保只关闭当前的图库选择对话框
                      // 使用 Navigator.pop(context) 而不是 Navigator.of(context).pop()
                      // 避免可能的导航器混淆
                      Navigator.pop(
                          context,
                          _PickerResult(
                            items: items,
                            confirmed: true,
                          ));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 组件初始化时不直接清空选择，而是使用Future延迟执行
    // 这样可以避免在构建阶段修改状态
    Future.microtask(() {
      if (mounted) {
        final notifier = ref.read(libraryManagementProvider.notifier);
        // 完全重置选择状态
        notifier.clearSelection();
        // 如果处于批量模式，退出批量模式
        if (ref.read(libraryManagementProvider).isBatchMode) {
          notifier.toggleBatchMode();
        }
        // 重置搜索条件
        notifier.updateSearchQuery('');
        AppLogger.debug(
            '【M3LibraryPickerDialogView】initState.microtask - 已重置所有选择状态、批量模式和搜索条件');
      }
    });
  }
}

/// 选择结果
class _PickerResult {
  final List<LibraryItem> items;
  final bool confirmed;

  _PickerResult({
    required this.items,
    this.confirmed = false,
  });
}
