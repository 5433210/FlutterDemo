import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/value_objects/work/work_entity.dart';
import '../../../../theme/app_sizes.dart';
import '../../../widgets/common/tab_bar_theme_wrapper.dart';

class WorkDetailInfoPanel extends ConsumerStatefulWidget {
  final WorkEntity work;

  const WorkDetailInfoPanel({
    super.key,
    required this.work,
  });

  @override
  ConsumerState<WorkDetailInfoPanel> createState() =>
      _WorkDetailInfoPanelState();
}

class _WorkDetailInfoPanelState extends ConsumerState<WorkDetailInfoPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          // Tab 标签栏
          TabBarThemeWrapper(
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '基本信息'),
                Tab(text: '集字信息'),
              ],
              labelStyle: theme.textTheme.titleSmall,
              unselectedLabelStyle: theme.textTheme.bodyMedium,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),

          // 内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 基本信息 Tab
                _buildBasicInfoTab(context),

                // 集字信息 Tab
                _buildCharactersTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(context, '作品名称', widget.work.name),
        _buildInfoRow(context, '作者', widget.work.author ?? '未知'),
        _buildInfoRow(context, '风格', widget.work.style!.label),
        _buildInfoRow(context, '工具', widget.work.tool!.label),
        _buildInfoRow(context, '创作时间', _formatDate(widget.work.creationDate)),
        _buildInfoRow(
            context, '图片数量', (widget.work.imageCount ?? 0).toString()),
        _buildInfoRow(context, '创建时间', _formatDateTime(widget.work.createTime)),
        _buildInfoRow(context, '修改时间', _formatDateTime(widget.work.updateTime)),
        if (widget.work.remark != null && widget.work.remark!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('备注:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.work.remark!),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfoTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      children: [
        _buildBasicInfoSection(context),
        const SizedBox(height: AppSizes.spacingLarge),
        _buildMetadataSection(context),
      ],
    );
  }

  Widget _buildCharacterChip(BuildContext context, dynamic charInfo) {
    // 这里应该显示提取的字形缩略图或字符
    // 简化处理，实际项目中应当基于已提取的字形数据构建
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
    final charCount = widget.work.collectedChars.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          children: [
            Text('$charCount 个', style: theme.textTheme.bodySmall),
          ],
        ),

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
              Math.min(charCount, 20), // 最多显示20个
              (index) => _buildCharacterChip(
                context,
                widget.work.collectedChars[index],
              ),
            ),
          ),

        if (charCount > 20)
          Center(
            child: TextButton(
              onPressed: () {
                // 导航到字形列表页
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
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

  Widget _buildMetadataSection(BuildContext context) {
    final theme = Theme.of(context);
    final hasTags = widget.work.metadata?.tags != null &&
        widget.work.metadata!.tags.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          children: [
            Icon(Icons.label_outline,
                size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('标签', style: theme.textTheme.titleMedium),
          ],
        ),
        const Divider(),

        if (!hasTags)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text('没有标签'),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.work.metadata!.tags
                .map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ))
                .toList(),
          ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未知';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '未知';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
