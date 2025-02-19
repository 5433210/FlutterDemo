import 'package:flutter/material.dart';

class CharacterDetailView extends StatelessWidget {
  final String charId;
  final bool showSourceButton;

  const CharacterDetailView({
    Key? key,
    required this.charId,
    this.showSourceButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 使用 LayoutBuilder 获取父容器约束
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算合适的内边距
        final padding = constraints.maxWidth * 0.05; // 5% 的边距
        // 计算预览区和信息区的比例
        final previewFlex = constraints.maxHeight > constraints.maxWidth ? 2 : 3;
        
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 集字预览区
              Expanded(
                flex: previewFlex,
                child: Card(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.8, // 最大宽度为容器的80%
                        maxHeight: constraints.maxHeight * 0.6, // 最大高度为容器的60%
                      ),
                      child: AspectRatio(
                        aspectRatio: 1, // 保持正方形
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Center(
                            child: Text('集字预览: $charId'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 信息面板
              Expanded(
                flex: 2,
                child: Card(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ...原有的信息面板内容...
                          _buildInfoSection('基本信息', [
                            _buildInfoRow('简体字', '永'),
                            _buildInfoRow('繁体字', '永'),
                            _buildInfoRow('风格', '楷书'),
                            _buildInfoRow('工具', '毛笔'),
                          ]),
                          const SizedBox(height: 16),
                          _buildInfoSection('来源信息', [
                            _buildInfoRow('作品', '兰亭序'),
                            _buildInfoRow('位置', '第1页'),
                            _buildInfoRow('采集时间', '2024-01-01'),
                            if (showSourceButton) ...[
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: 实现查看原作功能
                                },
                                child: const Text('查看原作'),
                              ),
                            ],
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
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
}
