import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../../widgets/common/base_toolbar.dart';

class WorkDetailPage extends StatefulWidget {
  final int workId; // TODO: 换成实际的作品ID类型
  
  const WorkDetailPage({Key? key, required this.workId}) : super(key: key);

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BaseToolbar(
            enableDrag: true,
            leftActions: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              FilledButton.icon(
                onPressed: () {
                  // 打开集字操作面板
                },
                icon: const Icon(Icons.edit),
                label: const Text('集字'),
              ),
            ],
            rightActions: [
              IconButton(icon: const Icon(Icons.file_download), onPressed: () {}),
              IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
            ],
          ),
          Expanded(
            child: IntrinsicHeight( // 使用 IntrinsicHeight
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
                children: [
                  // 左侧预览区 (70%)
                  Expanded(
                    flex: 7,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 尽可能小
                      children: [
                        // 图片预览区
                        Expanded(
                          child: Center(
                            child: Container(
                              color: Colors.grey[200],
                              child: Text('作品图片 $_currentImageIndex'),
                            ),
                          ),
                        ),
                        // 缩略图列表
                        SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5, // Demo data
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _currentImageIndex = index;
                                      });
                                    },
                                    child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(
                                        border: index == _currentImageIndex
                                          ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                                          : null,
                                        color: Colors.grey[300],
                                      ),
                                      child: Center(child: Text('$index')),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ),
                      ],
                    ),
                  ),
                  // 右侧信息面板 (30%)
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView( // 使用 SingleChildScrollView
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 基本信息卡片
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('基本信息', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('作品名称', '示例作品'),
                                    _buildInfoRow('作者', '张三'),
                                    _buildInfoRow('创作时间', '2024-01-01'),
                                    _buildInfoRow('书法风格', '楷书'),
                                    _buildInfoRow('书写工具', '毛笔'),
                                  ],
                                ),
                              ),
                            ),
                            // 采集信息卡片
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('采集信息', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('已采集字数', '12'),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: List.generate(
                                        12,
                                        (index) => Container(
                                          width: 40,
                                          height: 40,
                                          color: Colors.grey[200],
                                          child: Center(child: Text('字$index')),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
