import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';

/// 元素通用属性面板：显示和编辑元素的锁定状态、隐藏状态和名称
class ElementCommonPropertyPanel extends StatelessWidget {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final PracticeEditController controller;

  const ElementCommonPropertyPanel({
    Key? key,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 从元素数据中获取基本属性
    final isLocked = element['isLocked'] as bool? ?? false;
    final isHidden = element['isHidden'] as bool? ?? false;
    final name = element['name'] as String? ?? '未命名元素';

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '基本属性',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 元素名称
              TextField(
                controller: TextEditingController(text: name),
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  onElementPropertiesChanged({'name': value});
                },
              ),
              const SizedBox(height: 16),

              // 元素透明度
              Row(
                children: [
                  const Text('透明度:'),
                  Expanded(
                    child: Slider(
                      value: (element['opacity'] as num?)?.toDouble() ?? 1.0,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: ((element['opacity'] as num?)?.toDouble() ?? 1.0)
                          .toStringAsFixed(1),
                      onChanged: (value) {
                        // 拖动过程中实时预览
                        controller.updateElementOpacity(element['id'], value,
                            isInteractive: true);
                      },
                      onChangeEnd: (value) {
                        // 拖动结束时记录历史
                        controller.updateElementOpacity(element['id'], value);
                      },
                    ),
                  ),
                  Text(((element['opacity'] as num?)?.toDouble() ?? 1.0)
                      .toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 12),

              // 位置和尺寸信息（只读）
              Text(
                  '位置: X=${(element['x'] as num).toInt()}, Y=${(element['y'] as num).toInt()}'),
              Text(
                  '尺寸: 宽=${(element['width'] as num).toInt()}, 高=${(element['height'] as num).toInt()}'),
              const SizedBox(height: 12),

              // 锁定和隐藏切换
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 锁定切换
                  FilterChip(
                    label: const Text('锁定'),
                    selected: isLocked,
                    onSelected: (selected) {
                      onElementPropertiesChanged({'isLocked': selected});
                    },
                    avatar: isLocked
                        ? const Icon(Icons.lock, size: 18)
                        : const Icon(Icons.lock_open, size: 18),
                  ),
                  // 隐藏切换
                  FilterChip(
                    label: const Text('隐藏'),
                    selected: isHidden,
                    onSelected: (selected) {
                      onElementPropertiesChanged({'isHidden': selected});
                    },
                    avatar: isHidden
                        ? const Icon(Icons.visibility_off, size: 18)
                        : const Icon(Icons.visibility, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
