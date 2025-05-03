import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';

/// 基础筛选面板类，为作品浏览和字符管理页面提供统一的筛选界面
abstract class M3FilterPanelBase<T> extends StatelessWidget {
  /// 当前筛选条件
  final T filter;

  /// 筛选条件变化时的回调
  final ValueChanged<T> onFilterChanged;

  /// 面板宽度
  final double width;

  /// 是否允许折叠面板
  final bool collapsible;

  /// 是否已展开
  final bool isExpanded;

  /// 展开/折叠状态变化时的回调
  final VoidCallback? onToggleExpand;

  /// 构造函数
  const M3FilterPanelBase({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    this.width = AppSizes.filterPanelWidth,
    this.collapsible = true,
    this.isExpanded = true,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    // 如果支持折叠并且当前已折叠，则显示折叠状态
    if (collapsible && !isExpanded) {
      return _buildCollapsedPanel(context, l10n);
    }

    return Material(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            _buildHeader(context, l10n),

            // 内容区域
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 各筛选部分
                          ...buildFilterSections(context),

                          const SizedBox(height: AppSizes.m),

                          // 重置按钮
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.filterReset),
                              onPressed: resetFilters,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建筛选面板中的各个部分，子类需要实现
  List<Widget> buildFilterSections(BuildContext context);

  /// 创建一个筛选部分卡片
  Widget buildSectionCard(BuildContext context, Widget child) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      margin: const EdgeInsets.only(bottom: AppSizes.m),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s),
        child: child,
      ),
    );
  }

  /// 获取筛选面板标题，子类需要实现
  String getFilterTitle(AppLocalizations l10n);

  /// 重置筛选条件，子类需要实现
  void resetFilters();

  /// 构建折叠状态的面板
  Widget _buildCollapsedPanel(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onToggleExpand,
        child: Container(
          width: 32,
          alignment: Alignment.center,
          child: RotatedBox(
            quarterTurns: 1,
            child: Tooltip(
              message: l10n.filterExpand,
              child: const Icon(Icons.tune),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSizes.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              getFilterTitle(l10n),
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (collapsible)
            Tooltip(
              message: l10n.filterCollapse,
              child: IconButton(
                onPressed: onToggleExpand,
                icon: const Icon(Icons.chevron_left),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(0),
              ),
            ),
        ],
      ),
    );
  }
}
