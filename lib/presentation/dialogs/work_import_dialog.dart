import 'package:flutter/material.dart';

class WorkImportDialog extends StatefulWidget {
  const WorkImportDialog({Key? key}) : super(key: key);

  @override
  State<WorkImportDialog> createState() => _WorkImportDialogState();
}

class _WorkImportDialogState extends State<WorkImportDialog> {
  final List<String> _images = []; // 临时，实际应该是图片文件列表
  int _selectedImageIndex = 0;

  Widget _buildImageList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 工具栏
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  // TODO: 实现添加图片
                },
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('添加图片'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() => _images.clear());
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('清空'),
              ),
            ],
          ),
        ),
        // 图片列表
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: _images.isEmpty ? 1 : _images.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (_images.isEmpty) {
                return const Center(
                  child: Text('拖放图片到此处或点击"添加图片"按钮'),
                );
              }
              
              final isSelected = index == _selectedImageIndex;
              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey[200],
                  child: Center(child: Text('图片 ${index + 1}')),
                ),
                title: Text('图片 ${index + 1}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() => _images.removeAt(index));
                  },
                ),
                selected: isSelected,
                onTap: () => setState(() => _selectedImageIndex = index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewArea() {
    return Column(
      children: [
        // 工具栏
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {},
                tooltip: '放大',
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {},
                tooltip: '缩小',
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right),
                onPressed: () {},
                tooltip: '旋转',
              ),
              IconButton(
                icon: const Icon(Icons.crop),
                onPressed: () {},
                tooltip: '裁剪',
              ),
            ],
          ),
        ),
        // 预览区
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: const Center(
              child: Text('图片预览区域\n\n点击或拖放图片到此处'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本信息表单
          const TextField(
            decoration: InputDecoration(
              labelText: '作品名称 *',
              hintText: '请输入作品名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: '创作者',
              hintText: '请输入创作者姓名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          // 创作时间选择
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              // TODO: 处理选择的日期
            },
            child: const InputDecorator(
              decoration: InputDecoration(
                labelText: '创作时间',
                border: OutlineInputBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('选择日期'),
                  Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 书法风格选择
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '书法风格',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'kai', child: Text('楷书')),
              DropdownMenuItem(value: 'xing', child: Text('行书')),
              DropdownMenuItem(value: 'cao', child: Text('草书')),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          // 书写工具选择
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '书写工具',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'brush', child: Text('毛笔')),
              DropdownMenuItem(value: 'pen', child: Text('硬笔')),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          // 备注
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '备注',
              hintText: '请输入备注信息',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          // 导入选项
          const Text('导入选项', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('自动优化图片质量'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('保存原始图片副本'),
            value: true,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 1200,
        height: 800,
        child: Column(
          children: [
            // 标题栏
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  const Text('导入书法作品', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 内容区
            Expanded(
              child: Row(
                children: [
                  // 左侧图片列表 (30%)
                  SizedBox(
                    width: 300,
                    child: _buildImageList(),
                  ),
                  const VerticalDivider(width: 1),
                  // 中部预览区 (40%)
                  Expanded(
                    flex: 4,
                    child: _buildPreviewArea(),
                  ),
                  const VerticalDivider(width: 1),
                  // 右侧信息面板 (30%)
                  SizedBox(
                    width: 300,
                    child: _buildInfoPanel(),
                  ),
                ],
              ),
            ),
            // 底部按钮
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _images.isEmpty ? null : () {
                      // TODO: 处理导入逻辑
                    },
                    child: const Text('导入'),
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
