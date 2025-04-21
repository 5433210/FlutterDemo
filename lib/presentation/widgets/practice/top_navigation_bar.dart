import 'package:flutter/material.dart';

import 'file_operations.dart';
import 'practice_edit_controller.dart';

/// 顶部导航栏
class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final PracticeEditController controller;
  final String? practiceId;
  final bool isPreviewMode;
  final VoidCallback onTogglePreviewMode;
  final bool showThumbnails;
  final Function(bool) onThumbnailToggle;

  const TopNavigationBar({
    Key? key,
    required this.controller,
    this.practiceId,
    required this.isPreviewMode,
    required this.onTogglePreviewMode,
    required this.showThumbnails,
    required this.onThumbnailToggle,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(controller.practiceTitle ?? '字帖编辑'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: '返回',
        onPressed: () => _handleBackButton(context),
      ),
      actions: [
        // 文件操作组
        _buildFileOperationsGroup(context),

        const SizedBox(width: 16),

        // 视图操作组
        _buildViewOperationsGroup(),

        const SizedBox(width: 16),

        // 操作组
        _buildOperationsGroup(),

        const SizedBox(width: 16),

        // 预览组
        _buildPreviewGroup(),
      ],
    );
  }

  /// 构建文件操作组
  Widget _buildFileOperationsGroup(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: '保存',
          onPressed: () => _savePractice(context),
        ),
        IconButton(
          icon: const Icon(Icons.save_as),
          tooltip: '另存为',
          onPressed: () => _saveAs(context),
        ),
        IconButton(
          icon: const Icon(Icons.print),
          tooltip: '打印',
          onPressed: () => _printPractice(context),
        ),
        IconButton(
          icon: const Icon(Icons.file_download),
          tooltip: '导出',
          onPressed: () => _exportPractice(context),
        ),
      ],
    );
  }

  /// 构建操作组
  Widget _buildOperationsGroup() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: '撤销',
          onPressed:
              controller.undoRedoManager.canUndo ? controller.undo : null,
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: '重做',
          onPressed:
              controller.undoRedoManager.canRedo ? controller.redo : null,
        ),
      ],
    );
  }

  /// 构建预览组
  Widget _buildPreviewGroup() {
    return IconButton(
      icon: Icon(isPreviewMode ? Icons.visibility_off : Icons.visibility),
      tooltip: isPreviewMode ? '退出预览模式' : '预览模式',
      onPressed: onTogglePreviewMode,
    );
  }

  /// 构建视图操作组
  Widget _buildViewOperationsGroup() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            showThumbnails ? Icons.view_carousel : Icons.view_carousel_outlined,
          ),
          tooltip: showThumbnails ? '隐藏页面缩略图' : '显示页面缩略图',
          onPressed: () => onThumbnailToggle(!showThumbnails),
        ),
      ],
    );
  }

  /// 导出字帖
  Future<void> _exportPractice(BuildContext context) async {
    await FileOperations.exportPractice(
      context,
      controller.state.pages,
    );
  }

  /// 处理返回按钮
  Future<void> _handleBackButton(BuildContext context) async {
    // 检查是否有未保存的修改
    if (controller.state.hasUnsavedChanges) {
      // 显示确认对话框
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('未保存的修改'),
            content: const Text('你有未保存的修改，确定要离开吗？'),
            actions: <Widget>[
              TextButton(
                child: const Text('取消'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('离开'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
              TextButton(
                child: const Text('保存并离开'),
                onPressed: () async {
                  // 保存修改
                  await _savePractice(context);
                  // 返回true表示确认离开
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      // 如果用户确认要离开，则返回
      if (result == true) {
        Navigator.of(context).pop();
      }
    } else {
      // 没有未保存的修改，直接返回
      Navigator.of(context).pop();
    }
  }

  /// 打印字帖
  Future<void> _printPractice(BuildContext context) async {
    await FileOperations.printPractice(
      context,
      controller.state.pages,
    );
  }

  /// 另存为
  Future<void> _saveAs(BuildContext context) async {
    await FileOperations.saveAs(
      context,
      controller.state.pages,
      controller.state.layers.cast<Map<String, dynamic>>(),
      controller,
    );
  }

  /// 保存字帖
  Future<void> _savePractice(BuildContext context) async {
    await FileOperations.savePractice(
      context,
      controller.state.pages,
      controller.state.layers.cast<Map<String, dynamic>>(),
      practiceId,
      controller,
    );
  }
}
