import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';

import '../practice_edit_controller.dart';
import 'export_service.dart';
import 'page_renderer.dart';

/// 导出对话框
class ExportDialog extends StatefulWidget {
  /// 页面数量
  final int pageCount;

  /// 默认文件名
  final String defaultFileName;

  /// 当前页面索引
  final int currentPageIndex;

  /// 页面控制器
  final PracticeEditController? controller;

  /// 导出回调
  final Function(String outputPath, ExportType exportType, String fileName,
      double pixelRatio, Map<String, dynamic> extraParams) onExport;

  const ExportDialog({
    Key? key,
    required this.pageCount,
    required this.defaultFileName,
    this.currentPageIndex = 0,
    this.controller,
    required this.onExport,
  }) : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

/// 页面范围类型
enum PageRangeType {
  /// 全部页面
  all,

  /// 当前页面
  current,

  /// 自定义范围
  custom,
}

/// PDF适配策略
enum PdfFitPolicy {
  /// 适合宽度
  width,

  /// 适合高度
  height,

  /// 包含在页面内
  contain,
}

class _ExportDialogState extends State<ExportDialog> {
  /// 导出类型
  ExportType _exportType = ExportType.pdf;

  /// 导出路径
  String? _outputPath;

  /// 文件名控制器
  late TextEditingController _fileNameController;

  /// 是否正在导出
  bool _isExporting = false;

  /// 像素比例
  double _pixelRatio = 1.0;

  /// 页面范围类型
  PageRangeType _pageRangeType = PageRangeType.all;

  /// 页面范围输入控制器
  late TextEditingController _pageRangeController;

  /// 页面大小
  PdfPageFormat _pageFormat = PdfPageFormat.a4;

  /// 页面朝向
  bool _isLandscape = false;

  /// 页面边距 (上, 右, 下, 左) 以厘米为单位
  final List<double> _margins = [0.0, 0.0, 0.0, 0.0];

  /// 适配方式
  PdfFitPolicy _fitPolicy = PdfFitPolicy.width;

  /// 页面预览图
  Uint8List? _previewImage;

  /// 正在加载预览
  bool _isLoadingPreview = false;

  /// 当前预览的页面索引
  int _previewPageIndex = 0;

  /// 所有页面的预览图
  final Map<int, Uint8List> _pagePreviewCache = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出字帖'),
      content: SizedBox(
        width: 800,
        height: 600,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左侧设置区域
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExportTypeSelector(),
                    const SizedBox(height: 16),
                    _buildFileNameInput(),
                    const SizedBox(height: 16),
                    _buildPixelRatioSelector(),
                    const SizedBox(height: 16),
                    _buildOutputPathSelector(),
                    const SizedBox(height: 16),

                    // PDF特有的设置
                    if (_exportType == ExportType.pdf) ...[
                      _buildPageRangeSelector(),
                      const SizedBox(height: 16),
                      _buildPageSizeSelector(),
                      const SizedBox(height: 16),
                      _buildOrientationSelector(),
                      const SizedBox(height: 16),
                      _buildFitPolicySelector(),
                      const SizedBox(height: 16),
                      _buildMarginsInput(),
                    ],

                    if (widget.pageCount > 1 && _exportType != ExportType.pdf)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          '注意: 将导出 ${widget.pageCount} 个图片文件，文件名将自动添加页码。',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 右侧预览区域
            Expanded(
              flex: 5,
              child: _buildPreviewArea(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _exportFile,
          child: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('导出'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _pageRangeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.defaultFileName);
    _pageRangeController = TextEditingController(text: '1-${widget.pageCount}');
    _initDefaultPath();

    // 使用延迟任务生成预览，避免在构建过程中触发setState
    if (widget.controller != null) {
      Future.microtask(() => _generatePreview());
    }
  }

  /// 构建导出类型选择器
  Widget _buildExportTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('导出格式:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ExportType.values.map((type) {
            return ChoiceChip(
              label: Text(type.name),
              selected: _exportType == type,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _exportType = type;
                  });
                  _generatePreview();
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建文件名输入框
  Widget _buildFileNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('文件名:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _fileNameController,
          decoration: InputDecoration(
            hintText: _getFileNameHint(),
            border: const OutlineInputBorder(),
            suffixText: _exportType == ExportType.pdf
                ? '.pdf'
                : (_exportType == ExportType.jpg ? '.jpg' : '.png'),
          ),
        ),
      ],
    );
  }

  /// 构建适配方式选择器 (PDF专用)
  Widget _buildFitPolicySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('适配方式:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<PdfFitPolicy>(
                title: const Text('适合宽度'),
                value: PdfFitPolicy.width,
                groupValue: _fitPolicy,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (value) {
                  setState(() {
                    _fitPolicy = value!;
                  });
                  _generatePreview();
                },
              ),
            ),
            Expanded(
              child: RadioListTile<PdfFitPolicy>(
                title: const Text('适合高度'),
                value: PdfFitPolicy.height,
                groupValue: _fitPolicy,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (value) {
                  setState(() {
                    _fitPolicy = value!;
                  });
                  _generatePreview();
                },
              ),
            ),
          ],
        ),
        RadioListTile<PdfFitPolicy>(
          title: const Text('包含在页面内'),
          value: PdfFitPolicy.contain,
          groupValue: _fitPolicy,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: (value) {
            setState(() {
              _fitPolicy = value!;
            });
            _generatePreview();
          },
        ),
      ],
    );
  }

  /// 构建单个边距输入
  Widget _buildMarginInput(String label, int index) {
    // 使用TextEditingController以保持输入框状态
    final controller =
        TextEditingController(text: _margins[index].toStringAsFixed(1));

    // 更新边距值的函数
    void updateMargin(double value) {
      // 确保值不小于0
      final newValue = value < 0 ? 0.0 : value;
      setState(() {
        _margins[index] = newValue;
        // 更新控制器文本，保持一位小数
        controller.text = newValue.toStringAsFixed(1);
        // 将光标移到末尾
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      });
      _generatePreview();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  suffixText: '厘米',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                controller: controller,
                onChanged: (value) {
                  try {
                    final newValue = double.parse(value);
                    if (newValue >= 0) {
                      setState(() {
                        _margins[index] = newValue;
                      });
                      _generatePreview();
                    }
                  } catch (e) {
                    // 忽略无效输入
                  }
                },
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 增加按钮
                IconButton(
                  icon: const Icon(Icons.arrow_drop_up),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                  onPressed: () {
                    // 增加0.1厘米
                    updateMargin(_margins[index] + 0.1);
                  },
                ),
                // 减少按钮
                IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                  onPressed: () {
                    // 减少0.1厘米，但不小于0
                    updateMargin(_margins[index] - 0.1);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 构建边距输入 (PDF专用)
  Widget _buildMarginsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('页面边距 (厘米):', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMarginInput('上', 0),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMarginInput('右', 1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMarginInput('下', 2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMarginInput('左', 3),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建页面朝向选择器 (PDF专用)
  Widget _buildOrientationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('页面朝向:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Row(
                  children: [
                    Icon(Icons.stay_current_portrait),
                    SizedBox(width: 8),
                    Text('纵向'),
                  ],
                ),
                value: false,
                groupValue: _isLandscape,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (value) {
                  setState(() {
                    _isLandscape = value!;
                  });
                  _generatePreview();
                },
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Row(
                  children: [
                    Icon(Icons.stay_current_landscape),
                    SizedBox(width: 8),
                    Text('横向'),
                  ],
                ),
                value: true,
                groupValue: _isLandscape,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (value) {
                  setState(() {
                    _isLandscape = value!;
                  });
                  _generatePreview();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建导出路径选择器
  Widget _buildOutputPathSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('导出位置:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _outputPath ?? '请选择导出位置',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _selectDirectory,
              child: const Text('浏览...'),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建页面范围选择器 (PDF专用)
  Widget _buildPageRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('页面范围:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<PageRangeType>(
                title: const Text('全部页面'),
                value: PageRangeType.all,
                groupValue: _pageRangeType,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (value) {
                  setState(() {
                    _pageRangeType = value!;
                  });
                  _generatePreview();
                },
              ),
            ),
            Expanded(
              child: RadioListTile<PageRangeType>(
                title: const Text('当前页面'),
                value: PageRangeType.current,
                groupValue: _pageRangeType,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (value) {
                  setState(() {
                    _pageRangeType = value!;
                  });
                  _generatePreview();
                },
              ),
            ),
          ],
        ),
        RadioListTile<PageRangeType>(
          title: Row(
            children: [
              const Text('自定义范围 '),
              Expanded(
                child: TextField(
                  controller: _pageRangeController,
                  decoration: const InputDecoration(
                    hintText: '例如: 1-3,5,7-9',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  enabled: _pageRangeType == PageRangeType.custom,
                  onChanged: (_) => _generatePreview(),
                ),
              ),
            ],
          ),
          value: PageRangeType.custom,
          groupValue: _pageRangeType,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: (value) {
            setState(() {
              _pageRangeType = value!;
            });
            _generatePreview();
          },
        ),
      ],
    );
  }

  /// 构建页面大小选择器 (PDF专用)
  Widget _buildPageSizeSelector() {
    final pageFormatMap = {
      'A3': PdfPageFormat.a3,
      'A4': PdfPageFormat.a4,
      'A5': PdfPageFormat.a5,
      'A6': PdfPageFormat.a6,
      'Letter': PdfPageFormat.letter,
      'Legal': PdfPageFormat.legal,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('页面大小:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<PdfPageFormat>(
          value: _pageFormat,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: pageFormatMap.entries.map((entry) {
            final double widthCm = entry.value.width / PdfPageFormat.cm;
            final double heightCm = entry.value.height / PdfPageFormat.cm;
            return DropdownMenuItem<PdfPageFormat>(
              value: entry.value,
              child: Text(
                  '${entry.key} (${widthCm.toStringAsFixed(1)} × ${heightCm.toStringAsFixed(1)} 厘米)'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _pageFormat = value;
              });
              _generatePreview();
            }
          },
        ),
      ],
    );
  }

  /// 构建像素比例选择器
  Widget _buildPixelRatioSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('输出质量:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _pixelRatio,
                min: 1.0,
                max: 3.0,
                divisions: 2,
                label: _getPixelRatioLabel(),
                onChanged: (value) {
                  setState(() {
                    _pixelRatio = value;
                  });
                  _generatePreview();
                },
              ),
            ),
            Text(_getPixelRatioLabel()),
          ],
        ),
      ],
    );
  }

  /// 构建预览区域
  Widget _buildPreviewArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '预览',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (widget.pageCount > 1 && _pagePreviewCache.isNotEmpty)
                Text(
                  ' (第 ${_previewPageIndex + 1}/${widget.pageCount} 页)',
                  style: const TextStyle(fontSize: 14),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingPreview
                ? const Center(child: CircularProgressIndicator())
                : _previewImage != null
                    ? Center(
                        child: _exportType == ExportType.pdf
                            ? AspectRatio(
                                aspectRatio: _getEffectivePageFormat().width /
                                    _getEffectivePageFormat().height,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withAlpha(128),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      _margins[3] * 10,
                                      _margins[0] * 10,
                                      _margins[1] * 10,
                                      _margins[2] * 10,
                                    ),
                                    child: Image.memory(
                                      _previewImage!,
                                      fit: _getFitFromPolicy(),
                                    ),
                                  ),
                                ),
                              )
                            : Image.memory(
                                _previewImage!,
                                fit: BoxFit.contain,
                              ),
                      )
                    : const Center(
                        child: Text('无法生成预览'),
                      ),
          ),
          const SizedBox(height: 8),
          if (_exportType == ExportType.pdf)
            Center(
              child: Text(
                '${_getEffectivePageFormat().width / PdfPageFormat.cm}厘米 × '
                '${_getEffectivePageFormat().height / PdfPageFormat.cm}厘米 '
                '(${_isLandscape ? "横向" : "纵向"})',
                style: const TextStyle(fontSize: 12),
              ),
            ),

          // 页面导航控件（仅当有多个页面时显示）
          if (widget.pageCount > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '上一页',
                    onPressed: _previewPageIndex > 0
                        ? () => _switchPreviewPage(_previewPageIndex - 1)
                        : null,
                  ),
                  Text('${_previewPageIndex + 1} / ${widget.pageCount}'),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: '下一页',
                    onPressed: _previewPageIndex < widget.pageCount - 1
                        ? () => _switchPreviewPage(_previewPageIndex + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 导出文件
  void _exportFile() {
    debugPrint('ExportDialog: 开始导出文件');

    if (_outputPath == null) {
      debugPrint('ExportDialog: 错误 - 未选择导出位置');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择导出位置')),
      );
      return;
    }

    final fileName = _fileNameController.text.trim();
    debugPrint('ExportDialog: 用户输入的文件名: "$fileName"');

    if (fileName.isEmpty) {
      debugPrint('ExportDialog: 错误 - 文件名为空');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入文件名')),
      );
      return;
    }

    // 检查文件名是否包含非法字符
    final RegExp invalidChars = RegExp(r'[\\/:*?"<>|]');
    if (invalidChars.hasMatch(fileName)) {
      debugPrint('ExportDialog: 错误 - 文件名包含非法字符');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文件名不能包含以下字符: \\ / : * ? " < > |')),
      );
      return;
    }

    // 检查目录是否存在
    final directory = Directory(_outputPath!);
    if (!directory.existsSync()) {
      debugPrint('ExportDialog: 导出目录不存在，尝试创建: $_outputPath');
      try {
        directory.createSync(recursive: true);
        debugPrint('ExportDialog: 成功创建导出目录');
      } catch (e) {
        debugPrint('ExportDialog: 创建导出目录失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建导出目录失败: $e')),
        );
        return;
      }
    }

    setState(() {
      _isExporting = true;
    });

    // 构建额外参数
    final extraParams = <String, dynamic>{};

    if (_exportType == ExportType.pdf) {
      // 为PDF添加特定参数
      final pageFormat = _getEffectivePageFormat();

      extraParams['pageFormat'] = pageFormat;
      extraParams['pageRangeType'] = _pageRangeType;

      if (_pageRangeType == PageRangeType.current) {
        extraParams['currentPage'] = widget.currentPageIndex;
      } else if (_pageRangeType == PageRangeType.custom) {
        extraParams['pageRange'] = _pageRangeController.text;
      }

      extraParams['margins'] = _margins;
      extraParams['fitPolicy'] = _fitPolicy;
    }

    debugPrint(
        'ExportDialog: 调用导出回调, 路径=$_outputPath, 类型=${_exportType.name}, 文件名=$fileName, 像素比例=$_pixelRatio, 额外参数=$extraParams');

    // 调用导出回调并获取返回值
    final result = widget.onExport(
        _outputPath!, _exportType, fileName, _pixelRatio, extraParams);

    debugPrint('ExportDialog: 导出回调返回值: $result');
    debugPrint('ExportDialog: 关闭导出对话框并返回结果');

    // 关闭对话框并返回结果
    Navigator.of(context).pop(result);
  }

  /// 生成预览图像
  Future<void> _generatePreview() async {
    // 只有在有控制器的情况下才能生成预览
    if (widget.controller == null) {
      return;
    }

    setState(() {
      _isLoadingPreview = true;
    });

    try {
      // 创建页面渲染器
      final pageRenderer = PageRenderer(widget.controller!);

      // 确定需要渲染的页面索引
      int pageIndex = _previewPageIndex;

      // 如果是当前页模式，使用指定的当前页
      if (_pageRangeType == PageRangeType.current) {
        pageIndex = widget.currentPageIndex;
        // 同时更新预览页面索引
        _previewPageIndex = pageIndex;
      }

      // 检查缓存中是否已有该页面的预览图
      if (_pagePreviewCache.containsKey(pageIndex)) {
        setState(() {
          _previewImage = _pagePreviewCache[pageIndex];
          _isLoadingPreview = false;
        });
        return;
      }

      // 渲染单个页面作为预览
      final pageImage = await pageRenderer.renderSinglePage(
        pageIndex,
        pixelRatio: _pixelRatio,
      );

      if (pageImage != null) {
        // 将预览图添加到缓存
        _pagePreviewCache[pageIndex] = pageImage;

        setState(() {
          _previewImage = pageImage;
          _isLoadingPreview = false;
        });
      } else {
        setState(() {
          _previewImage = null;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      debugPrint('预览生成失败: $e');
      setState(() {
        _previewImage = null;
        _isLoadingPreview = false;
      });
    }
  }

  /// 获取有效的页面格式 (考虑朝向)
  PdfPageFormat _getEffectivePageFormat() {
    if (_isLandscape) {
      return _pageFormat.landscape;
    } else {
      return _pageFormat.portrait;
    }
  }

  /// 获取文件名提示
  String _getFileNameHint() {
    if (_exportType == ExportType.pdf || widget.pageCount <= 1) {
      return '输入文件名';
    } else {
      return '输入文件名前缀（将自动添加页码）';
    }
  }

  /// 获取适合方式
  BoxFit _getFitFromPolicy() {
    switch (_fitPolicy) {
      case PdfFitPolicy.width:
        return BoxFit.fitWidth;
      case PdfFitPolicy.height:
        return BoxFit.fitHeight;
      case PdfFitPolicy.contain:
        return BoxFit.contain;
    }
  }

  /// 获取像素比例标签
  String _getPixelRatioLabel() {
    if (_pixelRatio == 1.0) {
      return '标准 (1x)';
    } else if (_pixelRatio == 2.0) {
      return '高清 (2x)';
    } else {
      return '超清 (3x)';
    }
  }

  /// 初始化默认路径
  Future<void> _initDefaultPath() async {
    try {
      debugPrint('ExportDialog: 开始初始化默认导出路径');
      final directory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      debugPrint('ExportDialog: 获取到默认路径: ${directory.path}');

      // 检查目录是否存在
      final exists = await Directory(directory.path).exists();
      debugPrint('ExportDialog: 目录是否存在: $exists');

      // 检查目录权限
      try {
        final testFile = File('${directory.path}/export_test.txt');
        await testFile.writeAsString('test');
        debugPrint('ExportDialog: 目录写入权限测试成功');
        await testFile.delete();
        debugPrint('ExportDialog: 测试文件已删除');
      } catch (e) {
        debugPrint('ExportDialog: 目录写入权限测试失败: $e');
      }

      setState(() {
        _outputPath = directory.path;
      });
    } catch (e, stack) {
      debugPrint('ExportDialog: 获取默认路径失败: $e');
      debugPrint('ExportDialog: 堆栈跟踪: $stack');
    }
  }

  /// 选择导出目录
  Future<void> _selectDirectory() async {
    try {
      debugPrint('ExportDialog: 开始选择导出目录');
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      debugPrint('ExportDialog: 用户选择的目录: $selectedDirectory');

      if (selectedDirectory != null) {
        // 检查目录是否存在
        final exists = await Directory(selectedDirectory).exists();
        debugPrint('ExportDialog: 选择的目录是否存在: $exists');

        // 检查目录权限
        try {
          final testFile = File('$selectedDirectory/export_test.txt');
          await testFile.writeAsString('test');
          debugPrint('ExportDialog: 选择的目录写入权限测试成功');
          await testFile.delete();
          debugPrint('ExportDialog: 测试文件已删除');
        } catch (e) {
          debugPrint('ExportDialog: 选择的目录写入权限测试失败: $e');
        }

        setState(() {
          _outputPath = selectedDirectory;
        });
      } else {
        debugPrint('ExportDialog: 用户取消了目录选择');
      }
    } catch (e, stack) {
      debugPrint('ExportDialog: 选择目录失败: $e');
      debugPrint('ExportDialog: 堆栈跟踪: $stack');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择目录失败: $e')),
        );
      }
    }
  }

  /// 切换预览页面
  void _switchPreviewPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= widget.pageCount) return;

    setState(() {
      _previewPageIndex = pageIndex;

      // 如果当前是"当前页"模式，切换页面时保持该模式
      if (_pageRangeType == PageRangeType.current) {
        // 不需要更改模式，但需要更新当前页索引
      }
      // 如果是自定义范围模式，保持不变
      else if (_pageRangeType == PageRangeType.custom) {
        // 不需要更改模式
      }
      // 如果是全部页面模式，也保持不变
      else {
        // 不需要更改模式
      }
    });

    // 如果缓存中已有该页面的预览图，直接使用
    if (_pagePreviewCache.containsKey(pageIndex)) {
      setState(() {
        _previewImage = _pagePreviewCache[pageIndex];
      });
    } else {
      // 否则重新生成预览
      _generatePreview();
    }
  }
}
