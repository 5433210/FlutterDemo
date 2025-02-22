import 'package:flutter/material.dart';

class ExportDialog extends StatelessWidget {
  final int workId;

  const ExportDialog({super.key, required this.workId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('导出作品', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '文件名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '导出格式',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                DropdownMenuItem(value: 'jpg', child: Text('JPG')),
                DropdownMenuItem(value: 'png', child: Text('PNG')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: 实现导出逻辑
                    Navigator.pop(context);
                  },
                  child: const Text('导出'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
