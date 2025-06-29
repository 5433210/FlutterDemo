import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../application/services/practice/practice_list_refresh_service.dart';
import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../../dialogs/optimized_save_dialog.dart';
import '../../dialogs/practice_save_dialog.dart';
import 'export/export_dialog.dart';
import 'export/export_service.dart';
import 'export/page_renderer.dart';
import 'optimized_save_service.dart';
import 'practice_edit_controller.dart';

/// 文件操作工具类
class FileOperations {
  /// 导出字帖
  static Future<void> exportPractice(
    BuildContext context,
    List<Map<String, dynamic>> pages,
    PracticeEditController controller,
    String defaultFileName,
  ) async {
    EditPageLogger.editPageDebug(
      '开始导出字帖',
      data: {
        'pageCount': pages.length,
        'defaultFileName': defaultFileName,
      },
    );

    if (pages.isEmpty) {
      EditPageLogger.editPageError('没有可导出的页面');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).noPagesToExport)),
      );
      return;
    }

    debugPrint('显示导出对话框');

    // 显示导出对话框
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ExportDialog(
        pageCount: pages.length,
        defaultFileName: defaultFileName,
        currentPageIndex: controller.state.currentPageIndex,
        controller: controller,
        onExport: (outputPath, exportType, fileName, pixelRatio, extraParams) {
          debugPrint(
              '用户选择了导出参数: 路径=$outputPath, 类型=${exportType.name}, 文件名=$fileName, 像素比例=$pixelRatio, 额外参数=$extraParams');
          // 返回导出参数
          return {
            'outputPath': outputPath,
            'exportType': exportType,
            'fileName': fileName,
            'pixelRatio': pixelRatio,
            'extraParams': extraParams,
          };
        },
      ),
    );

    if (result == null) {
      EditPageLogger.editPageDebug('用户取消了导出');
      return;
    }

    debugPrint('导出对话框返回结果: $result');

    // 检查结果是否包含所需的键
    if (!result.containsKey('outputPath') ||
        !result.containsKey('exportType') ||
        !result.containsKey('fileName')) {
      debugPrint('错误: 导出对话框返回的结果缺少必要的键');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).exportFailure)),
        );
      }
      return;
    }

    final outputPath = result['outputPath'] as String;
    final exportType = result['exportType'] as ExportType;
    final fileName = result['fileName'] as String;
    final pixelRatio = result['pixelRatio'] as double;

    EditPageLogger.editPageDebug(
      '准备导出',
      data: {
        'outputPath': outputPath,
        'exportType': exportType.name,
        'fileName': fileName,
        'pixelRatio': pixelRatio,
      },
    );

    // 🔧 在异步操作开始前保存ScaffoldMessenger引用，避免后续查找已销毁的widget
    ScaffoldMessengerState? scaffoldMessenger;
    if (context.mounted) {
      scaffoldMessenger = ScaffoldMessenger.of(context);
      _safeShowSnackBar(scaffoldMessenger,
          SnackBar(content: Text(AppLocalizations.of(context).exporting)));
    }

    try {
      // 根据导出类型调用不同的导出方法
      if (exportType == ExportType.pdf) {
        debugPrint('开始导出PDF');
        // 获取额外参数
        final extraParams = result.containsKey('extraParams')
            ? result['extraParams'] as Map<String, dynamic>
            : <String, dynamic>{};

        debugPrint('导出PDF的额外参数: $extraParams');

        final pdfPath = await ExportService.exportToPdf(
          controller,
          outputPath,
          fileName,
          pixelRatio: pixelRatio,
          extraParams: extraParams,
        );

        debugPrint('PDF导出结果: ${pdfPath != null ? "成功" : "失败"}, 路径: $pdfPath');

        if (pdfPath != null) {
          // 检查文件是否存在
          final file = File(pdfPath);
          final exists = await file.exists();
          debugPrint('检查导出的PDF文件是否存在: $exists');

          if (exists) {
            final fileSize = await file.length();
            debugPrint('导出的PDF文件大小: $fileSize 字节');

            _safeShowSnackBar(
              scaffoldMessenger,
              SnackBar(
                content: Text(
                    AppLocalizations.of(context).pdfExportSuccess(pdfPath)),
                action: SnackBarAction(
                  label: AppLocalizations.of(context).openFolder,
                  onPressed: () {
                    // 打开文件所在的文件夹
                    final directory = path.dirname(pdfPath);
                    Process.run('explorer.exe', [directory]);
                  },
                ),
              ),
            );
          } else {
            _safeShowSnackBar(
              scaffoldMessenger,
              SnackBar(
                  content: Text(
                      AppLocalizations.of(context).pdfExportSuccess(pdfPath))),
            );
          }
        } else {
          _safeShowSnackBar(
            scaffoldMessenger,
            SnackBar(
                content: Text(AppLocalizations.of(context).pdfExportFailed)),
          );
        }
      } else {
        // 导出为图片
        debugPrint('开始导出图片, 格式: ${exportType.name}');
        final imagePaths = await ExportService.exportToImages(
          controller,
          outputPath,
          fileName,
          exportType,
          pixelRatio: pixelRatio,
        );

        debugPrint(
            '图片导出结果: ${imagePaths.isNotEmpty ? "成功" : "失败"}, 数量: ${imagePaths.length}');
        if (imagePaths.isNotEmpty) {
          for (int i = 0; i < imagePaths.length; i++) {
            debugPrint('导出的图片 ${i + 1}: ${imagePaths[i]}');
          }
        }

        if (imagePaths.isNotEmpty) {
          // 检查第一个文件是否存在
          if (imagePaths.isNotEmpty) {
            final file = File(imagePaths[0]);
            final exists = await file.exists();
            debugPrint('检查导出的第一个图片文件是否存在: $exists');

            if (exists) {
              final fileSize = await file.length();
              debugPrint('导出的第一个图片文件大小: $fileSize 字节');
            }
          }

          _safeShowSnackBar(
            scaffoldMessenger,
            SnackBar(
              content: Text(AppLocalizations.of(context).exportSuccess),
              action: SnackBarAction(
                label: AppLocalizations.of(context).openFolder,
                onPressed: () {
                  // 打开文件所在的文件夹
                  if (imagePaths.isNotEmpty) {
                    final directory = path.dirname(imagePaths[0]);
                    Process.run('explorer.exe', [directory]);
                  }
                },
              ),
            ),
          );
        } else {
          _safeShowSnackBar(
            scaffoldMessenger,
            SnackBar(
                content: Text(AppLocalizations.of(context).imageExportFailed)),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('导出过程中发生异常: $e');
      debugPrint('异常堆栈: $stack');

      _safeShowSnackBar(
        scaffoldMessenger,
        SnackBar(
            content: Text(AppLocalizations.of(context).error(e.toString()))),
      );
    } finally {
      debugPrint('=== 导出字帖过程结束 ===');
    }
  }

  /// 打印字帖
  static Future<void> printPractice(
    BuildContext context,
    List<Map<String, dynamic>> pages,
    PracticeEditController controller,
    String documentName,
  ) async {
    if (pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).noPagesToPrint)),
      );
      return;
    }

    // 🔧 在异步操作开始前保存ScaffoldMessenger引用，避免后续查找已销毁的widget
    ScaffoldMessengerState? scaffoldMessenger;
    if (context.mounted) {
      scaffoldMessenger = ScaffoldMessenger.of(context);
      _safeShowSnackBar(scaffoldMessenger,
          SnackBar(content: Text(AppLocalizations.of(context).preparingPrint)));
    }

    try {
      // 使用 PageRenderer 渲染所有页面
      final pageRenderer = PageRenderer(controller);
      final pageImages = await pageRenderer.renderAllPages(
        onProgress: (current, total) {
          debugPrint('渲染进度: $current/$total');
        },
        pixelRatio: 1.0, // 使用标准分辨率
      );

      if (pageImages.isEmpty) {
        _safeShowSnackBar(
          scaffoldMessenger,
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).cannotCapturePageImage)),
        );
        return;
      }

      // // 显示打印对话框
      // if (context.mounted) {
      //   await showDialog(
      //     context: context,
      //     builder: (context) => PrintDialog(
      //       pageImages: pageImages,
      //       documentName: documentName.isNotEmpty ? documentName : '未命名字帖',
      //     ),
      //   );
      // }
    } catch (e) {
      _safeShowSnackBar(
        scaffoldMessenger,
        SnackBar(
            content: Text(AppLocalizations.of(context).error(e.toString()))),
      );
    }
  }

  /// 另存为
  static Future<void> saveAs(BuildContext context,
      List<Map<String, dynamic>> pages, List<Map<String, dynamic>> layers,
      [PracticeEditController? controller]) async {
    if (controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context).cannotSaveMissingController)),
      );
      return;
    }

    // 使用现有的保存对话框
    final title = await showDialog<String>(
      context: context,
      builder: (context) => PracticeSaveDialog(
        initialTitle: controller.practiceTitle,
        isSaveAs: true,
        checkTitleExists: controller.checkTitleExists,
      ),
    );

    if (title == null || title.isEmpty) return;

    // 🔧 修复：统一使用优化的保存服务，确保与Save操作行为一致
    await _saveAsWithOptimizedService(context, controller, title);
  }

  /// 保存字帖
  static Future<void> savePractice(
      BuildContext context,
      List<Map<String, dynamic>> pages,
      List<Map<String, dynamic>> layers,
      String? practiceId,
      [PracticeEditController? controller]) async {
    if (controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context).cannotSaveMissingController)),
      );
      return;
    }

    // 开始性能监控
    final saveStartTime = DateTime.now();
    EditPageLogger.performanceInfo(
      '开始保存字帖',
      data: {
        'pageCount': pages.length,
        'layerCount': layers.length,
        'practiceId': practiceId,
        'hasTitle': controller.practiceTitle != null,
        'practiceTitle': controller.practiceTitle,
        'timestamp': saveStartTime.toIso8601String(),
      },
    );

    // 如果已经有字帖标题且字帖已保存过，直接保存
    if (controller.practiceTitle != null && controller.practiceId != null) {
      try {
        // 对于已保存过的字帖，直接保存不需要传入标题
        final result = await controller.savePractice();

        final saveDuration = DateTime.now().difference(saveStartTime);

        EditPageLogger.performanceInfo(
          '保存操作完成',
          data: {
            'saveResult': result.toString(),
            'saveDurationMs': saveDuration.inMilliseconds,
            'practiceTitle': controller.practiceTitle,
            'pageCount': pages.length,
            'operation': 'direct_save',
          },
        );

        // 检查context是否仍然有效
        if (context.mounted) {
          if (result == true) {
            // 通知字帖列表刷新
            if (controller.practiceId != null) {
              final refreshService = PracticeListRefreshService();

              EditPageLogger.fileOpsInfo(
                '准备发送字帖列表刷新通知',
                data: {
                  'practiceId': controller.practiceId!,
                  'operation': 'practice_saved',
                },
              );

              refreshService.notifyPracticeSaved(controller.practiceId!);

              EditPageLogger.fileOpsInfo(
                '字帖列表刷新通知已发送',
                data: {
                  'practiceId': controller.practiceId!,
                  'operation': 'practice_saved',
                },
              );
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)
                      .practiceSheetSaved(controller.practiceTitle!))),
            );
          } else if (result == 'title_exists') {
            // 如果标题已存在，询问是否覆盖
            final shouldOverwrite =
                await _confirmOverwrite(context, controller.practiceTitle!);
            if (shouldOverwrite && context.mounted) {
              // 强制覆盖保存
              final overwriteStartTime = DateTime.now();
              final overwriteResult = await controller.savePractice(
                forceOverwrite: true,
              );

              final overwriteDuration =
                  DateTime.now().difference(overwriteStartTime);

              EditPageLogger.performanceInfo(
                '覆盖保存完成',
                data: {
                  'overwriteResult': overwriteResult.toString(),
                  'overwriteDurationMs': overwriteDuration.inMilliseconds,
                  'totalDurationMs':
                      DateTime.now().difference(saveStartTime).inMilliseconds,
                  'practiceTitle': controller.practiceTitle,
                },
              );

              if (overwriteResult == true && context.mounted) {
                // 通知字帖列表刷新
                if (controller.practiceId != null) {
                  final refreshService = PracticeListRefreshService();
                  refreshService.notifyPracticeSaved(controller.practiceId!);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(AppLocalizations.of(context)
                          .overwriteExistingPractice(
                              controller.practiceTitle!))),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(AppLocalizations.of(context).saveFailed)),
                );
              }
            }
          } else {
            // 如果保存失败，显示错误消息
            EditPageLogger.performanceWarning(
              '保存操作失败',
              data: {
                'saveResult': result.toString(),
                'saveDurationMs': saveDuration.inMilliseconds,
                'practiceTitle': controller.practiceTitle,
                'pageCount': pages.length,
              },
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
            );
          }
        }
      } catch (error, stackTrace) {
        final saveDuration = DateTime.now().difference(saveStartTime);
        EditPageLogger.editPageError(
          '保存操作异常',
          error: error,
          stackTrace: stackTrace,
          data: {
            'saveDurationMs': saveDuration.inMilliseconds,
            'practiceTitle': controller.practiceTitle,
            'pageCount': pages.length,
            'operation': 'direct_save_exception',
          },
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)
                    .saveFailedWithError(error.toString()))),
          );
        }
      }
      return;
    }

    // 如果没有标题，显示保存对话框让用户输入标题
    final title = await showDialog<String>(
      context: context,
      builder: (context) => PracticeSaveDialog(
        initialTitle: '',
        isSaveAs: false,
        // 检查标题是否存在
        checkTitleExists: controller.checkTitleExists,
      ),
    );

    if (title == null || title.isEmpty) return;

    // 调用控制器的savePractice方法（会自动处理新字帖）
    final result = await controller.savePractice(title: title);

    // 检查context是否仍然有效
    if (context.mounted) {
      if (result == true) {
        // 通知字帖列表刷新
        if (controller.practiceId != null) {
          final refreshService = PracticeListRefreshService();
          refreshService.notifyPracticeSaved(controller.practiceId!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).practiceSheetSaved(title))),
        );
      } else if (result == 'title_exists') {
        // 如果标题已存在，询问是否覆盖
        final shouldOverwrite = await _confirmOverwrite(context, title);
        if (shouldOverwrite && context.mounted) {
          // 强制覆盖保存
          final overwriteResult = await controller.savePractice(
            title: title,
            forceOverwrite: true,
          );

          if (overwriteResult == true && context.mounted) {
            // 通知字帖列表刷新
            if (controller.practiceId != null) {
              final refreshService = PracticeListRefreshService();
              refreshService.notifyPracticeSaved(controller.practiceId!);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)
                      .overwriteExistingPractice(title))),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
            );
          }
        }
      } else {
        // 如果保存失败，显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
        );
      }
    }
  }

  /// 优化的保存字帖方法
  ///
  /// 特点：
  /// 1. 不进入预览模式生成缩略图
  /// 2. 显示保存进度，禁用用户操作
  /// 3. 自动更新缓存
  static Future<void> savePracticeOptimized(
    BuildContext context,
    PracticeEditController controller, {
    String? title,
    bool forceOverwrite = false,
    GlobalKey? canvasKey,
  }) async {
    try {
      // 如果是新字帖且没有提供标题，显示保存对话框
      if (!controller.isSaved && title == null) {
        final inputTitle = await showDialog<String>(
          context: context,
          builder: (context) => PracticeSaveDialog(
            initialTitle: '',
            isSaveAs: false,
            checkTitleExists: controller.checkTitleExists,
          ),
        );

        if (inputTitle == null || inputTitle.isEmpty) return;
        title = inputTitle;
        
        // 🔧 添加短暂延迟，确保对话框完全关闭后再进行下一步操作
        // 避免导航栈中的类型混乱
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 再次检查context是否仍然有效
        if (!context.mounted) return;
      }

      // 创建保存Future
      final saveFuture = OptimizedSaveService.savePracticeOptimized(
        controller: controller,
        context: context,
        title: title,
        forceOverwrite: forceOverwrite,
        canvasKey: canvasKey,
        onProgress: (progress, message) {
          // 进度回调在对话框内部处理
        },
      );

      // 显示保存进度对话框
      final result = await showOptimizedSaveDialog(
        context: context,
        saveFuture: saveFuture,
        title: title ?? controller.practiceTitle ?? '未命名字帖',
      );

      if (!context.mounted) return;

      // 处理保存结果
      if (result != null) {
        if (result.success) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //       content: Text(result.message ??
          //           AppLocalizations.of(context).saveSuccess)),
          // );
        } else if (result.error == 'title_exists') {
          // 处理标题冲突
          final shouldOverwrite = await _confirmOverwrite(context, title!);
          if (shouldOverwrite && context.mounted) {
            // 重试保存，强制覆盖
            await savePracticeOptimized(
              context,
              controller,
              title: title,
              forceOverwrite: true,
              canvasKey: canvasKey,
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    result.error ?? AppLocalizations.of(context).saveFailed)),
          );
        }
      }
    } catch (e) {
      // 只有在context仍然mounted时才记录日志，避免dispose错误
      if (context.mounted) {
        EditPageLogger.fileOpsError(
          '优化保存过程异常',
          error: e,
          data: {
            'title': title,
            'hasCanvasKey': canvasKey != null,
            'error': e.toString(),
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .saveFailedWithError(e.toString()))),
        );
      }
    }
  }

  /// 确认是否覆盖现有字帖
  static Future<bool> _confirmOverwrite(
      BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmOverwrite),
        content:
            Text(AppLocalizations.of(context).overwriteExistingPractice(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).overwrite),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 🔧 安全地显示SnackBar，避免在widget销毁后调用导致错误
  static void _safeShowSnackBar(
    ScaffoldMessengerState? scaffoldMessenger,
    SnackBar snackBar,
  ) {
    if (scaffoldMessenger != null) {
      try {
        scaffoldMessenger.showSnackBar(snackBar);
      } catch (e) {
        // 如果显示SnackBar失败，记录日志但不抛出异常
        EditPageLogger.editPageError('显示SnackBar失败', error: e);
      }
    }
  }

  /// 使用优化服务执行另存为操作
  static Future<void> _saveAsWithOptimizedService(
    BuildContext context,
    PracticeEditController controller,
    String title,
  ) async {
    // 临时保存当前ID，用于另存为操作
    final originalId = controller.practiceId;
    final originalTitle = controller.practiceTitle;

    try {
      // 清除当前ID，确保创建新字帖
      controller.currentPracticeId = null;

      // 使用优化的保存服务，避免预览模式切换
      await savePracticeOptimized(
        context,
        controller,
        title: title,
        forceOverwrite: false,
        canvasKey: controller.canvasKey,
      );
    } catch (e) {
      // 如果保存失败，恢复原始状态
      if (controller.practiceId == null && originalId != null) {
        controller.currentPracticeId = originalId;
        controller.currentPracticeTitle = originalTitle;
      }

      // 记录错误但不重新抛出，savePracticeOptimized已经处理了UI反馈
      EditPageLogger.fileOpsError(
        'Save As操作失败',
        error: e,
        data: {
          'title': title,
          'originalId': originalId,
          'originalTitle': originalTitle,
        },
      );
    }
  }
}
