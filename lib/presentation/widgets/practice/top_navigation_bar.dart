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
      title: const Text('字帖编辑'),
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
    );
  }

  /// 保存字帖
  Future<void> _savePractice(BuildContext context) async {
    await FileOperations.savePractice(
      context,
      controller.state.pages,
      controller.state.layers.cast<Map<String, dynamic>>(),
      practiceId,
    );
  }
}
