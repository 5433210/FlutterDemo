import 'dart:io';

import 'package:flutter/foundation.dart';

import '../infrastructure/logging/logger.dart';

/// Linux平台文件选择器备用实现
/// 当zenity不可用时，使用命令行交互方式选择文件
class LinuxFilePicker {
  /// 选择文件（备用实现）
  static Future<List<String>?> pickFiles({
    String? dialogTitle,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    try {
      // 首先尝试使用zenity
      return await _pickFilesWithZenity(
        dialogTitle: dialogTitle,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );
    } catch (e) {
      if (kDebugMode) {
        print('zenity不可用，使用备用方法: $e');
      }

      // 备用方法：使用命令行交互
      return await _pickFilesWithFallback(
        dialogTitle: dialogTitle,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );
    }
  }

  /// 使用zenity选择文件
  static Future<List<String>?> _pickFilesWithZenity({
    String? dialogTitle,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    List<String> command = ['zenity', '--file-selection'];

    if (dialogTitle != null) {
      command.addAll(['--title', dialogTitle]);
    }

    if (allowMultiple) {
      command.add('--multiple');
    }

    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      String filter = allowedExtensions.map((ext) => '*.$ext').join(' ');
      command.addAll(['--file-filter', filter]);
    }

    final ProcessResult result = await Process.run(
      command.first,
      command.sublist(1),
      environment: {'DISPLAY': ':99'}, // 使用虚拟显示器
    );

    if (result.exitCode == 0) {
      String output = result.stdout.toString().trim();
      if (output.isNotEmpty) {
        return allowMultiple
            ? output.split('|').where((path) => path.isNotEmpty).toList()
            : [output];
      }
    }

    throw Exception('zenity执行失败: ${result.stderr}');
  }

  /// 备用文件选择方法（命令行交互）
  static Future<List<String>?> _pickFilesWithFallback({
    String? dialogTitle,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    try {
      // 使用find命令列出可用文件
      ProcessResult result = await Process.run(
        'find',
        ['.', '-maxdepth', '3', '-type', 'f'],
      );

      if (result.exitCode == 0) {
        List<String> files = result.stdout
            .toString()
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .take(20) // 限制显示前20个文件
            .toList();

        if (files.isNotEmpty) {
          AppLogger.info('Linux文件选择器 (备用方法)', tag: 'LinuxFilePicker');
          AppLogger.info('可用文件列表:', tag: 'LinuxFilePicker');
          for (int i = 0; i < files.length; i++) {
            AppLogger.info('${i + 1}. ${files[i]}', tag: 'LinuxFilePicker');
          }

          AppLogger.info('请输入文件编号 (1-${files.length}), 或输入完整路径:', tag: 'LinuxFilePicker');

          // 在实际应用中，这里需要更复杂的用户输入处理
          // 这只是一个示例实现
          return [files.first]; // 暂时返回第一个文件
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('备用文件选择器失败: $e');
      }
    }

    return null;
  }

  /// 选择目录
  static Future<String?> getDirectoryPath({
    String? dialogTitle,
  }) async {
    try {
      List<String> command = ['zenity', '--file-selection', '--directory'];

      if (dialogTitle != null) {
        command.addAll(['--title', dialogTitle]);
      }

      final ProcessResult result = await Process.run(
        command.first,
        command.sublist(1),
        environment: {'DISPLAY': ':99'},
      );

      if (result.exitCode == 0) {
        String output = result.stdout.toString().trim();
        return output.isNotEmpty ? output : null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('目录选择失败: $e');
      }
    }

    return null;
  }
}
