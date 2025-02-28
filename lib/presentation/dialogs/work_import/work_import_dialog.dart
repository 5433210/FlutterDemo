import 'dart:io';

import 'package:demo/application/services/work/work_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/work.dart';
import '../../../presentation/viewmodels/states/work_import_state.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/work_import_provider.dart';
import 'components/form/work_import_form.dart';
import 'components/preview/work_import_preview.dart';

class ImportResult {
  final bool isSuccess;
  final String? error;

  const ImportResult({
    this.isSuccess = false,
    this.error,
  });

  static ImportResult failure(String error) => ImportResult(error: error);
  static ImportResult success() => const ImportResult(isSuccess: true);
}

class WorkImportDialog extends ConsumerStatefulWidget {
  const WorkImportDialog({super.key});

  @override
  ConsumerState<WorkImportDialog> createState() => _WorkImportDialogState();
}

class WorkImportProvider extends StateNotifier<WorkImportState> {
  final WorkService _workService;

  WorkImportProvider(this._workService)
      : super(const WorkImportState(
          name: '',
          author: '',
          style: null,
          tool: null,
          remark: '',
          images: [],
          selectedImageIndex: -1,
          isLoading: false,
        ));

  Future<ImportResult> importWork() async {
    state = state.copyWith(isLoading: true);

    try {
      if (state.name.isEmpty) {
        return ImportResult.failure('作品名称不能为空');
      }

      if (state.images.isEmpty) {
        return ImportResult.failure('至少需要一张图片');
      }

      final work = Work(
        name: state.name,
        author: state.author,
        style: state.style?.name,
        tool: state.tool?.label,
        creationDate: state.creationDate,
        imageCount: state.images.length,
      );

      await _workService.importWork(state.images, work);

      return ImportResult.success();
    } catch (e, stackTrace) {
      debugPrint('Import failed in provider: $e\n$stackTrace');
      return ImportResult.failure(e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void reset() {
    state = const WorkImportState(
      name: '',
      author: '',
      style: null,
      tool: null,
      remark: '',
      images: [],
      selectedImageIndex: -1,
      isLoading: false,
    );
  }

  // ... existing code ...
}

class _WorkImportDialogState extends ConsumerState<WorkImportDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  // 用于记录已加载文件路径
  final Set<String> _loadedFilePaths = <String>{};
  late final TextEditingController _nameController;
  late final TextEditingController _authorController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(workImportProvider);
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
                        viewModel: ref.read(workImportProvider.notifier),
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
                          viewModel: ref.read(workImportProvider.notifier),
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
    _nameController.dispose();
    _authorController.dispose();
    _loadedFilePaths.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _authorController = TextEditingController();
    _resetDialog();
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

  Widget _buildHintText(ThemeData theme) {
    return Positioned(
      left: AppSizes.l,
      bottom: AppSizes.l + 120, // 调整位置到缩略图条上方
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppSizes.xxs),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              '点击图片可以预览，拖动可以调整顺序',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
            onPressed: _handleExit,
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
    final isDirty = ref.read(workImportProvider).isDirty;
    if (!isDirty) {
      _resetDialog(); // Reset state before exit
      Navigator.of(context).pop(false);
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 防止点击背景关闭
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
      _resetDialog(); // Reset state before exit
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
        // 导入成功后清空状态
        _resetDialog();
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
    } catch (e, stackTrace) {
      debugPrint('Import failed: $e\n$stackTrace');
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

      if (result != null) {
        final newFiles = result.paths
            .whereType<String>()
            .where((path) => !_loadedFilePaths.contains(path)) // 过滤已加载的文件
            .map((path) => File(path))
            .toList();

        if (newFiles.isEmpty) {
          _showWarning(context, '选中的图片已全部添加过');
          return;
        }

        // 记录新添加的文件路径
        _loadedFilePaths.addAll(newFiles.map((file) => file.path));

        await ref.read(workImportProvider.notifier).addImages(newFiles);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(context, '选择图片失败: ${e.toString()}');
    }
  }

  void _resetDialog() {
    // 清空控制器的值
    _nameController.clear();
    _authorController.clear();

    // 重置 provider 状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workImportProvider.notifier).reset();
    });
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    _showFeedback(
      context: context,
      message: message,
      isError: true,
    );
  }

  void _showFeedback({
    required BuildContext context,
    required String message,
    required bool isError,
  }) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  key: ValueKey(isError),
                  color: isError
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.s),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isError
                        ? theme.colorScheme.onError
                        : theme.colorScheme.onSecondaryContainer,
                    height: 1.2,
                  ),
                  maxLines: isError ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: isError
              ? theme.colorScheme.error
              : theme.colorScheme.secondaryContainer,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSizes.m),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.m,
            vertical: AppSizes.s,
          ),
          dismissDirection: DismissDirection.horizontal,
          duration: Duration(seconds: isError ? 4 : 2),
          showCloseIcon: isError,
          closeIconColor: isError ? theme.colorScheme.onError : null,
          animation: const AlwaysStoppedAnimation(1.0),
        ),
      );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    _showFeedback(
      context: context,
      message: message,
      isError: false,
    );
  }

  void _showValidationError() {
    _showErrorSnackBar(context, '请填写所有必填项');
  }

  // 显示警告提示
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
