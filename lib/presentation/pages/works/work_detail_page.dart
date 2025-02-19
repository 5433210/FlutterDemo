import 'package:demo/presentation/widgets/character/character_extraction_panel.dart';
import 'package:flutter/material.dart';
import '../../widgets/window/title_bar.dart';
import '../../dialogs/work_edit_dialog.dart';

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
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {}, 
                    child: const Text('编辑信息'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 采集信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('采集信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInfoRow('已采集字数', '0'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => CharacterExtractionPanel(
                            workId: widget.workId.toString(),
                            imageIndex: _currentImageIndex,
                          ),
                        );
                      },
                      child: const Text('进入集字模式'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 关联字帖卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('关联字帖', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Center(child: Text('暂无关联字帖')),
                ],
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
          const TitleBar(),
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
              IconButton(icon: const Icon(Icons.file_download), onPressed: () {}),
              IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
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
