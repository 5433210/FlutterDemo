import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../practice_edit_controller.dart';
import 'export_dialog.dart';
import 'page_renderer.dart';

/// 导出服务
class ExportService {
  /// 导出为图片
  static Future<List<String>> exportToImages(PracticeEditController controller,
      String outputPath, String fileNamePrefix, ExportType exportType,
      {double pixelRatio = 1.0}) async {
    final List<String> exportedFiles = [];

    try {
      EditPageLogger.fileOpsInfo(
          '开始导出图片: 页面数=${controller.state.pages.length}, 输出路径=$outputPath, 格式=${exportType.name}');

      // 检查输出路径是否有效
      if (outputPath.isEmpty) {
        EditPageLogger.fileOpsError('输出路径为空');
        return exportedFiles;
      }

      // 检查文件系统权限
      try {
        final testFile = File(path.join(outputPath, '.test_write_permission'));
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (e) {
        EditPageLogger.editPageWarning('文件系统权限检查失败，将尝试创建目录: $e');
      }

      // 确保目录存在
      final dir = Directory(outputPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 再次检查目录是否存在
      if (!await dir.exists()) {
        EditPageLogger.fileOpsError('无法创建目录: $outputPath');
        return exportedFiles;
      }

      // 创建页面渲染器
      final pageRenderer = PageRenderer(controller);

      // 渲染所有页面
      final pageImages = await pageRenderer.renderAllPages(
        onProgress: (current, total) {
          if (current % 5 == 0 || current == total) {
            EditPageLogger.editPageDebug('渲染进度: $current/$total');
          }
        },
        pixelRatio: pixelRatio,
      );

      if (pageImages.isEmpty) {
        EditPageLogger.fileOpsError('未能渲染任何页面');
        return exportedFiles;
      }

      EditPageLogger.fileOpsInfo('成功渲染 ${pageImages.length} 个页面');

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

        try {
          final file = File(filePath);

          // 确保文件不存在
          if (await file.exists()) {
            await file.delete();
          }

          // 写入文件
          await file.writeAsBytes(image);

          // 验证文件是否已创建
          if (await file.exists()) {
            final fileSize = await file.length();
            EditPageLogger.editPageDebug('图片文件保存成功: $fileName (大小: $fileSize 字节)');
            exportedFiles.add(file.path);
          } else {
            EditPageLogger.fileOpsError('文件写入后不存在: $filePath');
          }
        } catch (e, stack) {
          EditPageLogger.fileOpsError('保存图片文件失败: $e', stackTrace: stack);
        }
      }

      EditPageLogger.fileOpsInfo('导出完成，成功导出 ${exportedFiles.length} 个文件');
      return exportedFiles;
    } catch (e, stack) {
      EditPageLogger.fileOpsError('导出图片失败: $e', stackTrace: stack);
      return exportedFiles;
    }
  }

  /// 导出为PDF
  static Future<String?> exportToPdf(
      PracticeEditController controller, String outputPath, String fileName,
      {double pixelRatio = 1.0, Map<String, dynamic>? extraParams}) async {
    try {
      extraParams ??= {};
      EditPageLogger.fileOpsInfo(
          '开始导出PDF: 页面数=${controller.state.pages.length}, 输出路径=$outputPath, 文件名=$fileName');

      // 检查输出路径是否有效
      if (outputPath.isEmpty) {
        EditPageLogger.fileOpsError('输出路径为空');
        return null;
      }

      // 检查文件系统权限
      try {
        final testFile = File(path.join(outputPath, '.test_write_permission'));
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (e) {
        EditPageLogger.editPageWarning('文件系统权限检查失败，将尝试创建目录: $e');
      }

      // 确保目录存在
      final dir = Directory(outputPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 再次检查目录是否存在
      if (!await dir.exists()) {
        EditPageLogger.fileOpsError('无法创建目录: $outputPath');
        return null;
      }

      // 创建页面渲染器
      final pageRenderer = PageRenderer(controller);

      // 获取页面格式
      final PdfPageFormat pageFormat = extraParams.containsKey('pageFormat')
          ? extraParams['pageFormat'] as PdfPageFormat
          : PdfPageFormat.a4;
      // 检查页面格式是否为横向
      final isLandscape = pageFormat.width > pageFormat.height;
      EditPageLogger.editPageDebug('使用页面格式: $pageFormat, 朝向: ${isLandscape ? "横向" : "纵向"}');

      // 页面范围
      List<int> pageIndices = [];
      if (extraParams.containsKey('pageRangeType')) {
        final pageRangeType = extraParams['pageRangeType'];
        if (pageRangeType == PageRangeType.all) {
          // 所有页面
          pageIndices =
              List.generate(controller.state.pages.length, (index) => index);
          EditPageLogger.editPageDebug('导出所有页面: ${pageIndices.length}页');
        } else if (pageRangeType == PageRangeType.current) {
          // 当前页面
          final currentPage = extraParams.containsKey('currentPage')
              ? extraParams['currentPage'] as int
              : 0;
          pageIndices = [currentPage];
          EditPageLogger.editPageDebug('只导出当前页面: 第${currentPage + 1}页');
        } else if (pageRangeType == PageRangeType.custom &&
            extraParams.containsKey('pageRange')) {
          // 自定义范围
          final pageRange = extraParams['pageRange'] as String;
          pageIndices =
              _parsePageRange(pageRange, controller.state.pages.length);
          EditPageLogger.editPageDebug('导出自定义范围页面: $pageRange => ${pageIndices.length}页');
        }
      } else {
        // 默认导出所有页面
        pageIndices =
            List.generate(controller.state.pages.length, (index) => index);
      }

      // 确保至少有一页
      if (pageIndices.isEmpty) {
        pageIndices = [0];
        EditPageLogger.editPageWarning(
            'No valid page range specified, using first page by default');
      }

      // 边距 (单位: 厘米 => 点)
      List<double> margins = extraParams.containsKey('margins')
          ? (extraParams['margins'] as List<dynamic>).cast<double>()
          : [0.0, 0.0, 0.0, 0.0]; // 默认0厘米边距 [上, 右, 下, 左]

      final marginTop = margins[0] * PdfPageFormat.cm;
      final marginRight = margins[1] * PdfPageFormat.cm;
      final marginBottom = margins[2] * PdfPageFormat.cm;
      final marginLeft = margins[3] * PdfPageFormat.cm;

      EditPageLogger.editPageDebug(
          '页面边距 (厘米): 上=${margins[0]}, 右=${margins[1]}, 下=${margins[2]}, 左=${margins[3]}');

      // 适配策略
      final fitPolicy = extraParams.containsKey('fitPolicy')
          ? extraParams['fitPolicy'] as PdfFitPolicy
          : PdfFitPolicy.width;
      EditPageLogger.editPageDebug('适配策略: $fitPolicy');

      // 渲染指定的页面
      final List<Uint8List> pageImages = [];
      for (final pageIndex in pageIndices) {
        if (pageIndex < 0 || pageIndex >= controller.state.pages.length) {
          EditPageLogger.editPageWarning(
              'Skipping invalid page index: $pageIndex (out of range)');
          continue;
        }

        final pageImage = await pageRenderer.renderSinglePage(
          pageIndex,
          pixelRatio: pixelRatio,
        );

        if (pageImage != null) {
          pageImages.add(pageImage);
        } else {
          EditPageLogger.editPageWarning(
              'Failed to render page ${pageIndex + 1}, skipping');
        }
      }

      if (pageImages.isEmpty) {
        EditPageLogger.fileOpsError('未能渲染任何页面');
        return null;
      }

      EditPageLogger.fileOpsInfo('成功渲染 ${pageImages.length} 个页面');

      // 创建PDF文档
      final pdf = pw.Document();

      // 为每个页面创建PDF页面
      for (int i = 0; i < pageImages.length; i++) {
        final image = pageImages[i];
        final pageIndex = pageIndices[i < pageIndices.length ? i : 0];

        // 使用指定的页面格式，应用边距
        final effectivePageFormat = pageFormat.copyWith(
          marginTop: marginTop,
          marginRight: marginRight,
          marginBottom: marginBottom,
          marginLeft: marginLeft,
        );

        // 添加页面到PDF
        pdf.addPage(
          pw.Page(
            pageFormat: effectivePageFormat,
            build: (pw.Context context) {
              pw.Widget imageWidget = pw.Image(pw.MemoryImage(image));

              // 应用适配策略
              switch (fitPolicy) {
                case PdfFitPolicy.width:
                  imageWidget = pw.FittedBox(
                    fit: pw.BoxFit.fitWidth,
                    child: imageWidget,
                  );
                  break;
                case PdfFitPolicy.height:
                  imageWidget = pw.FittedBox(
                    fit: pw.BoxFit.fitHeight,
                    child: imageWidget,
                  );
                  break;
                case PdfFitPolicy.contain:
                  imageWidget = pw.FittedBox(
                    fit: pw.BoxFit.contain,
                    child: imageWidget,
                  );
                  break;
              }

              return pw.Center(child: imageWidget);
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
      final directory = Directory(outputPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 再次检查目录是否存在
      if (!await directory.exists()) {
        EditPageLogger.fileOpsError('无法创建目录: $outputPath');
        return null;
      }

      // 保存PDF文件
      final filePath = path.join(outputPath, pdfFileName);

      try {
        final file = File(filePath);

        // 保存文件
        final pdfBytes = await pdf.save();
        EditPageLogger.editPageDebug('PDF生成完成: ${pdfBytes.length} 字节');

        // 确保文件不存在
        if (await file.exists()) {
          await file.delete();
        }

        // 写入文件
        await file.writeAsBytes(pdfBytes);

        // 验证文件是否已创建
        if (await file.exists()) {
          final fileSize = await file.length();
          EditPageLogger.fileOpsInfo('PDF文件保存成功: $pdfFileName (大小: $fileSize 字节)');
          return file.path;
        } else {
          EditPageLogger.fileOpsError('PDF文件写入后不存在: $filePath');
          return null;
        }
      } catch (e, stack) {
        EditPageLogger.fileOpsError('保存PDF文件失败: $e', stackTrace: stack);
        return null;
      }
    } catch (e, stack) {
      EditPageLogger.fileOpsError('导出PDF失败: $e', stackTrace: stack);
      return null;
    }
  }

  /// 解析页面范围字符串，返回页面索引列表
  static List<int> _parsePageRange(String pageRange, int totalPages) {
    try {
      final Set<int> pageIndices = {};

      // 按逗号分割范围
      final ranges = pageRange.split(',');

      for (final range in ranges) {
        final trimmedRange = range.trim();
        if (trimmedRange.isEmpty) continue;

        // 检查是否是范围（包含'-'）
        if (trimmedRange.contains('-')) {
          final parts = trimmedRange.split('-');
          if (parts.length == 2) {
            final start = int.tryParse(parts[0].trim());
            final end = int.tryParse(parts[1].trim());

            if (start != null && end != null) {
              // 调整为基于0的索引并确保在有效范围内
              final adjustedStart = (start - 1).clamp(0, totalPages - 1);
              final adjustedEnd = (end - 1).clamp(0, totalPages - 1);

              // 添加范围内的所有页
              for (int i = adjustedStart; i <= adjustedEnd; i++) {
                pageIndices.add(i);
              }
            }
          }
        } else {
          // 单个页
          final page = int.tryParse(trimmedRange);
          if (page != null) {
            // 调整为基于0的索引
            final adjustedPage = (page - 1).clamp(0, totalPages - 1);
            pageIndices.add(adjustedPage);
          }
        }
      }

      // 转换为列表并按页码排序
      final result = pageIndices.toList()..sort();
      return result;
    } catch (e) {
      EditPageLogger.fileOpsError('解析页面范围失败: $e');
      // 出错时返回空列表
      return [];
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
