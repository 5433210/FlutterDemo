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
        final collectionState = ref.read(characterCollectionProvider);
        // 查找匹配的region，如果找不到则返回null
        final regions = collectionState.regions
            .where((r) => r.characterId == characterId)
            .toList();

        if (regions.isEmpty) {
          // 如果在当前已加载的regions中找不到，需要从数据库查询
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('正在查找字符区域...'),
              duration: Duration(seconds: 1),
            ),
          );

          try {
            // 先切换到预览标签页
            _tabController.animateTo(0);

            // 获取字符服务来查询字符区域信息
            final characterService = ref.read(characterServiceProvider);

            // 通过characterId获取字符详情
            final character =
                await characterService.getCharacterDetails(characterId);
            if (character == null) {
              throw Exception('找不到字符信息');
            }

            final pageId = character.pageId;
            final workId = widget.workId;

            // 获取图像提供者
            final imageProvider = ref.read(workImageProvider.notifier);

            // 加载目标页面
            await imageProvider.loadWorkImage(workId, pageId);

            // 加载该页的字符区域数据
            await ref.read(characterCollectionProvider.notifier).loadWorkData(
                  workId,
                  pageId: pageId,
                );

            // 重新查找region（应该已加载到regions中）
            final updatedState = ref.read(characterCollectionProvider);
            final updatedRegions = updatedState.regions
                .where((r) => r.characterId == characterId)
                .toList();

            if (updatedRegions.isNotEmpty) {
              // 选中目标字符区域
              ref
                  .read(characterCollectionProvider.notifier)
                  .selectRegion(updatedRegions.first.id);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('无法找到对应的选区，请手动选择'),
                  backgroundColor: Colors.orange,
                ),
              );
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
          return;
        }

        final region = regions.first;
        final pageId = region.pageId;

        try {
          // 先切换到预览标签页，让用户看到正在切换
          _tabController.animateTo(0);

          // 显示加载提示
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('正在切换到字符所在页面...'),
              duration: Duration(seconds: 1),
            ),
          );

          // 获取图像提供者
          final imageProvider = ref.read(workImageProvider.notifier);
          final currentWorkId = widget.workId;

          // 检查当前是否已经是目标页面
          final currentState = ref.read(workImageProvider);
          final isAlreadyOnPage = currentState.currentPageId == pageId &&
              currentState.workId == currentWorkId;

          if (!isAlreadyOnPage) {
            // 加载目标页面
            await imageProvider.loadWorkImage(currentWorkId, pageId);

            // 加载该页的字符区域数据
            await ref.read(characterCollectionProvider.notifier).loadWorkData(
                  currentWorkId,
                  pageId: pageId,
                );
          }

          // 选中目标字符区域
          ref
              .read(characterCollectionProvider.notifier)
              .selectRegion(region.id);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('切换到字符所在页面失败: $e'),
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

      // 等待一下让UI更新完成
      await Future.delayed(const Duration(milliseconds: 300));

      // 重新加载集字列表
      await ref.read(characterCollectionProvider.notifier).loadWorkData(
            widget.workId,
            pageId: ref.read(workImageProvider).currentPageId ?? '',
          );

      // 确保刷新作品集字结果
      try {
        await ref.read(characterGridProvider.notifier).loadCharacters();
      } catch (e) {
        print('刷新字符网格失败: $e');
      }
    }
  }
}
