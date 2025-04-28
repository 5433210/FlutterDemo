import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'export_service.dart';

/// 导出对话框
class ExportDialog extends StatefulWidget {
  /// 页面数量
  final int pageCount;

  /// 默认文件名
  final String defaultFileName;

  /// 导出回调
  final Function(String outputPath, ExportType exportType, String fileName,
      double pixelRatio) onExport;

  const ExportDialog({
    Key? key,
    required this.pageCount,
    required this.defaultFileName,
    required this.onExport,
  }) : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出字帖'),
      content: SizedBox(
        width: 500,
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.defaultFileName);
    _initDefaultPath();
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
                },
              ),
            ),
            Text(_getPixelRatioLabel()),
          ],
        ),
      ],
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

    debugPrint(
        'ExportDialog: 调用导出回调, 路径=$_outputPath, 类型=${_exportType.name}, 文件名=$fileName, 像素比例=$_pixelRatio');
    // 调用导出回调并获取返回值
    final result =
        widget.onExport(_outputPath!, _exportType, fileName, _pixelRatio);

    debugPrint('ExportDialog: 导出回调返回值: $result');
    debugPrint('ExportDialog: 关闭导出对话框并返回结果');

    // 关闭对话框并返回结果
    Navigator.of(context).pop(result);
  }

  /// 获取文件名提示
  String _getFileNameHint() {
    if (_exportType == ExportType.pdf || widget.pageCount <= 1) {
      return '输入文件名';
    } else {
      return '输入文件名前缀（将自动添加页码）';
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
}
