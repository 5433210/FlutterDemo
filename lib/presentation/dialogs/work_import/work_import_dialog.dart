import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_sizes.dart';
import '../../providers/work_import_provider.dart';
import '../../providers/works_providers.dart';
import '../../viewmodels/states/work_import_state.dart';
import 'components/form/work_import_form.dart';
import 'components/preview/work_import_preview.dart';

class WorkImportDialog extends ConsumerStatefulWidget {
  const WorkImportDialog({super.key});

  @override
  ConsumerState<WorkImportDialog> createState() => _WorkImportDialogState();
}

class _WorkImportDialogState extends ConsumerState<WorkImportDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(workImportProvider);
    final viewModel = ref.read(workImportProvider.notifier);
    final isDirty = state.images.isNotEmpty;

    return WillPopScope(
      onWillPop: _handleExit,
      child: Dialog(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1120,
            maxHeight: 720,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题栏
              _buildTitleBar(theme),

              // 内容区域
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 左侧预览区 (70%)
                    Expanded(
                      flex: 7,
                      child: WorkImportPreview(
                        state: state,
                        viewModel: viewModel,
                        isProcessing: _isLoading,
                        onAddImages: () => _pickImages(context),
                      ),
                    ),

                    // 分割线
                    VerticalDivider(
                      thickness: 1,
                      width: 1,
                      color: theme.dividerColor,
                    ),

                    // 右侧表单区 (30%)
                    Expanded(
                      flex: 3,
                      child: Form(
                        key: _formKey,
                        child: WorkImportForm(
                          state: state,
                          viewModel: viewModel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 底部按钮区
              _buildBottomBar(theme, state, isDirty),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 退出时重置状态
    Future.microtask(() {
      if (mounted) {
        ref.read(workImportProvider.notifier).reset();
      }
    });
    super.dispose();
  }

  Widget _buildBottomBar(ThemeData theme, WorkImportState state, bool isDirty) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.l,
        vertical: AppSizes.m,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : _handleExit,
            style: TextButton.styleFrom(
              minimumSize: const Size(88, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.l),
            ),
            child: const Text('取消'),
          ),
          const SizedBox(width: AppSizes.m),
          FilledButton(
            onPressed: _isLoading || !isDirty ? null : _handleSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.l),
            ),
            child: _isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('导入'),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(ThemeData theme) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.l),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            '导入作品',
            style: theme.textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _handleExit(),
            icon: const Icon(Icons.close),
            tooltip: '关闭',
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleExit() async {
    final viewModel = ref.read(workImportProvider.notifier);
    final isDirty = ref.read(workImportProvider).isDirty;

    if (!isDirty) {
      viewModel.reset();
      if (mounted) {
        Navigator.of(context).pop(false);
      }
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: AppSizes.s),
            const Text('确认退出'),
          ],
        ),
        content: const Text('当前有未保存的更改，退出后更改将会丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '继续编辑',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('放弃更改'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      viewModel.reset();
      Navigator.of(context).pop(false);
    }
    return confirmed ?? false;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写必填字段')),
      );
      return;
    }

    if (ref.read(workImportProvider).images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一张图片')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      _formKey.currentState!.save();
      final result = await ref.read(workImportProvider.notifier).importWork();

      if (!mounted) return;

      if (result) {
        // 触发主列表刷新
        ref.read(worksNeedsRefreshProvider.notifier).state =
            RefreshInfo.importCompleted();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入成功')),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败：${ref.read(workImportProvider).error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Import failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导入失败：${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImages(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
        withData: false,
        lockParentWindow: true,
      );

      if (!mounted) return;

      if (result != null && result.paths.isNotEmpty) {
        final files =
            result.paths.whereType<String>().map((path) => File(path)).toList();

        if (files.isEmpty) {
          _showWarning(context, '未选择任何图片');
          return;
        }

        await ref.read(workImportProvider.notifier).addImages(files);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  void _showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
