import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/widgets.dart';
import '../../providers/work_import_provider.dart';
import '../../theme/app_sizes.dart';
import 'components/dialog_header.dart';
import 'components/dialog_footer.dart';
import 'components/preview/preview_toolbar.dart';
import 'components/preview/thumbnail_strip.dart';
import 'components/preview/work_import_preview.dart';
import 'components/form/work_import_form.dart';

class WorkImportDialog extends ConsumerStatefulWidget {
  const WorkImportDialog({super.key});

  @override
  ConsumerState<WorkImportDialog> createState() => _WorkImportDialogState();
}

class _WorkImportDialogState extends ConsumerState<WorkImportDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 确保在构建完成后重置状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workImportProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    //_clearState();
    super.dispose();
  }

  void _clearState() {
    // 使用 addPostFrameCallback 确保在构建完成后重置状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workImportProvider.notifier).reset();
    });    
  }

  Future<void> _pickImages(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
      );

      if (result != null && mounted) {
        final files = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
        
        if (files.isNotEmpty) {
          ref.read(workImportProvider.notifier).addImages(files);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, '选择图片失败: ${e.toString()}');
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(workImportProvider.notifier).importWork();
      if (mounted && success) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(workImportProvider);

    return WillPopScope(
      onWillPop: () async {
            final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认退出'),
              content: const Text('当前有未保存的更改，确定要退出吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
          return confirmed ?? false;

        return true;
      },
      child: Dialog(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.dividerColor, width: 1),
        ),
        child: SizedBox(
          width: 1280,
          height: 768,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DialogHeader(
                title: '导入作品',
                onClose: () => Navigator.of(context).pop(),
              ),

              // Content Area - 双栏布局 (70:30)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Preview Area (70%)
                    Expanded(
                      flex: 7,
                      child: WorkImportPreview(
                        state: state,
                        viewModel: ref.read(workImportProvider.notifier),
                        //onAddImages: () => _pickImages(context),
                      ),
                    ),

                    // Divider
                    VerticalDivider(width: 1, color: theme.dividerColor),

                    // Right Form Area (30%)
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

              // Footer
              DialogFooter(
                error: state.error,
                isLoading: _isLoading,
                onCancel: () async {                  
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('确认退出'),
                        content: const Text('当前有未保存的更改，确定要退出吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                onSubmit: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}