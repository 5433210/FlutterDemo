import 'package:flutter/material.dart';

/// 导出进度对话框
class ExportProgressDialog extends StatelessWidget {
  /// 当前进度
  final int current;
  
  /// 总进度
  final int total;
  
  /// 导出类型
  final String exportType;
  
  /// 构造函数
  const ExportProgressDialog({
    Key? key,
    required this.current,
    required this.total,
    required this.exportType,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;
    final percentage = (progress * 100).toInt();
    
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '正在导出',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('正在导出为 $exportType...'),
            const SizedBox(height: 8),
            Text('$current / $total 页'),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('$percentage%'),
            const SizedBox(height: 16),
            const Text('请稍候，导出完成后将自动关闭'),
          ],
        ),
      ),
    );
  }
}
