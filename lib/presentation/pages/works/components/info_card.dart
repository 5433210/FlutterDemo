import 'package:flutter/material.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../../theme/app_sizes.dart';

/// 作品信息卡片
class InfoCard extends StatelessWidget {
  final WorkEntity work;
  final bool isEditMode;
  final Function(String)? onTitleEdit;
  final Function(String)? onAuthorEdit;
  final Function(String)? onStyleEdit;
  final Function(String)? onToolEdit;
  final Function(DateTime)? onDateEdit;
  final Function(String)? onRemarkEdit;

  const InfoCard({
    super.key,
    required this.work,
    this.isEditMode = false,
    this.onTitleEdit,
    this.onAuthorEdit,
    this.onStyleEdit,
    this.onToolEdit,
    this.onDateEdit,
    this.onRemarkEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              '基本信息',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.m),

            // Info rows
            _buildInfoRow(
              context,
              '标题',
              work.title,
              onEdit: isEditMode ? () => _showTitleEditor(context) : null,
            ),
            _buildInfoRow(
              context,
              '作者',
              work.author ?? '未知',
              onEdit: isEditMode ? () => _showAuthorEditor(context) : null,
            ),
            _buildInfoRow(
              context,
              '画风',
              work.style.toString().split('.').last,
              onEdit: isEditMode ? () => _showStyleEditor(context) : null,
            ),
            _buildInfoRow(
              context,
              '工具',
              work.tool.toString().split('.').last,
              onEdit: isEditMode ? () => _showToolEditor(context) : null,
            ),
            _buildInfoRow(
              context,
              '创作日期',
              work.creationDate.toString().split(' ')[0] ?? '未知',
              onEdit: isEditMode ? () => _showDateEditor(context) : null,
            ),
            if (work.remark?.isNotEmpty == true)
              _buildInfoRow(
                context,
                '备注',
                work.remark!,
                onEdit: isEditMode ? () => _showRemarkEditor(context) : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onEdit,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextEditor(
    BuildContext context,
    String title,
    String initialValue, {
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: initialValue);
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('确定'),
        ),
      ],
    );
  }

  void _showAuthorEditor(BuildContext context) async {
    if (onAuthorEdit == null) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _buildTextEditor(
        context,
        '编辑作者',
        work.author ?? '',
      ),
    );
    if (result != null) {
      onAuthorEdit!(result);
    }
  }

  void _showDateEditor(BuildContext context) async {
    if (onDateEdit == null) return;
    final result = await showDatePicker(
      context: context,
      initialDate: work.creationDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (result != null) {
      onDateEdit!(result);
    }
  }

  void _showRemarkEditor(BuildContext context) async {
    if (onRemarkEdit == null) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _buildTextEditor(
        context,
        '编辑备注',
        work.remark ?? '',
        maxLines: 5,
      ),
    );
    if (result != null) {
      onRemarkEdit!(result);
    }
  }

  void _showStyleEditor(BuildContext context) async {
    if (onStyleEdit == null) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _buildTextEditor(
        context,
        '编辑画风',
        work.style.toString().split('.').last,
      ),
    );
    if (result != null) {
      onStyleEdit!(result);
    }
  }

  void _showTitleEditor(BuildContext context) async {
    if (onTitleEdit == null) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _buildTextEditor(
        context,
        '编辑标题',
        work.title,
      ),
    );
    if (result != null) {
      onTitleEdit!(result);
    }
  }

  void _showToolEditor(BuildContext context) async {
    if (onToolEdit == null) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _buildTextEditor(
        context,
        '编辑工具',
        work.tool.toString().split('.').last,
      ),
    );
    if (result != null) {
      onToolEdit!(result);
    }
  }
}
