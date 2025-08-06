import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 文件选择器服务
abstract class FilePickerService {
  /// 选择单个文件
  Future<String?> pickFile({
    String? dialogTitle,
    List<String>? allowedExtensions,
    String? initialDirectory,
  });

  /// 选择多个文件
  Future<List<String>?> pickFiles({
    String? dialogTitle,
    List<String>? allowedExtensions,
    String? initialDirectory,
  });

  /// 选择保存文件路径
  Future<String?> pickSaveFile({
    String? dialogTitle,
    String? suggestedName,
    List<String>? allowedExtensions,
    String? initialDirectory,
  });

  /// 选择目录
  Future<String?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
  });
}

/// 文件选择器服务的实现
class FilePickerServiceImpl implements FilePickerService {
  @override
  Future<String?> pickFile({
    String? dialogTitle,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: dialogTitle,
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        return file.path;
      }

      return null;
    } catch (e) {
      // 如果文件选择器出错，返回null
      return null;
    }
  }

  @override
  Future<List<String>?> pickFiles({
    String? dialogTitle,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: dialogTitle,
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList();
      }

      return null;
    } catch (e) {
      // 如果文件选择器出错，返回null
      return null;
    }
  }

  @override
  Future<String?> pickSaveFile({
    String? dialogTitle,
    String? suggestedName,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: suggestedName,
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
      );

      return result;
    } catch (e) {
      // 如果文件选择器出错，尝试使用默认路径
      try {
        Directory? defaultDir;
        try {
          defaultDir = await getDownloadsDirectory();
        } catch (e) {
          try {
            defaultDir = await getApplicationDocumentsDirectory();
          } catch (e2) {
            defaultDir = await getTemporaryDirectory();
          }
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = suggestedName ?? 'export_$timestamp.zip';

        if (defaultDir != null) {
          return path.join(defaultDir.path, fileName);
        } else {
          return 'Downloads/$fileName';
        }
      } catch (e) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = suggestedName ?? 'export_$timestamp.zip';
        return 'Downloads/$fileName';
      }
    }
  }

  @override
  Future<String?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
  }) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle,
      );

      return result;
    } catch (e) {
      // 如果文件选择器出错，尝试返回默认目录
      try {
        Directory? defaultDir;
        try {
          defaultDir = await getDownloadsDirectory();
        } catch (e) {
          try {
            defaultDir = await getApplicationDocumentsDirectory();
          } catch (e2) {
            defaultDir = await getTemporaryDirectory();
          }
        }

        return defaultDir?.path ?? 'Downloads';
      } catch (e) {
        return 'Downloads';
      }
    }
  }
}
