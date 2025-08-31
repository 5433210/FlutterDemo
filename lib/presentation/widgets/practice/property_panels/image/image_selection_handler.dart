import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../../../application/providers/service_providers.dart';
import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/config/edit_page_logging_config.dart';
import '../../../../../utils/image_path_converter.dart';
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
  void updateProperty(String key, dynamic value,
      {bool createUndoOperation = true});

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

          // 检查文件是否存在
          // 构建正确的图像URL，处理可能已经包含file://前缀的情况
          String tempImageUrl;
          if (selectedItem.path.startsWith('file://')) {
            // 如果已经是file://格式，直接使用
            tempImageUrl = selectedItem.path;
          } else {
            // 如果是普通路径，添加file://前缀
            tempImageUrl = 'file:///${selectedItem.path.replaceAll("\\", "/")}';
          }
          
          final absolutePath = await ImagePathConverter.toAbsolutePath(
              ImagePathConverter.toRelativePath(tempImageUrl));
          
          // 处理 absolutePath：如果包含 file:// 前缀，则去除前缀
          String imageFilePath = absolutePath;
          if (imageFilePath.startsWith('file://')) {
            // 去除 file:// 前缀，转换为标准文件路径
            imageFilePath = imageFilePath.startsWith('file:///')
                ? imageFilePath.substring(8)  // file:///C:/... -> C:/...
                : imageFilePath.substring(7); // file://path -> path
          }
          
          final imageFile = File(imageFilePath);

          if (!await imageFile.exists()) {
            // 记录详细的文件不存在错误信息
            EditPageLogger.propertyPanelError(
              '从图库选择的图像文件不存在',
              tag: EditPageLoggingConfig.tagImagePanel,
              error: 'File not found: Image file does not exist at computed path',
              data: {
                'operation': 'selectImageFromLibrary_file_validation',
                'selectedItemId': selectedItem.id,
                'selectedItemFileName': selectedItem.fileName,
                'selectedItemPath': selectedItem.path,
                'tempImageUrl': tempImageUrl,
                'computedAbsolutePath': absolutePath,
                'pathExists': await Directory(File(absolutePath).parent.path).exists(),
                'parentDirectory': File(absolutePath).parent.path,
                'possibleCauses': [
                  'File was moved or deleted after library indexing',
                  'Path conversion error between relative and absolute paths',
                  'File permissions issue',
                  'Library database out of sync with filesystem',
                  'Platform-specific path separator issues'
                ],
                'debugInfo': {
                  'originalPath': selectedItem.path,
                  'platformSeparator': Platform.pathSeparator,
                  'currentDirectory': Directory.current.path,
                }
              },
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('图像文件不存在，请重新选择'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            return;
          }

          // 更新图层属性
          final content = Map<String, dynamic>.from(
              element['content'] as Map<String, dynamic>);

          // 使用相对路径存储图像URL
          content['imageUrl'] = ImagePathConverter.toRelativePath(tempImageUrl);
          content['sourceId'] = selectedItem.id;
          content['sourceType'] = 'library';
          content['libraryItem'] = selectedItem; // 保存图库项的完整引用

          // 重置变换属性和裁剪区域
          content['cropTop'] = 0.0;
          content['cropBottom'] = 0.0;
          content['cropLeft'] = 0.0;
          content['cropRight'] = 0.0;
          // 重置新的坐标格式裁剪区域
          content['cropX'] = 0.0;
          content['cropY'] = 0.0;
          content.remove('cropWidth'); // 移除裁剪宽高，让系统根据新图片尺寸重新计算
          content.remove('cropHeight');

          // 清除所有裁剪相关的缓存和变换数据
          content.remove('cropRect');
          content.remove('cropParameters');
          content.remove('lastCropSettings');
          content['isFlippedHorizontally'] = false;
          content['isFlippedVertically'] = false;
          content['rotation'] = 0.0;
          content['isTransformApplied'] = false; // 新选择的图像无需变换

          // 清除之前的图片尺寸信息，让系统重新检测
          content.remove('originalWidth');
          content.remove('originalHeight');
          content.remove('renderWidth');
          content.remove('renderHeight');

          // 立即加载新图像尺寸，避免界面显示错误的裁剪区域
          try {
            // 处理文件路径：如果包含 file:// 前缀，则去除前缀
            String filePath = selectedItem.path;
            if (filePath.startsWith('file://')) {
              // 去除 file:// 前缀，转换为标准文件路径
              filePath = filePath.startsWith('file:///')
                  ? filePath.substring(8)  // file:///C:/... -> C:/...
                  : filePath.substring(7); // file://path -> path
            }
            
            final file = File(filePath);
            if (await file.exists()) {
              final imageBytes = await file.readAsBytes();
              final sourceImage = img.decodeImage(imageBytes);
              if (sourceImage != null) {
                content['originalWidth'] = sourceImage.width.toDouble();
                content['originalHeight'] = sourceImage.height.toDouble();
                // 初始渲染尺寸等于原始尺寸
                content['renderWidth'] = sourceImage.width.toDouble();
                content['renderHeight'] = sourceImage.height.toDouble();
              }
            }
          } catch (e) {
            // 如果获取尺寸失败，记录但不中断流程，让处理管道自行处理
            EditPageLogger.propertyPanelError(
              '获取新图像尺寸失败',
              tag: EditPageLoggingConfig.tagImagePanel,
              error: e,
              data: {
                'selectedItemId': selectedItem.id,
                'selectedItemPath': selectedItem.path,
              },
            );
          }

          // 清除所有图像变换和处理相关的缓存数据
          content.remove('transformedImageData');
          content.remove('transformedImageUrl');
          content.remove('transformRect');
          content.remove('binarizedImageData');
          content.remove('processedImageData');
          content.remove('cachedProcessedImage');
          content.remove('imageProcessingCache');

          // 重置二值化和处理标记，让图像处理管道重新开始
          content['needsReprocessing'] = true;
          content.remove('lastProcessingSettings');

          // 清除所有UI状态和预览缓存
          content.remove('previewImageData');
          content.remove('displayImageData');
          content.remove('uiCacheData');
          content.remove('lastRenderSize');
          content.remove('lastImageSize');

          // 强制重新初始化图像处理管道
          content['forceReload'] = true;

          // 检查文件是否存在
          // 处理文件路径：如果包含 file:// 前缀，则去除前缀
          String filePath = selectedItem.path;
          if (filePath.startsWith('file://')) {
            // 去除 file:// 前缀，转换为标准文件路径
            filePath = filePath.startsWith('file:///')
                ? filePath.substring(8)  // file:///C:/... -> C:/...
                : filePath.substring(7); // file://path -> path
          }
          
          final localFile = File(filePath);
          if (!await localFile.exists()) {
            // 记录详细的文件不存在错误信息
            EditPageLogger.propertyPanelError(
              '从图库选择的本地文件不存在',
              tag: EditPageLoggingConfig.tagImagePanel,
              error: 'Local file not found: Image file does not exist at processed path',
              data: {
                'operation': 'selectImageFromLibrary_local_file_validation',
                'selectedItemId': selectedItem.id,
                'selectedItemFileName': selectedItem.fileName,
                'selectedItemPath': selectedItem.path,
                'processedFilePath': filePath,
                'fileExists': await localFile.exists(),
                'parentDirExists': await Directory(localFile.parent.path).exists(),
                'parentDirectory': localFile.parent.path,
                'possibleCauses': [
                  'Original file was moved or deleted',
                  'File permissions changed',
                  'Storage device disconnected (external drive)',
                  'Network path no longer accessible',
                  'Library database contains stale references',
                  'URI path processing error'
                ],
                'debugInfo': {
                  'originalHadFilePrefix': selectedItem.path.startsWith('file://'),
                  'isAbsolute': localFile.isAbsolute,
                  'platformSeparator': Platform.pathSeparator,
                  'currentDirectory': Directory.current.path,
                }
              },
            );
            
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
            tag: EditPageLoggingConfig.tagImagePanel,
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
        tag: EditPageLoggingConfig.tagImagePanel,
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

      // 使用相对路径存储图像URL
      final absoluteImageUrl =
          'file://${importedItem.path.replaceAll("\\", "/")}';
      content['imageUrl'] = ImagePathConverter.toRelativePath(absoluteImageUrl);
      content['sourceId'] = importedItem.id;
      content['sourceType'] = 'library';
      content['libraryItem'] = importedItem;

      // 重置变换属性和裁剪区域
      content['cropTop'] = 0.0;
      content['cropBottom'] = 0.0;
      content['cropLeft'] = 0.0;
      content['cropRight'] = 0.0;
      // 重置新的坐标格式裁剪区域
      content['cropX'] = 0.0;
      content['cropY'] = 0.0;
      content.remove('cropWidth'); // 移除裁剪宽高，让系统根据新图片尺寸重新计算
      content.remove('cropHeight');

      // 清除所有裁剪相关的缓存和变换数据
      content.remove('cropRect');
      content.remove('cropParameters');
      content.remove('lastCropSettings');
      content['isFlippedHorizontally'] = false;
      content['isFlippedVertically'] = false;
      content['rotation'] = 0.0;
      content['isTransformApplied'] = false; // 新选择的图像无需变换

      // 清除之前的图片尺寸信息，让系统重新检测
      content.remove('originalWidth');
      content.remove('originalHeight');
      content.remove('renderWidth');
      content.remove('renderHeight');

      // 立即加载新图像尺寸，避免界面显示错误的裁剪区域
      try {
        // 处理文件路径：如果包含 file:// 前缀，则去除前缀
        String filePath = importedItem.path;
        if (filePath.startsWith('file://')) {
          // 去除 file:// 前缀，转换为标准文件路径
          filePath = filePath.startsWith('file:///')
              ? filePath.substring(8)  // file:///C:/... -> C:/...
              : filePath.substring(7); // file://path -> path
        }
        
        final file = File(filePath);
        if (await file.exists()) {
          final imageBytes = await file.readAsBytes();
          final sourceImage = img.decodeImage(imageBytes);
          if (sourceImage != null) {
            content['originalWidth'] = sourceImage.width.toDouble();
            content['originalHeight'] = sourceImage.height.toDouble();
            // 初始渲染尺寸等于原始尺寸
            content['renderWidth'] = sourceImage.width.toDouble();
            content['renderHeight'] = sourceImage.height.toDouble();
          }
        }
      } catch (e) {
        // 如果获取尺寸失败，记录但不中断流程，让处理管道自行处理
        EditPageLogger.propertyPanelError(
          '获取新图像尺寸失败',
          tag: EditPageLoggingConfig.tagImagePanel,
          error: e,
          data: {
            'importedItemId': importedItem.id,
            'importedItemPath': importedItem.path,
          },
        );
      }

      // 清除所有图像变换和处理相关的缓存数据
      content.remove('transformedImageData');
      content.remove('transformedImageUrl');
      content.remove('transformRect');
      content.remove('binarizedImageData');
      content.remove('processedImageData');
      content.remove('cachedProcessedImage');
      content.remove('imageProcessingCache');

      // 重置二值化和处理标记，让图像处理管道重新开始
      content['needsReprocessing'] = true;
      content.remove('lastProcessingSettings');

      // 清除所有UI状态和预览缓存
      content.remove('previewImageData');
      content.remove('displayImageData');
      content.remove('uiCacheData');
      content.remove('lastRenderSize');
      content.remove('lastImageSize');

      // 强制重新初始化图像处理管道
      content['forceReload'] = true;

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
