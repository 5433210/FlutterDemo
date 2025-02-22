import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
import '../providers/work_import_provider.dart';
import '../theme/app_sizes.dart';
import '../viewmodels/states/work_import_state.dart';
import '../viewmodels/work_import_view_model.dart';

class WorkImportDialog extends ConsumerWidget {
  const WorkImportDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workImportProvider);
    final viewModel = ref.read(workImportProvider.notifier);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.maxDialogWidth,
          maxHeight: AppSizes.maxDialogHeight,
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 7,
                    child: WorkImportPreview(
                      images: state.images,
                      selectedIndex: state.selectedImageIndex,
                      onImageSelected: viewModel.selectImage,
                      onImagesAdded: viewModel.addImages,
                      onImageRemoved: viewModel.removeImage,
                      onRotate: viewModel.rotateSelectedImage,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: AppSizes.formWidth,
                    child: WorkImportForm(
                      state: state,
                      viewModel: viewModel,
                    ),
                  ),
                ],
              ),
            ),
            _buildFooter(context, state, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '导入书法作品',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WorkImportState state,
    WorkImportViewModel viewModel,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (state.error != null)
            Expanded(
              child: Text(
                state.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          TextButton(
            onPressed: state.isLoading
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const SizedBox(width: AppSizes.m),
          FilledButton(
            onPressed: state.isLoading || !state.isValid
                ? null
                : () async {
                    final success = await viewModel.importWork();
                    if (success && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
            child: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('导入'),
          ),
        ],
      ),
    );
  }
}

class WorkImportPreview extends StatelessWidget {
  final List<File> images;
  final int selectedIndex;
  final ValueChanged<int> onImageSelected;
  final ValueChanged<List<File>> onImagesAdded;
  final ValueChanged<int> onImageRemoved;
  final ValueChanged<bool> onRotate;

  const WorkImportPreview({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onImageSelected,
    required this.onImagesAdded,
    required this.onImageRemoved,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(context),
        Expanded(
          child: images.isEmpty
              ? _buildDropTarget(
                  child: _buildEmptyState(context),
                )
              : _buildImageView(context),
        ),
        if (images.isNotEmpty)
          _buildThumbnailStrip(context),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      height: AppSizes.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('添加图片'),
            onPressed: () => _pickImages(context),
          ),
          if (images.isNotEmpty && selectedIndex >= 0) ...[
            const SizedBox(width: AppSizes.m),
            IconButton(
              icon: const Icon(Icons.rotate_left),
              tooltip: '向左旋转',
              onPressed: () => onRotate(false),
            ),
            IconButton(
              icon: const Icon(Icons.rotate_right),
              tooltip: '向右旋转',
              onPressed: () => onRotate(true),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '删除',
              onPressed: () => onImageRemoved(selectedIndex),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageView(BuildContext context) {
    if (selectedIndex < 0 || selectedIndex >= images.length) {
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(workImportProvider);
        final viewModel = ref.read(workImportProvider.notifier);

        return WorkImportImageViewer(
          key: ValueKey(images[selectedIndex].path),
          image: images[selectedIndex],
          rotation: state.getRotation(images[selectedIndex].path),
          scale: state.scale,
          onResetView: viewModel.resetView,
          onScaleChanged: viewModel.setScale,
        );
      },
    );
  }

  Widget _buildThumbnailStrip(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.s),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, _) => const SizedBox(width: AppSizes.s),
        itemBuilder: (context, index) => WorkThumbnailItem(
          image: images[index],
          isSelected: index == selectedIndex,
          onTap: () => onImageSelected(index),
          onRemove: () => onImageRemoved(index),
        ),
      ),
    );
  }

  Widget _buildDropTarget({required Widget child}) {
    return DragTarget<List<String>>(
      onWillAccept: (data) => data != null,
      onAccept: (paths) {
        final files = paths.map((path) => File(path)).toList();
        onImagesAdded(files);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSizes.l),
          Text(
            '点击或拖放图片到此处',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.m),
          Text(
            '支持 jpg、png、webp 格式',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.l),
          FilledButton.icon(
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('选择图片'),
            onPressed: () => _pickImages(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
      );

      if (result != null) {
        final files = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
        
        if (files.isNotEmpty) {
          onImagesAdded(files);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _ThumbnailItem extends StatelessWidget {
  final File image;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThumbnailItem({
    required this.image,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Image.file(
            image,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class WorkImportForm extends StatelessWidget {
  final WorkImportState state;
  final WorkImportViewModel viewModel;

  const WorkImportForm({
    super.key,
    required this.state,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            context,
            label: '作品名称',
            value: state.name,
            onChanged: viewModel.updateName,
            required: true,
          ),
          const SizedBox(height: AppSizes.m),
          _buildTextField(
            context,
            label: '作者',
            value: state.author ?? '',
            onChanged: viewModel.updateAuthor,
          ),
          const SizedBox(height: AppSizes.m),
          _buildStyleDropdown(context),
          const SizedBox(height: AppSizes.m),
          _buildToolDropdown(context),
          const SizedBox(height: AppSizes.m),
          _buildDateField(context),
          const SizedBox(height: AppSizes.m),
          _buildTextField(
            context,
            label: '备注',
            value: state.remarks ?? '',
            onChanged: viewModel.updateRemarks,
            maxLines: 3,
          ),
          const SizedBox(height: AppSizes.l),
          _buildImportOptions(context),
        ],
      ),
    );
  }

  Widget _buildStyleDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('书法风格'),
        const SizedBox(height: AppSizes.xs),
        DropdownButtonFormField<WorkStyle>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSizes.s,
              vertical: AppSizes.s,
            ),
          ),
          value: state.style,
          items: WorkStyle.values.map((style) {
            return DropdownMenuItem(
              value: style,
              child: Text(style.label),
            );
          }).toList(),
          onChanged: viewModel.updateStyle,
        ),
      ],
    );
  }

  Widget _buildToolDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('创作工具'),
        const SizedBox(height: AppSizes.xs),
        DropdownButtonFormField<WorkTool>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSizes.s,
              vertical: AppSizes.s,
            ),
          ),
          value: state.tool,
          items: WorkTool.values.map((tool) {
            return DropdownMenuItem(
              value: tool,
              child: Text(tool.label),
            );
          }).toList(),
          onChanged: viewModel.updateTool,
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('创作日期'),
        const SizedBox(height: AppSizes.xs),
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
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.creationDate == null
                        ? '请选择日期'
                        : DateFormat('yyyy-MM-dd').format(state.creationDate!),
                  ),
                ),
                if (state.creationDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => viewModel.updateCreationDate(state.creationDate),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String? value,
    required ValueChanged<String> onChanged,
    bool required = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            if (required)
              Text(
                '*',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        TextFormField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: maxLines,
          initialValue: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildImportOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导入选项',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSizes.m),
        _buildSwitch(
          context,
          label: '优化图片',
          subtitle: '自动调整图片大小和质量以节省空间',
          value: state.optimizeImages,
          onChanged: (_) => viewModel.toggleOptimizeImages(),
        ),
        const SizedBox(height: AppSizes.s),
        _buildSwitch(
          context,
          label: '保留原图',
          subtitle: '保存原始图片文件',
          value: state.keepOriginals,
          onChanged: (_) => viewModel.toggleKeepOriginals(),
        ),
      ],
    );
  }

  Widget _buildSwitch(
    BuildContext context, {
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(label),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class WorkThumbnailItem extends StatelessWidget {
  final File image;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const WorkThumbnailItem({
    super.key,
    required this.image,
    required this.isSelected,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.file(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (onRemove != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: onRemove,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class WorkImportImageViewer extends StatefulWidget {
  final File image;
  final double rotation;
  final double scale;
  final VoidCallback? onResetView;
  final ValueChanged<double>? onScaleChanged;

  const WorkImportImageViewer({
    super.key,
    required this.image,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.onResetView,
    this.onScaleChanged,
  });

  @override
  State<WorkImportImageViewer> createState() => _WorkImportImageViewerState();
}

class _WorkImportImageViewerState extends State<WorkImportImageViewer> {
  late TransformationController _transformationController;
  
  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WorkImportImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scale != oldWidget.scale || 
        widget.rotation != oldWidget.rotation) {
      _updateTransform();
    }
  }

  void _updateTransform() {
    final matrix = Matrix4.identity()
      ..scale(widget.scale, widget.scale)
      ..rotateZ(widget.rotation * (3.1415926535 / 180));
    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 5.0,
          onInteractionEnd: (details) {
            if (widget.onScaleChanged != null) {
              final scale = _transformationController.value.getMaxScaleOnAxis();
              widget.onScaleChanged!(scale);
            }
          },
          child: Center(
            child: Image.file(
              widget.image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorWidget(context);
              },
            ),
          ),
        ),
        if ((widget.scale != 1.0 || widget.rotation != 0.0) && 
            widget.onResetView != null)
          Positioned(
            right: AppSizes.m,
            bottom: AppSizes.m,
            child: FloatingActionButton.small(
              onPressed: widget.onResetView,
              tooltip: '重置视图',
              child: const Icon(Icons.refresh),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.l),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSizes.m),
          Text(
            '图片加载失败',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
