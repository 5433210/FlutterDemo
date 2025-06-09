import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../dialogs/practice_save_dialog.dart';
import 'export/export_dialog.dart';
import 'export/export_service.dart';
import 'export/page_renderer.dart';
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
        const SnackBar(content: Text('没有可导出的页面')),
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
          const SnackBar(content: Text('导出失败: 参数不完整')),
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

    // 显示导出进度
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在导出，请稍候...')),
      );
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

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF导出成功: $pdfPath'),
                  action: SnackBarAction(
                    label: '打开文件夹',
                    onPressed: () {
                      // 打开文件所在的文件夹
                      final directory = path.dirname(pdfPath);
                      Process.run('explorer.exe', [directory]);
                    },
                  ),
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PDF导出成功，但无法找到文件: $pdfPath')),
              );
            }
          }
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF导出失败')),
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

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('导出${imagePaths.length}个图片成功'),
                action: SnackBarAction(
                  label: '打开文件夹',
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
          }
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片导出失败')),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('导出过程中发生异常: $e');
      debugPrint('异常堆栈: $stack');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
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
        const SnackBar(content: Text('没有可打印的页面')),
      );
      return;
    }

    // 显示加载提示
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在准备打印，请稍候...')),
      );
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法捕获页面图像')),
          );
        }
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打印准备失败: $e')),
        );
      }
    }
  }

  /// 另存为
  static Future<void> saveAs(BuildContext context,
      List<Map<String, dynamic>> pages, List<Map<String, dynamic>> layers,
      [PracticeEditController? controller]) async {
    if (controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法保存：缺少控制器')),
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

    // 调用控制器的saveAsNewPractice方法
    final result = await controller.saveAsNewPractice(title);

    // 检查context是否仍然有效
    if (context.mounted) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('字帖 "$title" 已保存')),
        );
      } else if (result == 'title_exists') {
        // 如果标题已存在，询问是否覆盖
        final shouldOverwrite = await _confirmOverwrite(context, title);
        if (shouldOverwrite && context.mounted) {
          // 强制覆盖保存
          final overwriteResult = await controller.saveAsNewPractice(
            title,
            forceOverwrite: true,
          );

          if (overwriteResult == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('字帖 "$title" 已覆盖保存')),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('保存失败，请稍后重试')),
            );
          }
        }
      } else {
        // 如果保存失败，显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请稍后重试')),
        );
      }
    }
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
        const SnackBar(content: Text('无法保存：缺少控制器')),
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

    // 如果已经有字帖标题，直接保存
    if (controller.practiceTitle != null) {
      try {
        // 确保将当前的页面内容传递给保存方法
        final result =
            await controller.savePractice(title: controller.practiceTitle);

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('字帖 "${controller.practiceTitle}" 已保存')),
            );
          } else if (result == 'title_exists') {
            // 如果标题已存在，询问是否覆盖
            final shouldOverwrite =
                await _confirmOverwrite(context, controller.practiceTitle!);
            if (shouldOverwrite && context.mounted) {
              // 强制覆盖保存
              final overwriteStartTime = DateTime.now();
              final overwriteResult = await controller.savePractice(
                title: controller.practiceTitle,
                forceOverwrite: true,
              );

              final overwriteDuration = DateTime.now().difference(overwriteStartTime);
              
              EditPageLogger.performanceInfo(
                '覆盖保存完成',
                data: {
                  'overwriteResult': overwriteResult.toString(),
                  'overwriteDurationMs': overwriteDuration.inMilliseconds,
                  'totalDurationMs': DateTime.now().difference(saveStartTime).inMilliseconds,
                  'practiceTitle': controller.practiceTitle,
                },
              );

              if (overwriteResult == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('字帖 "${controller.practiceTitle}" 已覆盖保存')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('保存失败，请稍后重试')),
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
              const SnackBar(content: Text('保存失败，请稍后重试')),
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
            SnackBar(content: Text('保存失败：$error')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('字帖 "$title" 已保存')),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('字帖 "$title" 已覆盖保存')),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('保存失败，请稍后重试')),
            );
          }
        }
      } else {
        // 如果保存失败，显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请稍后重试')),
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
        title: const Text('确认覆盖'),
        content: Text('已存在名为"$title"的字帖，是否覆盖？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('覆盖'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
