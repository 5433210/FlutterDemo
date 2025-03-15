import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../providers/work_image_editor_provider.dart' as editor;
import '../../../widgets/common/base_image_preview.dart';
import 'thumbnail_strip.dart';

class ViewModeImagePreview extends ConsumerStatefulWidget {
  final WorkEntity work;

  const ViewModeImagePreview({
    super.key,
    required this.work,
  });

  @override
  ConsumerState<ViewModeImagePreview> createState() =>
      _ViewModeImagePreviewState();
}

class _ViewModeImagePreviewState extends ConsumerState<ViewModeImagePreview> {
  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(editor.currentWorkImageIndexProvider);
    final imagePaths = widget.work.images.map((img) => img.path).toList();

    return Column(
      children: [
        // Main preview
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: imagePaths.isEmpty
                ? const Center(
                    child: Text('暂无图片'),
                  )
                : BaseImagePreview(
                    imagePaths: imagePaths,
                    initialIndex: selectedIndex,
                    onIndexChanged: (index) {
                      ref
                          .read(editor.currentWorkImageIndexProvider.notifier)
                          .state = index;
                    },
                    showThumbnails: false,
                    enableZoom: true,
                  ),
          ),
        ),

        // Thumbnail strip
        if (widget.work.images.isNotEmpty)
          SizedBox(
            height: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ThumbnailStrip(
                images: widget.work.images,
                selectedIndex: selectedIndex,
                isEditable: false,
                onTap: (index) {
                  ref
                      .read(editor.currentWorkImageIndexProvider.notifier)
                      .state = index;
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    // Reset index when view is disposed
    if (widget.work.images.isNotEmpty) {
      // 不在dispose中直接修改state，避免可能的错误
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(editor.currentWorkImageIndexProvider.notifier).state = 0;
        }
      });
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Reset index when view is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editor.currentWorkImageIndexProvider.notifier).state = 0;
    });
  }
}
