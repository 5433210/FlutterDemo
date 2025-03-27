import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/repository_providers.dart';
import '../../providers/character/selected_region_provider.dart';
import 'character_edit_panel.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 标签栏
        Container(
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
        ),

        // 标签内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 标签1: 集字效果预览
              const CharacterEditPanel(),

              // 标签2: 作品集字结果
              CharacterGridView(
                workId: widget.workId,
                onCharacterSelected: (id) async {
                  // 点击字符时，跳转到编辑视图并选中对应字符
                  await _selectCharacterRegion(id);
                  _tabController.animateTo(0); // 切换到编辑标签页
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  Future<void> _selectCharacterRegion(String id) async {
    try {
      final repository = ref.read(characterRepositoryProvider);
      final region = await repository.findById(id);
      if (region != null) {
        ref.read(selectedRegionProvider.notifier).setRegion(region.region);
      }
    } catch (e) {
      // 处理错误情况
    }
  }
}
