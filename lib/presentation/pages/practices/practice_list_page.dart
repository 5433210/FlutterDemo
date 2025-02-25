import 'package:flutter/material.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/page_toolbar.dart';
// 添加
import '../../../theme/app_sizes.dart';
import 'practice_detail_page.dart';
import 'practice_edit_page.dart';  // 添加

class PracticeListPage extends StatefulWidget {
  const PracticeListPage({super.key});

  @override
  State<PracticeListPage> createState() => _PracticeListPageState();
}

class _PracticeListPageState extends State<PracticeListPage> {
  bool _isGridView = true;

  void _navigateToPracticeDetail(BuildContext context, String practiceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeDetailPage(practiceId: practiceId),
      ),
    );
  }

  void _navigateToEditPage([String? practiceId]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeEditPage(practiceId: practiceId),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),  // 更新
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSizes.gridCrossAxisCount,  // 使用常量
        mainAxisSpacing: AppSizes.gridMainAxisSpacing,  // 使用常量
        crossAxisSpacing: AppSizes.gridCrossAxisSpacing,  // 使用常量
        childAspectRatio: 1,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        return Card(
          child: InkWell(
            onTap: () {
              _navigateToPracticeDetail(context, 'practice_$index'); // 添加导航
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        color: Colors.grey[300],
                        child: Center(child: Text('字帖 $index')),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Chip(
                          label: const Text('草稿'),
                          backgroundColor: Colors.yellow[100],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('字帖标题 $index', style: Theme.of(context).textTheme.titleMedium),
                      Text('创建时间: 2024-01-01', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),  // 更新
      itemCount: 20,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: Container(
              width: 48,
              color: Colors.grey[300],
              child: Center(child: Text('$index')),
            ),
            title: Text('字帖标题 $index'),
            subtitle: const Text('创建时间: 2024-01-01'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _navigateToPracticeDetail(context, 'practice_$index'); // 添加导航
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      navigationInfo: const Text('练习记录'),
      toolbar: PageToolbar(
        leading: [
          FilledButton.icon(
            onPressed: () => _navigateToEditPage(),
            icon: const Icon(Icons.add),
            label: const Text('新建练习'),
          ),
          const SizedBox(width: AppSizes.spacingMedium),
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            tooltip: _isGridView ? '列表视图' : '网格视图',
          ),
        ],
        trailing: [
          SizedBox(
            width: 240,
            child: SearchBar(
              hintText: '搜索练习...',
              leading: const Icon(Icons.search),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
              ),
            ),
          ),
        ],
      ),
      body: _isGridView ? _buildGridView() : _buildListView(),
    );
  }
}
