import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../providers/work_import_provider.dart';
import '../viewmodels/states/work_import_state.dart';

class WorkImportDialog extends ConsumerStatefulWidget {
  const WorkImportDialog({super.key});

  @override
  ConsumerState<WorkImportDialog> createState() => _WorkImportDialogState();
}

class _WorkImportDialogState extends ConsumerState<WorkImportDialog> {
 @override
  Widget build(BuildContext context) {
    final state = ref.watch(workImportProvider);
    final viewModel = ref.read(workImportProvider.notifier);
    return AlertDialog(
      title: const Text('导入书法作品'),
      content: SizedBox(
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
                  ElevatedButton.icon(
                    onPressed: state.isLoading ? null : () => _selectImages(context),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('添加图片'),
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
                    child: _buildImageList(state),
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
                    onPressed: state.images.isEmpty ? null : () {
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

   Widget _buildImageList(WorkImportState state) {
    if (state.images.isEmpty) {
      return const Center(
        child: Text('请添加图片'),
      );
    }

    return ListView.builder(
      itemCount: state.images.length,
      itemBuilder: (context, index) {
        return _ImageListItem(
          file: state.images[index],
          isSelected: index == state.selectedImageIndex,
          onTap: () => ref.read(workImportProvider.notifier).selectImage(index),
          onRemove: () => ref.read(workImportProvider.notifier).removeImage(index),
        );
      },
    );
  }

  Future<void> _selectImages(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: false,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final files = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();

        if (files.isNotEmpty) {
          await ref.read(workImportProvider.notifier).addImages(files);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: ${e.toString()}')),
        );
      }
    }
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
 
}

class _ImageListItem extends StatelessWidget {
  final File file;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImageListItem({
    required this.file,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            SizedBox(
              height: 100,
              child: Row(
                children: [
                  // Thumbnail
                  SizedBox(
                    width: 100,
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // File name
                  Expanded(
                    child: Text(
                      path.basename(file.path),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: onRemove,
                tooltip: '移除图片',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
