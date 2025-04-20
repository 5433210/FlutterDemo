import 'package:flutter/material.dart';

/// 图层信息面板组件
/// 用于在各种元素的属性面板中显示图层信息（只读）
class LayerInfoPanel extends StatelessWidget {
  final Map<String, dynamic>? layer;

  const LayerInfoPanel({
    Key? key,
    required this.layer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (layer == null) return const SizedBox.shrink();

    return ExpansionTile(
      title: const Text('图层信息'),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图层名称
              Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text('图层名称',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text(layer!['name'] as String? ?? '未命名图层'),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              // 图层可见性
              Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text('可见性',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Icon(
                    (layer!['isVisible'] as bool? ?? true)
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: 20,
                    color: (layer!['isVisible'] as bool? ?? true)
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text((layer!['isVisible'] as bool? ?? true)
                      ? '可见'
                      : '隐藏'),
                ],
              ),
              const SizedBox(height: 8.0),

              // 图层锁定状态
              Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text('锁定状态',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Icon(
                    (layer!['isLocked'] as bool? ?? false)
                        ? Icons.lock
                        : Icons.lock_open,
                    size: 20,
                    color: (layer!['isLocked'] as bool? ?? false)
                        ? Colors.orange
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text((layer!['isLocked'] as bool? ?? false)
                      ? '已锁定'
                      : '未锁定'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
