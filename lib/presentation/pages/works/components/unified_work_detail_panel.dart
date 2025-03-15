import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/work_style.dart';
import '../../../../domain/enums/work_tool.dart';
import '../../../../domain/models/work/work_entity.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/work_detail_provider.dart';
import '../../../widgets/common/section_title.dart';
import '../../../widgets/common/tab_bar_theme_wrapper.dart';
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

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _remarkController;

  // Form state
  WorkStyle? _selectedStyle;
  WorkTool? _selectedTool;
  DateTime? _selectedDate;
  List<String> _tags = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Tab(text: '标签'),
                Tab(text: '集字信息'),
              ],
              labelStyle: theme.textTheme.titleSmall,
              unselectedLabelStyle: theme.textTheme.bodyMedium,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(context),
                _buildTagsTab(context),
                _buildCharactersTab(context),
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
      _initFormControllers();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this); // Added tab for tags
    _initFormControllers();
  }

  Widget _buildBasicInfoDisplay(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('标题', widget.work.title),
        _buildInfoRow('作者', widget.work.author),
        _buildInfoRow('风格', widget.work.style.label),
        _buildInfoRow('工具', widget.work.tool.label),
        _buildInfoRow('创作时间', _formatDate(widget.work.creationDate)),
        _buildInfoRow('图片数量', (widget.work.imageCount ?? 0).toString()),
        _buildInfoRow('创建时间', _formatDateTime(widget.work.createTime)),
        _buildInfoRow('修改时间', _formatDateTime(widget.work.updateTime)),
        if (widget.work.remark != null && widget.work.remark!.isNotEmpty)
          _buildRemarkSection(context),
      ],
    );
  }

  Widget _buildBasicInfoTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      children: [
        widget.isEditing
            ? _buildEditForm(context)
            : _buildBasicInfoDisplay(context),
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
            child: Center(
              child: Text('尚未从此作品中提取字形'),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              charCount.clamp(0, 20),
              (index) => _buildCharacterChip(context),
            ),
          ),
        if (charCount > 20)
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: Navigate to characters list page
              },
              child: const Text('查看全部'),
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

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '创作日期',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(1500),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
              _updateWorkField('creationDate', date);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
            ),
            child: Text(
              _selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                  : '未设置',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '基本信息'),
        const SizedBox(height: AppSizes.spacingMedium),
        _buildFormField(
          label: '作品名称',
          controller: _titleController,
          onChanged: (value) => _updateWorkField('title', value),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        _buildFormField(
          label: '作者',
          controller: _authorController,
          onChanged: (value) => _updateWorkField('author', value),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        _buildStyleDropdown(),
        const SizedBox(height: AppSizes.spacingSmall),
        _buildToolDropdown(),
        const SizedBox(height: AppSizes.spacingSmall),
        _buildDatePicker(),
        const SizedBox(height: AppSizes.spacingSmall),
        _buildFormField(
          label: '备注',
          controller: _remarkController,
          onChanged: (value) => _updateWorkField('remark', value),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onChanged: onChanged,
        ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarkSection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '备注:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(widget.work.remark!),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '作品风格',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<WorkStyle>(
          value: _selectedStyle,
          items: WorkStyle.values
              .map((style) => DropdownMenuItem(
                    value: style,
                    child: Text(style.label),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedStyle = value);
              _updateWorkField('style', value);
            }
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsTab(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '标签管理',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            if (widget.isEditing)
              TagEditor(
                tags: _tags,
                suggestedTags: const [
                  '行书',
                  '楷书',
                  '隶书',
                  '草书',
                  '真迹',
                  '拓片',
                  '碑帖',
                  '字帖',
                  '宋代',
                  '元代',
                  '明代',
                  '清代',
                ],
                onTagsChanged: (updatedTags) {
                  setState(() => _tags = updatedTags);
                  ref
                      .read(workDetailProvider.notifier)
                      .updateWorkTags(updatedTags);
                },
                chipColor: theme.colorScheme.primaryContainer,
                textColor: theme.colorScheme.onPrimaryContainer,
              )
            else if (_tags.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.spacingLarge),
                  child: Text('没有标签'),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ))
                    .toList(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '使用工具',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<WorkTool>(
          value: _selectedTool,
          items: WorkTool.values
              .map((tool) => DropdownMenuItem(
                    value: tool,
                    child: Text(tool.label),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedTool = value);
              _updateWorkField('tool', value);
            }
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
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

  void _initFormControllers() {
    _titleController = TextEditingController(text: widget.work.title);
    _authorController = TextEditingController(text: widget.work.author);
    _remarkController = TextEditingController(text: widget.work.remark);
    _selectedStyle = widget.work.style;
    _selectedTool = widget.work.tool;
    _selectedDate = widget.work.creationDate;
    _tags = List.from(widget.work.tags);
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
    }
    notifier.markAsChanged();
  }
}
