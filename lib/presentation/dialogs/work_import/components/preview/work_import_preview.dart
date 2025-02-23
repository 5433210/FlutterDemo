import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as path;
import '../../../../../theme/app_sizes.dart';
import '../../../../viewmodels/states/work_import_state.dart';
import '../../../../viewmodels/work_import_view_model.dart';
import 'preview_toolbar.dart';
import 'thumbnail_strip.dart';
import 'image_viewer.dart';

class WorkImportPreview extends StatefulWidget {
  final WorkImportState state;
  final WorkImportViewModel viewModel;
  final VoidCallback onAddImages;

  const WorkImportPreview({
    super.key,
    required this.state,
    required this.viewModel,
    required this.onAddImages,
  });

  @override
  _WorkImportPreviewState createState() => _WorkImportPreviewState();
}

class _WorkImportPreviewState extends State<WorkImportPreview> {
  bool _isDragging = false;
  bool _isProcessing = false;
  final GlobalKey _dropTargetKey = GlobalKey();

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: AppSizes.s),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSizes.m),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleDropDone(DropDoneDetails details) async {
    if (_isProcessing) return;

    setState(() {
      _isDragging = false;
      _isProcessing = true;
    });

    try {
      final files = details.files
          .where((file) {
            final ext = path.extension(file.path).toLowerCase();
            return ['.jpg', '.jpeg', '.png', '.webp'].contains(ext);
          })
          .map((file) => File(file.path))
          .toList();

      if (files.isEmpty) {
        _showError('仅支持 jpg、jpeg、png、webp 格式的图片');
        return;
      }

      await widget.viewModel.addImages(files);
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showError('添加图片失败：${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImages = widget.state.images.isNotEmpty;
    final hasSelection = widget.state.selectedImageIndex >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 工具栏
        PreviewToolbar(
          hasImages: hasImages,
          hasSelection: hasSelection,
          onAddImages: widget.onAddImages,
          onRotateLeft: () => widget.viewModel.rotateImage(false),
          onRotateRight: () => widget.viewModel.rotateImage(true),
          onDelete: () => widget.viewModel.removeImage(widget.state.selectedImageIndex),
        ),

        // 预览区域
        Expanded(
          child: _buildDropTarget(),
        ),

        // 缩略图区域
        if (hasImages)
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: ThumbnailStrip(
              images: widget.state.images,
              selectedIndex: widget.state.selectedImageIndex,
              onSelect: widget.viewModel.selectImage,
              onRemove: widget.viewModel.removeImage,
              onReorder: widget.viewModel.reorderImages,
            ),
          ),
      ],
    );
  }

  Widget _buildDropTarget() {
    final theme = Theme.of(context);
    final hasImages = widget.state.images.isNotEmpty;
    final hasSelection = widget.state.selectedImageIndex >= 0 && 
                        widget.state.selectedImageIndex < widget.state.images.length;  // 添加范围检查

    return DropTarget(
      key: _dropTargetKey,
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: _handleDropDone,
      child: MouseRegion(
        cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onAddImages,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 背景
              Container(
                color: theme.colorScheme.surface,
                child: hasImages && hasSelection
                    ? ImageViewer(
                        image: widget.state.images[widget.state.selectedImageIndex],
                        rotation: widget.state.getRotation(
                          widget.state.images[widget.state.selectedImageIndex].path,
                        ),
                        scale: widget.state.scale,
                        onResetView: widget.viewModel.resetView,
                        onScaleChanged: widget.viewModel.setScale,
                      )
                    : _buildPlaceholder(theme, hasImages),
              ),

              // 拖放遮罩
              if (_isDragging)
                _buildDragOverlay(theme),

              // 处理中指示器
              if (_isProcessing)
                _buildProcessingOverlay(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, bool hasImages) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasImages ? Icons.photo_library_outlined : Icons.cloud_upload_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSizes.m),
          Text(
            hasImages ? '请选择要预览的图片' : '点击或拖放图片到此处',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (!hasImages) ...[
            const SizedBox(height: AppSizes.s),
            Text(
              '支持 jpg、jpeg、png、webp 格式',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDragOverlay(ThemeData theme) {
    return AnimatedOpacity(
      opacity: _isDragging ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.file_upload_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSizes.s),
              Text(
                '释放鼠标添加图片',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay(ThemeData theme) {
    return Container(
      color: theme.colorScheme.scrim.withOpacity(0.32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.m),
            Text(
              '正在处理...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}