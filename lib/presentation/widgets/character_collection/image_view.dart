import 'package:flutter/material.dart' hide SelectionOverlay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/selected_region_provider.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../../providers/character/work_image_provider.dart';
import 'selection_overlay.dart';

class ImageView extends ConsumerStatefulWidget {
  const ImageView({Key? key}) : super(key: key);

  @override
  ConsumerState<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends ConsumerState<ImageView> {
  // 变换控制器
  final TransformationController _transformationController =
      TransformationController();

  // 缩放状态
  double _currentScale = 1.0;
  double _previousScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(workImageProvider);
    final toolMode = ref.watch(toolModeProvider);
    final regions = ref.watch(characterCollectionProvider).regions;
    final selectedIds = ref.watch(characterCollectionProvider).selectedIds;

    // 如果没有图像数据，则显示空白
    if (imageState.imageData == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 可交互图像查看器
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 5.0,
          onInteractionStart: _handleInteractionStart,
          onInteractionUpdate: _handleInteractionUpdate,
          onInteractionEnd: _handleInteractionEnd,
          panEnabled: toolMode == Tool.pan,
          scaleEnabled: toolMode == Tool.pan,
          child: Center(
            child: Image.memory(
              imageState.imageData!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true, // 防止图像切换时闪烁
            ),
          ),
        ),

        // 选框覆盖层
        IgnorePointer(
          ignoring: toolMode == Tool.pan,
          child: SelectionOverlay(
            regions: regions,
            selectedIds: selectedIds,
            toolMode: toolMode,
            transformationController: _transformationController,
            onRegionCreated: (rect) => ref
                .read(characterCollectionProvider.notifier)
                .createRegion(rect),
            onRegionSelected: (id) =>
                ref.read(characterCollectionProvider.notifier).selectRegion(id),
            onRegionUpdated: (id, rect) =>
                ref.read(selectedRegionProvider.notifier).updateRect(rect),
          ),
        ),

        // 缩放指示器 (仅在缩放时显示)
        if (_currentScale != 1.0)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${(_currentScale * 100).toInt()}%',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // 交互结束
  void _handleInteractionEnd(ScaleEndDetails details) {
    // 更新当前比例
    setState(() {
      _currentScale = _transformationController.value.getMaxScaleOnAxis();
    });
  }

  // 交互开始
  void _handleInteractionStart(ScaleStartDetails details) {
    _previousScale = _currentScale;
  }

  // 交互更新
  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    if (ref.read(toolModeProvider) == Tool.pan) {
      setState(() {
        _currentScale = _previousScale * details.scale;
      });
    }
  }
}
