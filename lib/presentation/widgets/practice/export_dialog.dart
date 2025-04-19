import 'package:flutter/material.dart';

/// 导出对话框
class ExportDialog extends StatefulWidget {
  const ExportDialog({Key? key}) : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  // 导出格式
  String _format = 'PDF';
  
  // 页面范围
  String _pageRange = 'all';
  
  // 自定义页面范围
  final TextEditingController _customRangeController = TextEditingController();
  
  // 导出质量
  String _quality = 'high';
  
  // 是否包含背景
  bool _includeBackground = true;
  
  @override
  void dispose() {
    _customRangeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出字帖'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 导出格式
              const Text('导出格式:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['PDF', 'PNG', 'JPG'].map((format) {
                  return ChoiceChip(
                    label: Text(format),
                    selected: _format == format,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _format = format;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // 页面范围
              const Text('页面范围:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('所有页面'),
                value: 'all',
                groupValue: _pageRange,
                onChanged: (value) {
                  setState(() {
                    _pageRange = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('当前页面'),
                value: 'current',
                groupValue: _pageRange,
                onChanged: (value) {
                  setState(() {
                    _pageRange = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('自定义范围'),
                value: 'custom',
                groupValue: _pageRange,
                onChanged: (value) {
                  setState(() {
                    _pageRange = value!;
                  });
                },
              ),
              if (_pageRange == 'custom')
                Padding(
                  padding: const EdgeInsets.only(left: 32, right: 16),
                  child: TextField(
                    controller: _customRangeController,
                    decoration: const InputDecoration(
                      hintText: '例如: 1-3, 5, 7-9',
                      helperText: '页码从1开始',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              
              // 导出质量
              const Text('导出质量:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('低'),
                    selected: _quality == 'low',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _quality = 'low';
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('中'),
                    selected: _quality == 'medium',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _quality = 'medium';
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('高'),
                    selected: _quality == 'high',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _quality = 'high';
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 其他选项
              const Text('其他选项:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('包含背景'),
                value: _includeBackground,
                onChanged: (value) {
                  setState(() {
                    _includeBackground = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            // 处理自定义范围
            String finalPageRange = _pageRange;
            if (_pageRange == 'custom' && _customRangeController.text.isNotEmpty) {
              finalPageRange = _customRangeController.text;
            }
            
            Navigator.pop(context, {
              'format': _format,
              'pageRange': finalPageRange,
              'quality': _quality,
              'includeBackground': _includeBackground,
            });
          },
          child: const Text('导出'),
        ),
      ],
    );
  }
}
