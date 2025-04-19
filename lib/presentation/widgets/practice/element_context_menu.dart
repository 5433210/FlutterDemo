import 'package:flutter/material.dart';

import 'practice_edit_controller.dart';

/// 元素上下文菜单
class ElementContextMenu extends StatelessWidget {
  /// 元素
  final Map<String, dynamic> element;
  
  /// 控制器
  final PracticeEditController controller;
  
  /// 上移一层回调
  final VoidCallback onMoveUp;
  
  /// 下移一层回调
  final VoidCallback onMoveDown;
  
  /// 置于顶层回调
  final VoidCallback onBringToFront;
  
  /// 置于底层回调
  final VoidCallback onSendToBack;
  
  /// 组合元素回调
  final VoidCallback onGroup;
  
  /// 构造函数
  const ElementContextMenu({
    Key? key,
    required this.element,
    required this.controller,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onBringToFront,
    required this.onSendToBack,
    required this.onGroup,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isLocked = element['isLocked'] == true;
    final id = element['id'] as String;
    final isGroup = element['type'] == 'group';
    final hasMultipleSelection = controller.state.selectedElementIds.length > 1;
    
    return SimpleDialog(
      title: const Text('元素操作'),
      children: [
        // 锁定/解锁
        ListTile(
          leading: Icon(isLocked ? Icons.lock_open : Icons.lock),
          title: Text(isLocked ? '解锁元素' : '锁定元素'),
          onTap: () {
            Navigator.of(context).pop();
            controller.toggleElementLock(id);
          },
        ),
        
        const Divider(),
        
        // 层级管理
        ListTile(
          leading: const Icon(Icons.arrow_upward),
          title: const Text('上移一层'),
          onTap: () {
            Navigator.of(context).pop();
            onMoveUp();
          },
        ),
        ListTile(
          leading: const Icon(Icons.arrow_downward),
          title: const Text('下移一层'),
          onTap: () {
            Navigator.of(context).pop();
            onMoveDown();
          },
        ),
        ListTile(
          leading: const Icon(Icons.vertical_align_top),
          title: const Text('置于顶层'),
          onTap: () {
            Navigator.of(context).pop();
            onBringToFront();
          },
        ),
        ListTile(
          leading: const Icon(Icons.vertical_align_bottom),
          title: const Text('置于底层'),
          onTap: () {
            Navigator.of(context).pop();
            onSendToBack();
          },
        ),
        
        const Divider(),
        
        // 组合/解组
        if (hasMultipleSelection)
          ListTile(
            leading: const Icon(Icons.group_work),
            title: const Text('组合元素'),
            onTap: () {
              Navigator.of(context).pop();
              onGroup();
            },
          ),
        
        if (isGroup)
          ListTile(
            leading: const Icon(Icons.unarchive),
            title: const Text('解除组合'),
            onTap: () {
              Navigator.of(context).pop();
              controller.ungroupSelectedElement();
            },
          ),
        
        const Divider(),
        
        // 删除
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('删除', style: TextStyle(color: Colors.red)),
          onTap: () {
            Navigator.of(context).pop();
            controller.deleteSelectedElements();
          },
        ),
      ],
    );
  }
}
