import 'package:demo/presentation/dialogs/work_edit_dialog.dart';
import 'package:demo/presentation/widgets/character/character_detail_view.dart';
import 'package:demo/presentation/widgets/character/character_extraction_panel.dart';
import 'package:demo/presentation/widgets/window/title_bar.dart';
import 'package:flutter/material.dart';
import '../../dialogs/export_dialog.dart';
import '../../dialogs/delete_confirmation_dialog.dart';
import '../practices/practice_detail_page.dart';
import '../../dialogs/character_detail_dialog.dart';

class WorkDetailPage extends StatefulWidget {
  final int workId;
  const WorkDetailPage({Key? key, required this.workId}) : super(key: key);

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  int _currentImageIndex = 0;

  Widget _buildPreviewArea() {
    return Column(
      children: [
        // 主预览区域
        Expanded(
          child: Container(
            color: Colors.grey[200],
            child: Stack(
              children: [
                // 图片预览（占位）
                Center(
                  child: Text(
                    '图片预览 ${_currentImageIndex + 1}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                // 工具栏覆盖层
                Positioned(
                  right: 16,
                  top: 16,
                  child: Card(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_in),
                          onPressed: () {},
                          tooltip: '放大',
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_out),
                          onPressed: () {},
                          tooltip: '缩小',
                        ),
                        IconButton(
                          icon: const Icon(Icons.rotate_right),
                          onPressed: () {},
                          tooltip: '旋转',
                        ),
                        IconButton(
                          icon: const Icon(Icons.fit_screen),
                          onPressed: () {},
                          tooltip: '适应屏幕',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 底部缩略图列表
        Container(
          height: 100,
          padding: const EdgeInsets.all(8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5, // 示例数量
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = index == _currentImageIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _currentImageIndex = index);
                },
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 2,
                    ),
                    color: Colors.grey[300],
                  ),
                  child: Center(child: Text('图 ${index + 1}')),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => CharacterDetailDialog(
                charId: 'char_$index',
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text('字$index'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Text(
                    '2024-01-${index + 1}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('基本信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInfoRow('作品名称', '示例作品'),
                  _buildInfoRow('创作者', '张三'),
                  _buildInfoRow('创作时间', '2024-01-01'),
                  _buildInfoRow('书法风格', '楷书'),
                  _buildInfoRow('书写工具', '毛笔'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 集字信息卡片 - 分配较多空间 (flex: 2)
          Expanded(
            flex: 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('集字信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildInfoRow('已采集字数', '12'),
                    const SizedBox(height: 16),
                    // 使用 Expanded 包裹 GridView 使其在剩余空间中滚动
                    Expanded(child: _buildCharacterGrid()),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 关联字帖卡片 - 分配较少空间 (flex: 1)
          Expanded(
            flex: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('关联字帖', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    // 使用 Expanded 包裹 ListView 使其在剩余空间中滚动
                    Expanded(
                      child: ListView.separated(
                        itemCount: 3,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(child: Text('字帖${index + 1}')),
                            ),
                            title: Text('示例字帖 ${index + 1}'),
                            subtitle: Text('创建时间: 2024-01-${index + 1}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PracticeDetailPage(
                                    practiceId: 'practice_$index',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    return Scaffold(
      body: Column(
        children: [
          TitleBar(),
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('作品详情', style: TextStyle(fontSize: 20)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => WorkEditDialog(workId: widget.workId),
                  );
                },
                tooltip: '编辑',
              ),
              IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ExportDialog(workId: widget.workId),
                  );
                },
                tooltip: '导出',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => DeleteConfirmationDialog(
                      onConfirm: () {
                        Navigator.pop(context); // 关闭对话框
                        Navigator.pop(context); // 返回作品浏览页面
                      },
                    ),
                  );
                },
                tooltip: '删除',
              ),
              const VerticalDivider(indent: 8, endIndent: 8),
              IconButton(
                icon: const Icon(Icons.brush_outlined), // 更换为更美观的图标
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CharacterExtractionPanel(
                      workId: widget.workId.toString(),
                      imageIndex: _currentImageIndex,
                    ),
                  );
                },
                tooltip: '进入集字模式',
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          Expanded(
            child: Row(
              children: [
                // 左侧主区域 (70%宽度): 作品图片预览
                Expanded(
                  flex: 7,
                  child: _buildPreviewArea(),
                ),
                // 右侧边栏 (30%宽度): 信息面板
                Expanded(
                  flex: 3,
                  child: _buildInfoPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterDetailPage extends StatelessWidget {
  final String charId;
  final VoidCallback onBack;

  const CharacterDetailPage({Key? key, required this.charId, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text('字帖详情', style: TextStyle(fontSize: 20)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('字帖 $charId'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
