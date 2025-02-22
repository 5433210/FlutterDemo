import 'package:flutter/material.dart';
import '../../widgets/window/title_bar.dart';
import 'practice_edit_page.dart';
import '../../widgets/preview/practice_preview.dart'; // 新建预览组件

class PracticeDetailPage extends StatefulWidget {
  final String practiceId;

  const PracticeDetailPage({
    super.key,
    required this.practiceId,
  });

  @override
  State<PracticeDetailPage> createState() => _PracticeDetailPageState();
}

class _PracticeDetailPageState extends State<PracticeDetailPage> {
  int _currentPageIndex = 0;

  Widget _buildPreviewArea() {
    return Column(
      children: [
        // 工具栏
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
                icon: const Icon(Icons.fit_screen),
                onPressed: () {},
                tooltip: '适应屏幕',
              ),
            ],
          ),
        ),
        // 主预览区
        Expanded(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(20.0),
            minScale: 0.5,
            maxScale: 4.0,
            child: PracticePreview(
              practiceId: widget.practiceId,
              pageIndex: _currentPageIndex,
            ),
          ),
        ),
        // 底部页面导航栏
        Container(
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5, // 示例页数
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = index == _currentPageIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _currentPageIndex = index);
                },
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 2,
                    ),
                    color: Colors.grey[200],
                  ),
                  child: Stack(
                    children: [
                      Center(child: Text('页 ${index + 1}')),
                      if (isSelected)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
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
          // 基本信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    '基本信息',
                    [
                      _buildInfoRow('标题', '示例字帖'),
                      _buildInfoRow('创建时间', '2024-01-01'),
                      _buildInfoRow('修改时间', '2024-01-01'),
                      _buildInfoRow('状态', '草稿'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 字体信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    '字体信息',
                    [
                      _buildInfoRow('已使用集字', '0'),
                      _buildInfoRow('字体风格', '楷书'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...children,
      ],
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

  // 添加打印和导出功能
  Future<void> _handlePrint() async {
    // TODO: 实现打印功能
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('打印'),
        content: const Text('打印功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport() async {
    // TODO: 实现导出功能
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('导出'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('导出为PDF'),
            ),
            ListTile(
              leading: Icon(Icons.image),
              title: Text('导出为图片'),
            ),
          ],
        ),
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
            title: const Text('字帖详情', style: TextStyle(fontSize: 20)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PracticeEditPage(
                      practiceId: widget.practiceId,
                    ),
                  ),
                ),
                tooltip: '编辑',
              ),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: _handlePrint,
                tooltip: '打印',
              ),
              IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: _handleExport,
                tooltip: '导出',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {},
                tooltip: '删除',
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          Expanded(
            child: Row(
              children: [
                // 左侧预览区 (70%宽度)
                Expanded(
                  flex: 7,
                  child: _buildPreviewArea(),
                ),
                // 右侧信息面板 (30%宽度)
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
