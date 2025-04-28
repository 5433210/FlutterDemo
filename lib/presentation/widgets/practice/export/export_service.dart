import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../practice_edit_controller.dart';
import 'page_renderer.dart';

/// 导出服务
class ExportService {
  /// 导出为图片
  static Future<List<String>> exportToImages(PracticeEditController controller,
      String outputPath, String fileNamePrefix, ExportType exportType,
      {double pixelRatio = 1.0}) async {
    final List<String> exportedFiles = [];

    try {
      debugPrint(
          '开始导出图片: 页面数=${controller.state.pages.length}, 输出路径=$outputPath, 文件名前缀=$fileNamePrefix, 格式=${exportType.name}');

      // 检查输出路径是否有效
      if (outputPath.isEmpty) {
        debugPrint('错误: 输出路径为空');
        return exportedFiles;
      }

      // 检查文件系统权限
      try {
        debugPrint('检查文件系统权限...');
        final testFile = File(path.join(outputPath, '.test_write_permission'));
        await testFile.writeAsString('test');
        await testFile.delete();
        debugPrint('文件系统权限检查通过');
      } catch (e) {
        debugPrint('文件系统权限检查失败: $e');
        debugPrint('尝试创建目录并再次检查权限...');
      }

      // 确保目录存在
      final dir = Directory(outputPath);
      if (!await dir.exists()) {
        debugPrint('创建目录: $outputPath');
        await dir.create(recursive: true);
      }

      // 再次检查目录是否存在
      if (!await dir.exists()) {
        debugPrint('错误: 无法创建目录: $outputPath');
        return exportedFiles;
      }

      debugPrint('目录已准备好: $outputPath');

      // 创建页面渲染器
      final pageRenderer = PageRenderer(controller);

      // 渲染所有页面
      final pageImages = await pageRenderer.renderAllPages(
        onProgress: (current, total) {
          debugPrint('渲染进度: $current/$total');
        },
        pixelRatio: pixelRatio,
      );

      if (pageImages.isEmpty) {
        debugPrint('错误: 未能渲染任何页面');
        return exportedFiles;
      }

      debugPrint('成功渲染 ${pageImages.length} 个页面');

      // 保存图片文件
      for (int i = 0; i < pageImages.length; i++) {
        final image = pageImages[i];

        // 构建文件名
        final pageNumber = i + 1;
        final fileName = pageImages.length > 1
            ? '${fileNamePrefix}_$pageNumber.${exportType.extension}'
            : '$fileNamePrefix.${exportType.extension}';

        // 保存图片文件
        final filePath = path.join(outputPath, fileName);
        debugPrint('保存图片文件到: $filePath');

        try {
          final file = File(filePath);

          // 确保文件不存在
          if (await file.exists()) {
            debugPrint('文件已存在，先删除: $filePath');
            await file.delete();
          }

          // 写入文件
          debugPrint('开始写入图片文件: $filePath');
          await file.writeAsBytes(image);

          // 验证文件是否已创建
          if (await file.exists()) {
            final fileSize = await file.length();
            debugPrint('图片文件保存成功: $filePath (大小: $fileSize 字节)');

            // 尝试打开文件以验证其完整性
            try {
              final readTest = await file.readAsBytes();
              debugPrint('文件读取测试成功: ${readTest.length} 字节');
            } catch (e) {
              debugPrint('文件读取测试失败: $e');
            }

            exportedFiles.add(file.path);
          } else {
            debugPrint('错误: 文件写入后不存在: $filePath');
          }
        } catch (e, stack) {
          debugPrint('保存图片文件失败: $e');
          debugPrint('堆栈跟踪: $stack');
        }
      }

      debugPrint('导出完成，成功导出 ${exportedFiles.length} 个文件');
      return exportedFiles;
    } catch (e, stack) {
      debugPrint('导出图片失败: $e');
      debugPrint('堆栈跟踪: $stack');
      return exportedFiles;
    }
  }

  /// 导出为PDF
  static Future<String?> exportToPdf(
      PracticeEditController controller, String outputPath, String fileName,
      {double pixelRatio = 1.0}) async {
    try {
      debugPrint(
          '开始导出PDF: 页面数=${controller.state.pages.length}, 输出路径=$outputPath, 文件名=$fileName');

      // 检查输出路径是否有效
      if (outputPath.isEmpty) {
        debugPrint('错误: 输出路径为空');
        return null;
      }

      // 检查文件系统权限
      try {
        debugPrint('检查文件系统权限...');
        final testFile = File(path.join(outputPath, '.test_write_permission'));
        await testFile.writeAsString('test');
        await testFile.delete();
        debugPrint('文件系统权限检查通过');
      } catch (e) {
        debugPrint('文件系统权限检查失败: $e');
        debugPrint('尝试创建目录并再次检查权限...');
      }

      // 创建页面渲染器
      final pageRenderer = PageRenderer(controller);

      // 渲染所有页面
      final pageImages = await pageRenderer.renderAllPages(
        onProgress: (current, total) {
          debugPrint('渲染进度: $current/$total');
        },
        pixelRatio: pixelRatio,
      );

      if (pageImages.isEmpty) {
        debugPrint('错误: 未能渲染任何页面');
        return null;
      }

      debugPrint('成功渲染 ${pageImages.length} 个页面');

      // 创建PDF文档
      final pdf = pw.Document();

      // 为每个页面创建PDF页面
      for (int i = 0; i < pageImages.length; i++) {
        final image = pageImages[i];

        debugPrint('添加第 ${i + 1} 页到PDF: ${image.length} 字节');

        // 添加页面到PDF
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  pw.MemoryImage(image),
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }

      // 确保文件名有.pdf后缀
      String pdfFileName = fileName;
      if (!pdfFileName.toLowerCase().endsWith('.pdf')) {
        pdfFileName = '$pdfFileName.pdf';
      }

      // 确保目录存在
      final dir = Directory(outputPath);
      if (!await dir.exists()) {
        debugPrint('创建目录: $outputPath');
        await dir.create(recursive: true);
      }

      // 再次检查目录是否存在
      if (!await dir.exists()) {
        debugPrint('错误: 无法创建目录: $outputPath');
        return null;
      }

      debugPrint('目录已准备好: $outputPath');

      // 保存PDF文件
      final filePath = path.join(outputPath, pdfFileName);
      debugPrint('保存PDF文件到: $filePath');

      try {
        final file = File(filePath);

        // 保存文件
        final pdfBytes = await pdf.save();
        debugPrint('PDF生成完成: ${pdfBytes.length} 字节');

        // 确保文件不存在
        if (await file.exists()) {
          debugPrint('文件已存在，先删除: $filePath');
          await file.delete();
        }

        // 写入文件
        debugPrint('开始写入PDF文件: $filePath');
        await file.writeAsBytes(pdfBytes);

        // 验证文件是否已创建
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('PDF文件保存成功: $filePath (大小: $fileSize 字节)');

          // 尝试打开文件以验证其完整性
          try {
            final readTest = await file.readAsBytes();
            debugPrint('文件读取测试成功: ${readTest.length} 字节');
          } catch (e) {
            debugPrint('文件读取测试失败: $e');
          }

          return file.path;
        } else {
          debugPrint('错误: PDF文件写入后不存在: $filePath');
          return null;
        }
      } catch (e, stack) {
        debugPrint('保存PDF文件失败: $e');
        debugPrint('堆栈跟踪: $stack');
        return null;
      }
    } catch (e, stack) {
      debugPrint('导出PDF失败: $e');
      debugPrint('堆栈跟踪: $stack');
      return null;
    }
  }
}

/// 导出类型
enum ExportType {
  pdf('PDF', 'pdf'),
  png('PNG', 'png'),
  jpg('JPG', 'jpg');

  final String name;
  final String extension;
  const ExportType(this.name, this.extension);
}
