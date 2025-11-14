import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../l10n/app_localizations.dart';
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

  /// 是否自动检测页面方向
  bool _autoDetectOrientation = true;

  /// 页面边距 (上, 右, 下, 左) 以厘米为单位
  final List<double> _margins = [0.0, 0.0, 0.0, 0.0];

  /// 🔧 边距输入框控制器 (上, 右, 下, 左)
  late List<TextEditingController> _marginControllers;

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
    final l10n = AppLocalizations.of(context);

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter && !_isExporting) {
            _exportFile();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        }
      },
      child: AlertDialog(
        title: Text(l10n.export),
        content: SizedBox(
          width: 800,
          height: 550,
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
                            l10n.multipleFilesNote(widget.pageCount),
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
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: _isExporting ? null : _exportFile,
            child: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.export),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _pageRangeController.dispose();
    
    // 🔧 释放边距输入框控制器
    for (final controller in _marginControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.defaultFileName);
    _pageRangeController = TextEditingController(text: '1-${widget.pageCount}');
    
    // 🔧 初始化边距输入框控制器
    _marginControllers = List.generate(4, (index) => 
      TextEditingController(text: _margins[index].toStringAsFixed(1)));
    
    _initDefaultPath();

    // 使用延迟任务生成预览，避免在构建过程中触发setState
    if (widget.controller != null) {
      Future.microtask(() {
        // 如果启用自动检测方向，先进行初始方向检测
        if (_autoDetectOrientation) {
          _updateOrientation();
        }
        _generatePreview();
      });
    }
  }

  /// 构建导出类型选择器
  Widget _buildExportTypeSelector() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.exportType}:',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.fileName}:',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.fitMode}:',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<PdfFitPolicy>(
                title: Text(l10n.fitWidth),
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
                title: Text(l10n.fitHeight),
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
          title: Text(l10n.fitContain),
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
    // 🔧 使用类级别的控制器，确保状态正确维护
    final controller = _marginControllers[index];

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
      mainAxisSize: MainAxisSize.min,
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
                  // 🔧 移除suffixText，因为标题中已经标注了单位 (cm)
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
              mainAxisSize: MainAxisSize.min,
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
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.pageMargins}:',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMarginInput(l10n.marginTop, 0),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMarginInput(l10n.marginRight, 1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMarginInput(l10n.marginBottom, 2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMarginInput(l10n.marginLeft, 3),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建页面朝向选择器 (PDF专用)
  Widget _buildOrientationSelector() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.pageOrientation}:',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // 自动检测选项
        CheckboxListTile(
          title: Row(
            children: [
              const Icon(Icons.auto_fix_high),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).autoDetectPageOrientation),
            ],
          ),
          value: _autoDetectOrientation,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: (value) {
            setState(() {
              _autoDetectOrientation = value!;
              if (_autoDetectOrientation) {
                // 立即检测并更新方向
                _updateOrientation();
              }
            });
            _generatePreview();
          },
        ),
        const SizedBox(height: 8), // 手动方向选择（当自动检测关闭时可用）
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: Row(
                  children: [
                    const Icon(Icons.stay_current_portrait),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.portrait,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                value: false,
                groupValue: _isLandscape,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: _autoDetectOrientation
                    ? null
                    : (value) {
                        setState(() {
                          _isLandscape = value!;
                        });
                        _generatePreview();
                      },
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: Row(
                  children: [
                    const Icon(Icons.stay_current_landscape),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.landscape,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                value: true,
                groupValue: _isLandscape,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: _autoDetectOrientation
                    ? null
                    : (value) {
                        setState(() {
                          _isLandscape = value!;
                        });
                        _generatePreview();
                      },
              ),
            ),
          ],
        ),
        // 显示检测到的方向信息
        if (_autoDetectOrientation)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.autoDetect}: ${_isLandscape ? l10n.landscape : l10n.portrait}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 构建导出路径选择器
  Widget _buildOutputPathSelector() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.location}:',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  _outputPath ?? l10n.selectExportLocation,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _selectDirectory,
              child: Text(l10n.browse),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建页面范围选择器 (PDF专用)
  Widget _buildPageRangeSelector() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.pageRange}:',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<PageRangeType>(
                title: Text(l10n.allPages),
                value: PageRangeType.all,
                groupValue: _pageRangeType,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (value) {
                  setState(() {
                    _pageRangeType = value!;
                  });
                  // 当切换页面范围模式时，如果启用自动检测方向，需要重新检测
                  if (_autoDetectOrientation) {
                    _updateOrientation();
                  }
                  _generatePreview();
                },
              ),
            ),
            Expanded(
              child: RadioListTile<PageRangeType>(
                title: Text(l10n.currentPage),
                value: PageRangeType.current,
                groupValue: _pageRangeType,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (value) {
                  setState(() {
                    _pageRangeType = value!;
                  });
                  // 当切换到当前页模式时，如果启用自动检测方向，需要立即检测
                  if (_pageRangeType == PageRangeType.current &&
                      _autoDetectOrientation) {
                    _updateOrientation();
                  }
                  _generatePreview();
                },
              ),
            ),
          ],
        ),
        RadioListTile<PageRangeType>(
          title: Row(
            children: [
              Text('${l10n.customRange} '),
              Expanded(
                child: TextField(
                  controller: _pageRangeController,
                  decoration: InputDecoration(
                    hintText: l10n.exportDialogRangeExample,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
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
            // 当切换到自定义范围模式时，如果启用自动检测方向，需要重新检测当前预览页面
            if (_autoDetectOrientation) {
              _updateOrientation();
            }
            _generatePreview();
          },
        ),
      ],
    );
  }

  /// 构建页面大小选择器 (PDF专用)
  Widget _buildPageSizeSelector() {
    final l10n = AppLocalizations.of(context);
    final pageFormatMap = {
      'A3': PdfPageFormat.a3,
      'A4': PdfPageFormat.a4,
      'A5': PdfPageFormat.a5,
      'A6': PdfPageFormat.a6,
      'Letter': PdfPageFormat.letter,
      'Legal': PdfPageFormat.legal,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.pageSize}:',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                '${entry.key} (${widthCm.toStringAsFixed(1)} × ${heightCm.toStringAsFixed(1)} ${l10n.centimeter})',
                overflow: TextOverflow.ellipsis,
              ),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.outputQuality}:',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.preview,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (widget.pageCount > 1 && _pagePreviewCache.isNotEmpty)
                Text(
                  l10n.previewPage(
                    _previewPageIndex + 1,
                    widget.pageCount,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 350, // 给预览区域一个固定高度，替代Expanded
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
                    : Center(
                        child: Text(l10n.canNotPreview),
                      ),
          ),
          const SizedBox(height: 8),
          if (_exportType == ExportType.pdf)
            Center(
              child: Text(
                l10n.exportDimensions(
                  _getEffectivePageFormat().width / PdfPageFormat.cm,
                  _getEffectivePageFormat().height / PdfPageFormat.cm,
                  _isLandscape ? l10n.landscape : l10n.portrait,
                ),
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
                    tooltip: l10n.previousPage,
                    onPressed: _previewPageIndex > 0
                        ? () => _switchPreviewPage(_previewPageIndex - 1)
                        : null,
                  ),
                  Text('${_previewPageIndex + 1} / ${widget.pageCount}'),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: l10n.nextPage,
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

  Map<int, bool> _collectPageOrientationOverrides() {
    if (widget.controller == null) {
      return {};
    }

    final pages = widget.controller!.state.pages;
    final Map<int, bool> orientationMap = {};

    for (int i = 0; i < pages.length; i++) {
      orientationMap[i] = _detectPageOrientation(i);
    }

    return orientationMap;
  }

  /// 检测当前页面的方向
  bool _detectPageOrientation(int pageIndex) {
    if (widget.controller == null) {
      return false; // 默认为portrait
    }

    try {
      final pages = widget.controller!.state.pages;
      if (pageIndex < 0 || pageIndex >= pages.length) {
        return false; // 默认为portrait
      }

      final page = pages[pageIndex];

      // 首先检查是否有orientation属性
      if (page.containsKey('orientation')) {
        final orientation = page['orientation'] as String?;
        if (orientation != null && orientation.isNotEmpty) {
          return orientation.toLowerCase() == 'landscape';
        }
      }

      // 如果没有orientation属性，通过width和height判断
      final width = (page['width'] as num?)?.toDouble() ?? 210.0;
      final height = (page['height'] as num?)?.toDouble() ?? 297.0;

      // 如果宽度大于高度，认为是横向
      return width > height;
    } catch (e) {
      EditPageLogger.rendererError(
        '检测页面方向失败',
        error: e,
        data: {
          'pageIndex': pageIndex,
          'operation': '_detectPageOrientation',
        },
      );
      return false; // 默认为portrait
    }
  }

  /// 导出文件
  void _exportFile() {
    final l10n = AppLocalizations.of(context);
    debugPrint('ExportDialog: 开始导出文件');

    if (_outputPath == null) {
      debugPrint('ExportDialog: 错误 - 未选择导出位置');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectExportLocation)),
      );
      return;
    }

    final fileName = _fileNameController.text.trim();
    debugPrint('ExportDialog: 用户输入的文件名: "$fileName"');

    if (fileName.isEmpty) {
      debugPrint('ExportDialog: 错误 - 文件名为空');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inputFileName)),
      );
      return;
    }

    // 检查文件名是否包含非法字符
    final RegExp invalidChars = RegExp(r'[\\/:*?"<>|]');
    if (invalidChars.hasMatch(fileName)) {
      debugPrint('ExportDialog: 错误 - 文件名包含非法字符');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidFilename)),
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
          SnackBar(content: Text('${l10n.createExportDirectoryFailed}: $e')),
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
      extraParams['basePageFormat'] = _pageFormat;
      extraParams['isLandscape'] = _isLandscape;
      extraParams['autoDetectOrientation'] = _autoDetectOrientation;

      if (_autoDetectOrientation && widget.controller != null) {
        extraParams['pageOrientationOverrides'] =
            _collectPageOrientationOverrides();
      }
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

  Future<void> _generatePreview() async {
    // 只有在有控制器的情况下才能生成预览
    if (widget.controller == null) {
      return;
    }

    // 如果启用自动检测方向，先更新方向
    if (_autoDetectOrientation) {
      _updateOrientation();
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

  /// 检测当前页面的方向

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
    final l10n = AppLocalizations.of(context);
    if (_exportType == ExportType.pdf || widget.pageCount <= 1) {
      return l10n.inputFileName;
    } else {
      return l10n.filenamePrefix;
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
    final l10n = AppLocalizations.of(context);
    if (_pixelRatio == 1.0) {
      return l10n.qualityStandard;
    } else if (_pixelRatio == 2.0) {
      return l10n.qualityHigh;
    } else {
      return l10n.qualityUltra;
    }
  }

  /// 初始化默认路径
  Future<void> _initDefaultPath() async {
    try {
      debugPrint('ExportDialog: 开始初始化默认导出路径');

      Directory? directory;
      try {
        directory = await getDownloadsDirectory();
      } catch (e) {
        debugPrint('ExportDialog: 获取Downloads目录失败: $e');
        // 在测试环境或不支持的平台上，使用Documents目录
        try {
          directory = await getApplicationDocumentsDirectory();
        } catch (e2) {
          debugPrint('ExportDialog: 获取Documents目录也失败: $e2');
          // 最后尝试使用临时目录
          try {
            directory = await getTemporaryDirectory();
          } catch (e3) {
            debugPrint('ExportDialog: 获取临时目录也失败: $e3');
            // 如果所有路径都获取失败，设置为null让用户手动选择
            directory = null;
          }
        }
      }

      if (directory == null) {
        debugPrint('ExportDialog: 无法获取任何默认路径，用户需要手动选择');
        return;
      }

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

      if (mounted) {
        setState(() {
          _outputPath = directory!.path;
        });
      }
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
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .createExportDirectoryFailed(e.toString()))),
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

    // 如果启用自动检测方向，在切换页面时更新方向
    if (_autoDetectOrientation) {
      _updateOrientation();
    }

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

  /// 更新页面方向设置
  void _updateOrientation() {
    if (!_autoDetectOrientation) {
      return;
    }

    int targetPageIndex = _previewPageIndex;

    // 如果是当前页模式，使用指定的当前页
    if (_pageRangeType == PageRangeType.current) {
      targetPageIndex = widget.currentPageIndex;
    }

    final shouldBeLandscape = _detectPageOrientation(targetPageIndex);

    if (_isLandscape != shouldBeLandscape) {
      EditPageLogger.rendererDebug(
        '自动调整页面方向',
        data: {
          'pageIndex': targetPageIndex,
          'detectedOrientation': shouldBeLandscape ? 'landscape' : 'portrait',
          'previousOrientation': _isLandscape ? 'landscape' : 'portrait',
          'operation': '_updateOrientation',
        },
      );

      setState(() {
        _isLandscape = shouldBeLandscape;
      });
    }
  }
}
