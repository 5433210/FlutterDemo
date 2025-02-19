import 'package:flutter/material.dart';
import '../../widgets/common/data_list.dart';
import '../../widgets/common/base_toolbar.dart';

class PracticeListPage extends StatefulWidget {
  const PracticeListPage({super.key});

  @override
  State<PracticeListPage> createState() => _PracticeListPageState();
}

class _PracticeListPageState extends State<PracticeListPage> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部工具栏
        Material(
          elevation: 2,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {/* 新建字帖 */},
                  icon: const Icon(Icons.add),
                  label: const Text('新建字帖'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                  tooltip: _isGridView ? '列表视图' : '网格视图',
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '搜索字帖',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 内容区域
        Expanded(
          child: _isGridView
            ? GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: 20,
                itemBuilder: (context, index) {
                  return Card(
                    child: InkWell(
                      onTap: () {
                        // 点击进入字帖详情页（占位）
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
            )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
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
                        // 点击进入字帖详情页（占位）
                      },
                    ),
                  );
                },
            ),
        ),
      ],
    );
  }
}
