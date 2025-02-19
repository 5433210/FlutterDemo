import 'package:flutter/material.dart';
import 'work_detail_page.dart';

class WorkListPage extends StatefulWidget {
  const WorkListPage({super.key});

  @override
  State<WorkListPage> createState() => _WorkListPageState();
}

class _WorkListPageState extends State<WorkListPage> {
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
                  onPressed: () {/* 导入作品对话框 */},
                  icon: const Icon(Icons.add),
                  label: const Text('导入作品'),
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
                      hintText: '搜索作品',
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
                        // 点击进入作品详情页（占位）
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              color: Colors.grey[300],
                              child: Center(child: Text('作品 $index')),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('作品名称 $index',
                                  style: Theme.of(context).textTheme.titleMedium),
                                Text('作者名称',
                                  style: Theme.of(context).textTheme.bodySmall),
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
                      title: Text('作品名称 $index'),
                      subtitle: const Text('作者名称'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // 点击进入作品详情页（占位）
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
