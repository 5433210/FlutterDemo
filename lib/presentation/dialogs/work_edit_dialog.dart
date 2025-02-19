import 'package:flutter/material.dart';

class WorkEditDialog extends StatefulWidget {
  final int workId;

  const WorkEditDialog({
    Key? key,
    required this.workId,
  }) : super(key: key);

  @override
  State<WorkEditDialog> createState() => _WorkEditDialogState();
}

class _WorkEditDialogState extends State<WorkEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _authorController;
  late final TextEditingController _remarksController;
  DateTime? _creationDate;
  String? _style;
  String? _tool;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '示例作品'); // TODO: 加载实际数据
    _authorController = TextEditingController(text: '张三');
    _remarksController = TextEditingController();
    _creationDate = DateTime.now();
    _style = 'kai';
    _tool = 'brush';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('编辑作品信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '作品名称 *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: '创作者',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _creationDate ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _creationDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '创作时间',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_creationDate != null 
                      ? '${_creationDate!.year}-${_creationDate!.month}-${_creationDate!.day}'
                      : '选择日期'
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _style,
              decoration: const InputDecoration(
                labelText: '书法风格',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'kai', child: Text('楷书')),
                DropdownMenuItem(value: 'xing', child: Text('行书')),
                DropdownMenuItem(value: 'cao', child: Text('草书')),
              ],
              onChanged: (value) => setState(() => _style = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tool,
              decoration: const InputDecoration(
                labelText: '书写工具',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'brush', child: Text('毛笔')),
                DropdownMenuItem(value: 'pen', child: Text('硬笔')),
              ],
              onChanged: (value) => setState(() => _tool = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: 保存编辑
                    Navigator.of(context).pop();
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}
