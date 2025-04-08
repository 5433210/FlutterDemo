import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../application/services/character/character_service.dart';
import '../../../presentation/providers/character/erase_providers.dart';
import '../../../widgets/character_edit/character_edit_panel.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/character_grid_provider.dart';
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
  bool _wasAdjusting = false;

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(workImageProvider);
    final selectedRegion = ref.watch(selectedRegionProvider);
    // 监听处理选项
    final processingOptions = ref.watch(processingOptionsProvider);
    // 监听选区调整状态
    final isAdjusting = ref.watch(characterCollectionProvider).isAdjusting;

    // 处理选区调整状态变化
    if (isAdjusting != _wasAdjusting) {
      _wasAdjusting = isAdjusting;
      if (!isAdjusting) {
        // 选区调整完成，更新图像
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _characterImage?.dispose();
              _characterImage = null;
            });
          }
        });
      }
    }

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
    _tabController.addListener(handleTabChange);

    // 初始化时清除擦除状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eraseStateProvider.notifier).clear();
    });
  }

  Widget _buildCharacterEditor(
    CharacterRegion selectedRegion,
    WorkImageState imageState,
    ProcessingOptions processingOptions,
  ) {
    // 使用selectedRegion的id、rect和rotation作为key的一部分，确保选区变化时重建
    return CharacterEditPanel(
      key: ValueKey(
          'editor_${selectedRegion.id}_${selectedRegion.rect.left}_${selectedRegion.rect.top}_${selectedRegion.rect.width}_${selectedRegion.rect.height}_${selectedRegion.rotation}'),
      selectedRegion: selectedRegion,
      workId: widget.workId,
      pageId: imageState.currentPageId ?? '',
      imageData: imageState.imageData,
      processingOptions: processingOptions,
      onEditComplete: _handleEditComplete,
    );
  }

  Widget _buildGridTab() {
    return CharacterGridView(
      workId: widget.workId,
      onCharacterSelected: (characterId) async {
        try {
          // 1. 获取当前页面状态
          final currentState = ref.read(workImageProvider);
          final currentPageId = currentState.currentPageId;
          final currentWorkId = widget.workId;

          // 2. 获取字符服务来查询字符详情
          final characterService = ref.read(characterServiceProvider);
          final character =
              await characterService.getCharacterDetails(characterId);

          if (character == null) {
            throw Exception('找不到字符信息');
          }

          // 3. 检查字符是否在当前页面
          final isOnCurrentPage = character.pageId == currentPageId &&
              character.workId == currentWorkId;

          if (!isOnCurrentPage) {
            // 4. 如果不在当前页面，需要切换页面
            // 4.1 显示加载提示
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('正在切换到字符所在页面...'),
                duration: Duration(seconds: 1),
              ),
            );

            // 4.2 加载目标页面
            final imageProvider = ref.read(workImageProvider.notifier);
            await imageProvider.loadWorkImage(
                character.workId, character.pageId);

            // 4.3 加载该页的字符区域数据
            await ref.read(characterCollectionProvider.notifier).loadWorkData(
                  character.workId,
                  pageId: character.pageId,
                  defaultSelectedRegionId: characterId,
                );

            // 4.4 切换到预览标签页
            _tabController.animateTo(0);
          } else {
            // 5. 如果在当前页面，直接加载区域数据
            await ref.read(characterCollectionProvider.notifier).loadWorkData(
                  currentWorkId,
                  pageId: currentPageId,
                  defaultSelectedRegionId: characterId,
                );

            // 5.1 切换到预览标签页
            _tabController.animateTo(0);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('查找并切换页面失败: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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

    return _buildCharacterEditor(selectedRegion, imageState, processingOptions);
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

  void _handleEditComplete(Map<String, dynamic> result) async {
    final characterId = result['characterId'];
    if (characterId != null) {
      // 切换到作品集字结果标签页
      _tabController.animateTo(1);

      // 刷新作品集字结果
      try {
        await ref.read(characterGridProvider.notifier).loadCharacters();
      } catch (e) {
        print('刷新字符网格失败: $e');
      }
    }
  }
}
