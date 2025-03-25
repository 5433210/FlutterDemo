import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/work_detail_provider.dart';
import '../../../widgets/common/tab_bar_theme_wrapper.dart';
import '../../../widgets/forms/work_form.dart';
import '../../../widgets/tag_editor.dart';

class UnifiedWorkDetailPanel extends ConsumerStatefulWidget {
  final WorkEntity work;
  final bool isEditing;

  const UnifiedWorkDetailPanel({
    super.key,
    required this.work,
    required this.isEditing,
  });

  @override
  ConsumerState<UnifiedWorkDetailPanel> createState() =>
      _UnifiedWorkDetailPanelState();
}

class _UnifiedWorkDetailPanelState extends ConsumerState<UnifiedWorkDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    // 确保每次构建时都使用最新的标签数据
    final tags = List<String>.from(widget.work.tags);

    return Card(
      margin: const EdgeInsets.only(
        top: AppSizes.spacingMedium,
        right: AppSizes.spacingMedium,
        bottom: AppSizes.spacingMedium,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          TabBarThemeWrapper(
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '基本信息'),
                Tab(text: '集字'),
                Tab(text: '标签'),
              ],
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(context),
                _buildCharactersTab(context),
                _buildTagsTab(context, tags),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(UnifiedWorkDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.work != widget.work ||
        oldWidget.isEditing != widget.isEditing) {
      setState(() {
        // 强制更新状态以反映新的数据
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this); // Added tab for tags
  }

  // Additional metadata not included in the form
  Widget _buildAdditionalMetadata(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          '其他信息',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        _buildInfoRow('图片数量', (widget.work.imageCount ?? 0).toString()),
        _buildInfoRow('创建时间', _formatDateTime(widget.work.createTime)),
        _buildInfoRow('修改时间', _formatDateTime(widget.work.updateTime)),
      ],
    );
  }

  Widget _buildBasicInfoTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      children: [
        // Use WorkForm for both view and edit modes
        WorkForm(
          title: '基本信息',
          initialTitle: widget.work.title,
          initialAuthor: widget.work.author,
          initialStyle: widget.work.style,
          initialTool: widget.work.tool,
          initialCreationDate: widget.work.creationDate,
          initialRemark: widget.work.remark,
          isProcessing: false,
          // Only enable editing in edit mode
          onTitleChanged: widget.isEditing
              ? (value) => _updateWorkField('title', value)
              : null,
          onAuthorChanged: widget.isEditing
              ? (value) => _updateWorkField('author', value)
              : null,
          onStyleChanged: widget.isEditing
              ? (value) => _updateWorkField('style', value)
              : null,
          onToolChanged: widget.isEditing
              ? (value) => _updateWorkField('tool', value)
              : null,
          onCreationDateChanged: widget.isEditing
              ? (value) => _updateWorkField('creationDate', value)
              : null,
          onRemarkChanged: widget.isEditing
              ? (value) => _updateWorkField('remark', value)
              : null,
          // Configure form appearance
          visibleFields: WorkFormPresets.editFields,
          requiredFields: {WorkFormField.title},
          showHelp: false,
          showKeyboardShortcuts: false,
        ),

        // Display additional metadata in view mode
        if (!widget.isEditing) ...[
          const SizedBox(height: AppSizes.spacingMedium),
          _buildAdditionalMetadata(context),
        ],
      ],
    );
  }

  Widget _buildCharacterChip(BuildContext context) {
    return Chip(
      avatar: const CircleAvatar(
        child: Icon(Icons.text_fields, size: 14),
      ),
      label: const Text('字'),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildCharactersSection(BuildContext context) {
    final theme = Theme.of(context);
    final charCount = widget.work.collectedChars.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$charCount 个', style: theme.textTheme.bodySmall),
        if (charCount == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: Text('暂无集字')),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              math.min(charCount, 20),
              (index) => _buildCharacterChip(context),
            ),
          ),
        if (charCount > 20)
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('查看更多'),
            ),
          ),
      ],
    );
  }

  Widget _buildCharactersTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      children: [
        _buildCharactersSection(context),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // 修改标签标签页构建方法，直接使用传入的标签数据
  Widget _buildTagsTab(BuildContext context, List<String> tags) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '标签管理',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TagEditor(
              tags: tags,
              readOnly: !widget.isEditing,
              onTagsChanged: (newTags) {
                _updateWorkField('tags', newTags);
              },
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未知';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '未知';
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  void _updateWorkField(String field, dynamic value) {
    final notifier = ref.read(workDetailProvider.notifier);
    switch (field) {
      case 'title':
        notifier.updateWorkBasicInfo(title: value);
        break;
      case 'author':
        notifier.updateWorkBasicInfo(author: value);
        break;
      case 'style':
        notifier.updateWorkBasicInfo(style: value);
        break;
      case 'tool':
        notifier.updateWorkBasicInfo(tool: value);
        break;
      case 'creationDate':
        notifier.updateWorkBasicInfo(creationDate: value);
        break;
      case 'remark':
        notifier.updateWorkBasicInfo(remark: value);
        break;
      case 'tags':
        // 使用专门的方法更新标签
        notifier.updateWorkTags(value);
        break;
    }
    notifier.markAsChanged();
  }
}
