import 'package:flutter/material.dart';

class CharacterListPage extends StatefulWidget {
  const CharacterListPage({Key? key}) : super(key: key);

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  bool isGrid = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部工具栏
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Theme.of(context).primaryColorLight,
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    isGrid = !isGrid;
                  });
                },
                icon: Icon(isGrid ? Icons.list : Icons.grid_view),
                tooltip: isGrid ? '切换到列表视图' : '切换到网格视图',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '搜索集字',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 内容区域
        Expanded(
          child: isGrid ? _buildGridView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        return Card(
          child: InkWell(
            onTap: () {
              // 导航到集字详情（占位）
            },
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    child: Center(child: Text('字$index')),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('来自：作品X', style: Theme.of(context).textTheme.bodySmall),
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
      padding: const EdgeInsets.all(16),
      itemCount: 20,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: Container(
              width: 48,
              color: Colors.grey[200],
              child: const Center(child: Text('字')),
            ),
            title: Text('集字 $index'),
            subtitle: const Text('来自：作品X'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 导航到集字详情（占位）
            },
          ),
        );
      },
    );
  }
}
