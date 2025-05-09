import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/library_item.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../infrastructure/providers/storage_providers.dart';
import '../../../widgets/common/full_screen_image_preview.dart';

/// 图库预览对话框
class LibraryImagePreviewDialog extends ConsumerStatefulWidget {
  final LibraryItem item;

  const LibraryImagePreviewDialog({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<LibraryImagePreviewDialog> createState() =>
      _LibraryImagePreviewDialogState();
}

class _LibraryImagePreviewDialogState
    extends ConsumerState<LibraryImagePreviewDialog> {
  List<String> _imagePaths = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          color: Theme.of(context).colorScheme.surface,
          child: _buildContent(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadImagePaths();
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }

    if (_imagePaths.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('没有找到图片文件'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }

    return FullScreenImagePreview(
      imagePaths: _imagePaths,
      initialIndex: 0,
      showThumbnails: true,
      enableZoom: true,
    );
  }

  Future<void> _loadImagePaths() async {
    try {
      final libraryStorage = ref.read(libraryStorageProvider);

      // 获取原图路径
      try {
        // 尝试获取具体的原始文件路径
        final originalFilePath = await libraryStorage.getLibraryItemPath(
            widget.item.id, widget.item.format);
        final originalFile = File(originalFilePath);

        if (await originalFile.exists()) {
          setState(() {
            _imagePaths = [originalFilePath];
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        AppLogger.debug(
          '无法获取具体原始文件路径，将尝试目录扫描',
          data: {
            'itemId': widget.item.id,
            'format': widget.item.format,
            'error': e.toString()
          },
        );
      }

      // 如果找不到具体文件，尝试列出目录下所有图片文件
      final itemDir =
          await libraryStorage.getLibraryItemDirectory(widget.item.id);
      final files = await Directory(itemDir.path)
          .list()
          .where((entity) =>
              entity is File &&
              !entity.path.contains('thumbnails') &&
              (entity.path.toLowerCase().endsWith('.jpg') ||
                  entity.path.toLowerCase().endsWith('.jpeg') ||
                  entity.path.toLowerCase().endsWith('.png') ||
                  entity.path.toLowerCase().endsWith('.gif') ||
                  entity.path.toLowerCase().endsWith('.webp') ||
                  entity.path
                      .toLowerCase()
                      .endsWith('.${widget.item.format.toLowerCase()}')))
          .toList();

      final paths = files.map((e) => e.path).toList();

      if (paths.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '找不到图片文件';
        });
      } else {
        setState(() {
          _imagePaths = paths;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error(
        '加载图片路径失败',
        error: e,
        stackTrace: stack,
        data: {'itemId': widget.item.id},
      );

      setState(() {
        _isLoading = false;
        _errorMessage = '加载图片失败: ${e.toString()}';
      });
    }
  }
}
