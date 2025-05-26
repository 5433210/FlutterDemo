import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CharacterEditDialog extends StatefulWidget {
  final String charId;

  const CharacterEditDialog({
    super.key,
    required this.charId,
  });

  @override
  State<CharacterEditDialog> createState() => _CharacterEditDialogState();
}

class _CharacterEditDialogState extends State<CharacterEditDialog> {
  late final TextEditingController _simplifiedController;
  late final TextEditingController _traditionalController;
  late final TextEditingController _remarksController;
  String? _style;
  String? _tool;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _handleSave();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('编辑集字信息',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _simplifiedController,
                decoration: const InputDecoration(
                  labelText: '简体字 *',
                  border: OutlineInputBorder(),
                ),
                maxLength: 1,
                onSubmitted: (_) => _handleSave(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _traditionalController,
                decoration: const InputDecoration(
                  labelText: '繁体字',
                  border: OutlineInputBorder(),
                ),
                maxLength: 1,
                onSubmitted: (_) => _handleSave(),
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
                onSubmitted: (_) => _handleSave(),
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
                    onPressed: _handleSave,
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _simplifiedController.dispose();
    _traditionalController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // TODO: 加载实际数据
    _simplifiedController = TextEditingController(text: '永');
    _traditionalController = TextEditingController(text: '永');
    _remarksController = TextEditingController();
    _style = 'kai';
    _tool = 'brush';
  }

  /// 处理保存操作
  void _handleSave() {
    // TODO: 保存编辑
    Navigator.of(context).pop();
  }
}
