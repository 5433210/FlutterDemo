import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../viewmodels/states/work_import_state.dart';
import '../../../../viewmodels/work_import_view_model.dart';
import '../../../../widgets/loading_overlay.dart';
import 'image_viewer.dart';
import 'preview_toolbar.dart';
import 'empty_state.dart';
import 'drop_target.dart';
import 'thumbnail_strip.dart';

class WorkImportPreview extends StatelessWidget {
  final WorkImportState state;
  final WorkImportViewModel viewModel;

  const WorkImportPreview({
    //super.key,
    required this.state,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主内容区
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewToolbar(
              hasImages: state.images.isNotEmpty,
              hasSelection: state.selectedImageIndex >= 0,
              onAddImages: () => _pickImages(context),
              onRotateLeft: () => viewModel.rotateImage(false),
              onRotateRight: () => viewModel.rotateImage(true),
              onDelete: () => viewModel.removeImage(state.selectedImageIndex),
            ),
            // 图片预览区
            Expanded(
              child: state.images.isEmpty
                  ? ImageDropTarget(
                      onFilesDropped: viewModel.addImages,
                      child: const EmptyState(),
                    )
                  : ImageDropTarget(
                      onFilesDropped: viewModel.addImages,
                      child: ImageViewer(
                        image: state.images[state.selectedImageIndex],
                        rotation: state.getRotation(
                          state.images[state.selectedImageIndex].path,
                        ),
                        scale: state.scale,
                        onResetView: viewModel.resetView,
                        onScaleChanged: viewModel.setScale,
                      ),
                    ),
            ),
            
            // 缩略图列表
            if (state.images.isNotEmpty)
              SizedBox(
                height: 120,
                child: ThumbnailStrip(
                  images: state.images,
                  selectedIndex: state.selectedImageIndex,
                  onSelect: viewModel.selectImage,
                  onRemove: viewModel.removeImage,
                  onReorder: viewModel.reorderImages,
                ),
              ),
          ],
        ),

        // 加载遮罩
        if (state.isLoading)
          const LoadingOverlay(),
      ],
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
          viewModel.addImages(files);
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