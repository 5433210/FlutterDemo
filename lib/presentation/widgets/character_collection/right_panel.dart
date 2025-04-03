import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../application/services/image/character_image_processor.dart';
import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../presentation/providers/character/erase_providers.dart';
import '../../../widgets/character_edit/character_edit_panel.dart';
import '../../providers/character/selected_region_provider.dart';
import '../../providers/character/work_image_provider.dart';
import 'character_grid_view.dart';

class RightPanel extends ConsumerStatefulWidget {
  final String workId;

  const RightPanel({
    Key? key,
    required this.workId,
  }) : super(key: key);

  @override
  ConsumerState<RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends ConsumerState<RightPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  ui.Image? _characterImage;

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(workImageProvider);
    final selectedRegion = ref.watch(selectedRegionProvider);
    // 监听处理选项
    final processingOptions = ref.watch(processingOptionsProvider);

    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 标签1: 集字效果预览
              _buildPreviewTab(selectedRegion, imageState, processingOptions),
              // 标签2: 作品集字结果
              _buildGridTab(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _characterImage?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 初始化时清除擦除状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eraseStateProvider.notifier).clear();
    });
  }

  Widget _buildCharacterEditor(ui.Image image) {
    return CharacterEditPanel(
      key: ValueKey(image.hashCode),
      image: image,
      onEditComplete: _handleEditComplete,
    );
  }

  Widget _buildGridTab() {
    return CharacterGridView(
      workId: widget.workId,
      onCharacterSelected: (id) async {
        _tabController.animateTo(0);
      },
    );
  }

  Widget _buildPreviewTab(
    CharacterRegion? selectedRegion,
    WorkImageState imageState,
    ProcessingOptions processingOptions,
  ) {
    if (selectedRegion == null) {
      return const Center(
        child: Text(
          '请在左侧预览区选择字符区域',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (imageState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (imageState.error != null) {
      return Center(
        child: Text(
          '加载失败: ${imageState.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return FutureBuilder<ui.Image>(
      future: _getSelectedRegionImage(
        selectedRegion,
        imageState.imageData,
        processingOptions,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              '处理选中区域失败: ${snapshot.error ?? "未知错误"}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return Center(
          child: _buildCharacterEditor(snapshot.data!),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: '集字效果预览'),
          Tab(text: '作品集字结果'),
        ],
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
        indicatorColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<ui.Image> _getSelectedRegionImage(
    CharacterRegion region,
    Uint8List? imageData,
    ProcessingOptions processingOptions,
  ) async {
    if (imageData == null) {
      throw Exception('No image data available');
    }

    final imageProcessor = ref.read(characterImageProcessorProvider);
    final preview = await imageProcessor.previewProcessing(
      imageData,
      region.rect,
      processingOptions,
      null,
    );

    final bytes = Uint8List.fromList(img.encodePng(preview.processedImage));
    final completer = Completer<ui.Image>();

    ui.decodeImageFromList(bytes, (result) {
      completer.complete(result);
    });

    return completer.future;
  }

  void _handleEditComplete(Map<String, dynamic> result) {
    // 获取路径数据和处理选项
    final pathRenderData = ref.read(pathRenderDataProvider);
    final eraseState = ref.read(eraseStateProvider);

    final resultData = {
      'paths': pathRenderData.completedPaths ?? [],
      'processingOptions': ProcessingOptions(
        inverted: eraseState.isReversed,
        threshold: 128.0,
        noiseReduction: 0.5,
        showContour: eraseState.showContour,
      ),
    };
  }
}
