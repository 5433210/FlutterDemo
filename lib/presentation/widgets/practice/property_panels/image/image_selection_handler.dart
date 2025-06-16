import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../application/providers/service_providers.dart';
import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/config/edit_page_logging_config.dart';
import '../../../../providers/library/library_management_provider.dart';
import '../../../library/m3_library_picker_dialog.dart';
import '../../practice_edit_controller.dart';

/// 图像选择处理器混合类
mixin ImageSelectionHandler {
  /// 获取控制器
  PracticeEditController get controller;

  /// 获取元素数据
  Map<String, dynamic> get element;

  /// 获取ref
  WidgetRef get ref;

  /// 导入状态
  bool get isImporting;
  set isImporting(bool value);

  /// 对话框上下文
  BuildContext? get dialogContext;
  set dialogContext(BuildContext? value);

  /// 更新属性
  void updateProperty(String key, dynamic value);

  /// 选择图片事件回调
  void onSelectImage();

  /// 从图库选择图像
  Future<void> selectImageFromLibrary(BuildContext context) async {
    try {
      // 使用新的图库选择对话框
      final selectedItem = await M3LibraryPickerDialog.show(context);

      // 用户从图库选择了图片
      if (selectedItem != null) {
        isImporting = true;

        try {
          final l10n = AppLocalizations.of(context);
          // 更新图层属性
          final content = Map<String, dynamic>.from(
              element['content'] as Map<String, dynamic>);
          content['imageUrl'] =
              'file://${selectedItem.path.replaceAll("\\", "/")}';
          content['sourceId'] = selectedItem.id;
          content['sourceType'] = 'library';
          content['libraryItem'] = selectedItem; // 保存图库项的完整引用

          // 重置变换属性
          content['cropTop'] = 0.0;
          content['cropBottom'] = 0.0;
          content['cropLeft'] = 0.0;
          content['cropRight'] = 0.0;
          content['isFlippedHorizontally'] = false;
          content['isFlippedVertically'] = false;
          content['rotation'] = 0.0;
          content['isTransformApplied'] = true; // 设置为true确保图片立即显示

          content.remove('transformedImageData');
          content.remove('transformedImageUrl');
          content.remove('transformRect');

          // 检查文件是否存在
          final file = File(selectedItem.path);
          if (!await file.exists()) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.fileNotExist(selectedItem.path)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          // 更新元素
          updateProperty('content', content);

          // 通知UI更新
          controller.notifyListeners();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.fileRestored),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // 通知上层图片已选择
          onSelectImage();
        } catch (e) {
          EditPageLogger.propertyPanelError(
            '从图库导入图片失败',
            tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
            error: e,
            data: {
              'selectedItemId': selectedItem.id,
              'selectedItemPath': selectedItem.path,
              'operation': 'import_from_library',
            },
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)
                    .imageImportError(e.toString())),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          isImporting = false;
        }
      }
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '打开图库选择器失败',
        tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
        error: e,
        data: {
          'operation': 'show_library_picker',
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).openGalleryFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 从本地选择图像
  Future<void> selectImageFromLocal(BuildContext context) async {
    // Guard against multiple simultaneous invocations
    if (isImporting) {
      return; // Already importing, do nothing
    }

    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // 弹出提示对话框，说明会自动导入图库
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fromLocal),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.imagePropertyPanelAutoImportNotice,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    if (shouldProceed != true) {
      return; // User cancelled, exit method
    }

    // Set importing state right away to prevent multiple invocations
    isImporting = true;

    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      // 如果没有选择文件直接返回
      if (result == null || result.files.isEmpty) {
        isImporting = false;
        return;
      }

      // Get file path immediately to avoid any race conditions
      final file = result.files.first;
      if (file.path == null) {
        throw Exception('Invalid file path');
      }
      final filePath = file.path!;

      // 检查组件是否仍然挂载
      if (!context.mounted) {
        isImporting = false;
        return;
      }

      // 显示加载指示器
      dialogContext = null; // 确保每次都重置对话框引用
      if (context.mounted) {
        // 使用非阻塞方式显示加载对话框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) {
            dialogContext = ctx;
            return Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(l10n.importing),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }

      // 使用 LibraryImportService 导入文件
      final importService = ref.read(libraryImportServiceProvider);
      final importedItem = await importService.importFile(filePath);

      if (importedItem == null) {
        throw Exception('Failed to import image to library');
      }

      // 刷新图库
      final libraryNotifier = ref.read(libraryManagementProvider.notifier);
      await libraryNotifier.loadData();

      // 更新图片元素
      if (!context.mounted) {
        isImporting = false;
        return;
      }

      final content =
          Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
      content['imageUrl'] = 'file://${importedItem.path.replaceAll("\\", "/")}';
      content['sourceId'] = importedItem.id;
      content['sourceType'] = 'library';
      content['libraryItem'] = importedItem;

      // 重置变换属性
      content['cropTop'] = 0.0;
      content['cropBottom'] = 0.0;
      content['cropLeft'] = 0.0;
      content['cropRight'] = 0.0;
      content['isFlippedHorizontally'] = false;
      content['isFlippedVertically'] = false;
      content['rotation'] = 0.0;
      content['isTransformApplied'] = true; // 设置为true确保图片立即显示
      content.remove('transformedImageData');
      content.remove('transformedImageUrl');
      content.remove('transformRect');

      // Update the property (outside of setState to avoid nested setState calls)
      updateProperty('content', content);

      // 通知UI更新
      controller.notifyListeners();

      // 显示成功提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageImportSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageImportError(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Always ensure we clean up, regardless of success or failure

      // 关闭加载指示器
      if (dialogContext != null) {
        Navigator.of(dialogContext!).pop();
        dialogContext = null;
      }

      // 重置导入状态
      isImporting = false;
    }
  }
}
