import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import '../providers/work_import_provider.dart';
import '../viewmodels/states/work_import_state.dart';
import '../../application/providers/service_providers.dart';

class WorkImportDialog extends ConsumerStatefulWidget {
  const WorkImportDialog({super.key});

  @override
  ConsumerState<WorkImportDialog> createState() => _WorkImportDialogState();
}

class _WorkImportDialogState extends ConsumerState<WorkImportDialog> {
  @override
  Widget build(BuildContext context) {
    final workService = ref.watch(workServiceProvider);
    return _buildDialog(context);
  }

  Widget _buildDialog(BuildContext context) {
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
                    onPressed:
                        state.isLoading ? null : () => _selectImages(context),
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
                    onPressed: state.isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: state.isLoading || !state.isValid
                        ? null
                        : () => _handleImport(context),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('导入'),
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
          onRemove: () =>
              ref.read(workImportProvider.notifier).removeImage(index),
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
    final state = ref.watch(workImportProvider);
    final viewModel = ref.read(workImportProvider.notifier);

    // Check if we have valid image index
    final hasValidSelection = state.images.isNotEmpty &&
        state.selectedImageIndex >= 0 &&
        state.selectedImageIndex < state.images.length;

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
                onPressed: hasValidSelection
                    ? () => viewModel.updateZoom(state.zoomLevel * 1.2)
                    : null,
                tooltip: '放大',
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: hasValidSelection
                    ? () => viewModel.updateZoom(state.zoomLevel / 1.2)
                    : null,
                tooltip: '缩小',
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right),
                onPressed: hasValidSelection
                    ? () => viewModel.updateRotation(state.rotation + 90)
                    : null,
                tooltip: '旋转',
              ),
              IconButton(
                icon: const Icon(Icons.crop),
                onPressed: hasValidSelection
                    ? () => _showCropDialog(context, state)
                    : null,
                tooltip: '裁剪',
              ),
              const SizedBox(width: 16),
              if (hasValidSelection)
                Text('${(state.zoomLevel * 100).round()}%'),
            ],
          ),
        ),
        // 预览区
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: hasValidSelection
                ? InteractiveViewer(
                    minScale: 0.1,
                    maxScale: 5.0,
                    onInteractionUpdate: (details) {
                      if (details.scale != 1.0) {
                        viewModel.updateZoom(state.zoomLevel * details.scale);
                      }
                    },
                    child: Center(
                      child: Transform.rotate(
                        angle: state.rotation * pi / 180,
                        child: Image.file(
                          state.images[state.selectedImageIndex],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Text('请选择要预览的图片'),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCropDialog(
      BuildContext context, WorkImportState state) async {
    // TODO: Implement image cropping dialog
    // This is a placeholder implementation
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('图片裁剪'),
        content: const Text('裁剪功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    final state = ref.watch(workImportProvider);
    final viewModel = ref.read(workImportProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: '作品名称 *',
              hintText: '请输入作品名称',
              border: OutlineInputBorder(),
            ),
            onChanged: viewModel.updateName,
            controller: TextEditingController(text: state.name),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: '创作者',
              hintText: '请输入创作者姓名',
              border: OutlineInputBorder(),
            ),
            onChanged: viewModel.updateAuthor,
            controller: TextEditingController(text: state.author),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: state.creationDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                viewModel.updateCreationDate(date);
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
                  Text(state.creationDate != null
                      ? DateFormat('yyyy-MM-dd').format(state.creationDate!)
                      : '选择日期'),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '书法风格',
              border: OutlineInputBorder(),
            ),
            value: state.style,
            items: const [
              DropdownMenuItem(value: 'kai', child: Text('楷书')),
              DropdownMenuItem(value: 'xing', child: Text('行书')),
              DropdownMenuItem(value: 'cao', child: Text('草书')),
            ],
            onChanged: viewModel.updateStyle,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '书写工具',
              border: OutlineInputBorder(),
            ),
            value: state.tool,
            items: const [
              DropdownMenuItem(value: 'brush', child: Text('毛笔')),
              DropdownMenuItem(value: 'pen', child: Text('硬笔')),
            ],
            onChanged: viewModel.updateTool,
          ),
          const SizedBox(height: 16),
          TextField(
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '备注',
              hintText: '请输入备注信息',
              border: OutlineInputBorder(),
            ),
            onChanged: viewModel.updateRemarks,
            controller: TextEditingController(text: state.remarks),
          ),
          const SizedBox(height: 24),
          const Text('导入选项',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('自动优化图片质量'),
            value: state.optimizeImages,
            onChanged: (value) => viewModel.toggleOptimizeImages(),
          ),
          SwitchListTile(
            title: const Text('保存原始图片副本'),
            value: state.keepOriginals,
            onChanged: (value) => viewModel.toggleKeepOriginals(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(BuildContext context) async {
    final viewModel = ref.read(workImportProvider.notifier);

    try {
      final success = await viewModel.importWork();
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: ${e.toString()}')),
        );
      }
    }
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
      color:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
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
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
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
