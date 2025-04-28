import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 打印对话框
class PrintDialog extends StatefulWidget {
  /// 页面数据
  final List<Uint8List> pageImages;

  /// 文档名称
  final String documentName;

  const PrintDialog({
    Key? key,
    required this.pageImages,
    required this.documentName,
  }) : super(key: key);

  @override
  State<PrintDialog> createState() => _PrintDialogState();
}

class _PrintDialogState extends State<PrintDialog> {
  /// 当前页面索引
  int _currentPageIndex = 0;

  /// 生成PDF文档
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(title: widget.documentName);

    for (final pageImage in widget.pageImages) {
      final image = pw.MemoryImage(pageImage);
      
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// 构建页面预览
  Widget _buildPagePreview() {
    if (widget.pageImages.isEmpty) {
      return const Center(
        child: Text('没有可打印的页面'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Center(
              child: AspectRatio(
                aspectRatio: 210 / 297, // A4纸比例
                child: Image.memory(
                  widget.pageImages[_currentPageIndex],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        if (widget.pageImages.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentPageIndex > 0
                      ? () {
                          setState(() {
                            _currentPageIndex--;
                          });
                        }
                      : null,
                ),
                Text('${_currentPageIndex + 1} / ${widget.pageImages.length}'),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _currentPageIndex < widget.pageImages.length - 1
                      ? () {
                          setState(() {
                            _currentPageIndex++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '打印预览',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 左侧打印设置
                  Expanded(
                    flex: 3,
                    child: PdfPreview(
                      maxPageWidth: 300,
                      build: (format) => _generatePdf(format),
                      canChangePageFormat: true,
                      canChangeOrientation: true,
                      allowPrinting: true,
                      allowSharing: false,
                      canDebug: false,
                      pdfFileName: '${widget.documentName}.pdf',
                      previewPageMargin: const EdgeInsets.all(8),
                      actions: [
                        PdfPreviewAction(
                          icon: const Icon(Icons.print),
                          onPressed: (context, build, format) async {
                            await Printing.layoutPdf(
                              onLayout: (format) => build(format),
                              name: widget.documentName,
                              format: format,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(),
                  // 右侧预览
                  Expanded(
                    flex: 4,
                    child: _buildPagePreview(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
