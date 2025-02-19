import 'package:flutter/material.dart';
import '../../dialogs/character_edit_dialog.dart';
import '../works/work_detail_page.dart';

class CharacterListPage extends StatefulWidget {
  const CharacterListPage({Key? key}) : super(key: key);

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  bool isGrid = true;
  String? selectedCharId;

  Widget _buildListArea() {
    return Column(
      children: [
        // 顶部工具栏改为两行布局
        Column(
          children: [
            // 搜索与筛选工具栏
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  // 搜索框
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: '搜索简体字/作品名称',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 风格筛选
                  PopupMenuButton(
                    child: Chip(
                      label: const Text('书法风格'),
                      deleteIcon: const Icon(Icons.arrow_drop_down),
                      onDeleted: () {},
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(child: Text('全部')),
                      const PopupMenuItem(child: Text('楷书')),
                      const PopupMenuItem(child: Text('行书')),
                      // ...更多风格选项
                    ],
                  ),
                  const SizedBox(width: 8),
                  // 工具筛选
                  PopupMenuButton(
                    child: Chip(
                      label: const Text('书写工具'),
                      deleteIcon: const Icon(Icons.arrow_drop_down),
                      onDeleted: () {},
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(child: Text('全部')),
                      const PopupMenuItem(child: Text('毛笔')),
                      const PopupMenuItem(child: Text('硬笔')),
                    ],
                  ),
                ],
              ),
            ),
            // 操作工具栏
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 视图切换
                  ToggleButtons(
                    isSelected: [isGrid, !isGrid],
                    onPressed: (index) {
                      setState(() => isGrid = index == 0);
                    },
                    children: const [
                      Icon(Icons.grid_view),
                      Icon(Icons.list),
                    ],
                  ),
                  const Spacer(),
                  // 批量操作按钮组
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download),
                    label: const Text('导出'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete),
                    label: const Text('删除'),
                  ),
                ],
              ),
            ),
          ],
        ),
        // 列表内容区
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
        final charId = 'char_$index';
        final isSelected = charId == selectedCharId;
        
        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          child: InkWell(
            onTap: () => setState(() => selectedCharId = charId),
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
        final charId = 'char_$index';
        final isSelected = charId == selectedCharId;
        
        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          child: ListTile(
            leading: Container(
              width: 48,
              color: Colors.grey[200],
              child: const Center(child: Text('字')),
            ),
            title: Text('集字 $index'),
            subtitle: const Text('来自：作品X'),
            trailing: const Icon(Icons.chevron_right),
            selected: isSelected,
            onTap: () => setState(() => selectedCharId = charId),
          ),
        );
      },
    );
  }

  Widget _buildDetailArea() {
    if (selectedCharId == null) {
      return const Center(child: Text('请选择一个集字查看详情'));
    }

    return Column(
      children: [
        // 顶部工具栏
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CharacterEditDialog(
                      charId: selectedCharId!,
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('编辑'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // TODO: 获取实际的workId
                  final workId = 1;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkDetailPage(
                        workId: workId,
                      ),
                    ),
                  ).then((_) {
                    // 返回后可以刷新当前集字详情
                    setState(() {});
                  });
                },
                icon: const Icon(Icons.visibility),
                label: const Text('查看原作'),
              ),
            ],
          ),
        ),
        // 内容区
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 预览区域
                Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(child: Text('字', style: Theme.of(context).textTheme.displayLarge)),
                  ),
                ),
                const SizedBox(height: 24),
                // 信息卡片
                _buildInfoSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildInfoCard('基础信息', [
          _buildInfoRow('简体字', '示例'),
          _buildInfoRow('繁体字', '示例'),
          _buildInfoRow('风格', '楷书'),
          _buildInfoRow('工具', '毛笔'),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('来源信息', [
          _buildInfoRow('作品', '示例作品'),
          _buildInfoRow('位置', '第1页'),
          _buildInfoRow('采集时间', '2024-01-01'),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('使用记录', [
          _buildInfoRow('使用次数', '3'),
          _buildInfoRow('最近使用', '2024-01-01'),
          const SizedBox(height: 8),
          const Text('关联字帖：'),
          ListTile(
            title: const Text('示例字帖1'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('示例字帖2'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ]),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label：', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧列表区 (40%宽度)
        Expanded(
          flex: 4,
          child: _buildListArea(),
        ),
        // 分隔线
        const VerticalDivider(width: 1),
        // 右侧详情区 (60%宽度)
        Expanded(
          flex: 6,
          child: _buildDetailArea(),
        ),
      ],
    );
  }
}
