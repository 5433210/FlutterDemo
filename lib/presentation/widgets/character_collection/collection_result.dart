import 'package:flutter/material.dart';

class CollectionResult extends StatefulWidget {
  const CollectionResult({super.key});

  @override
  State<CollectionResult> createState() => _CollectionResultState();
}

class _CollectionResultState extends State<CollectionResult> {
  final _formKey = GlobalKey<FormState>();
  final _simplifiedCharController = TextEditingController();
  String _selectedStyle = '楷书';
  String _selectedTool = '毛笔';
  final _remarkController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview section
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('集字效果预览'),
            ),
          ),
          const SizedBox(height: 16),

          // Transform tools
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.rotate_left),
                onPressed: () {
                  // Handle rotation
                },
                tooltip: '向左旋转',
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right),
                onPressed: () {
                  // Handle rotation
                },
                tooltip: '向右旋转',
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  // Handle zoom
                },
                tooltip: '放大',
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  // Handle zoom
                },
                tooltip: '缩小',
              ),
              IconButton(
                icon: const Icon(Icons.color_lens),
                onPressed: () {
                  // Handle color
                },
                tooltip: '字体颜色',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Size info
          Text(
            '当前尺寸：200x200像素',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Registration form
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _simplifiedCharController,
                      decoration: const InputDecoration(
                        labelText: '对应简体字 *',
                        hintText: '输入汉字',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入对应简体字';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStyle,
                      decoration: const InputDecoration(
                        labelText: '书法风格',
                      ),
                      items: ['楷书', '行书', '草书', '隶书', '篆书']
                          .map((style) => DropdownMenuItem(
                                value: style,
                                child: Text(style),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStyle = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTool,
                      decoration: const InputDecoration(
                        labelText: '书写工具',
                      ),
                      items: ['毛笔', '硬笔']
                          .map((tool) => DropdownMenuItem(
                                value: tool,
                                child: Text(tool),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTool = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _remarkController,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        hintText: '可选',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      // Handle save
                    }
                  },
                  child: const Text('保存集字'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  // Handle clear selection
                },
                child: const Text('清空选择'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _simplifiedCharController.dispose();
    _remarkController.dispose();
    super.dispose();
  }
}
