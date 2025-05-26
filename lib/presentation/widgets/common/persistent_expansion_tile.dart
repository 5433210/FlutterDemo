import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/expansion_tile_provider.dart';

/// 带有状态持久化功能的 ExpansionTile
/// 自动保存和恢复展开/折叠状态
class PersistentExpansionTile extends ConsumerWidget {
  /// 唯一标识符，用于保存状态
  final String tileId;

  /// 标题组件
  final Widget title;

  /// 子组件列表
  final List<Widget> children;

  /// 默认是否展开
  final bool defaultExpanded;

  /// 背景颜色
  final Color? backgroundColor;

  /// 折叠时的图标颜色
  final Color? collapsedIconColor;

  /// 展开时的图标颜色
  final Color? iconColor;

  /// 子组件的内边距
  final EdgeInsetsGeometry? childrenPadding;

  /// 展开/折叠状态改变时的回调
  final ValueChanged<bool>? onExpansionChanged;

  /// 前导图标
  final Widget? leading;

  /// 副标题
  final Widget? subtitle;

  /// 尾随图标
  final Widget? trailing;

  /// 控制子组件的动画曲线
  final Curve expansionAnimationCurve;

  /// 控制是否启用交互
  final bool enabled;

  const PersistentExpansionTile({
    Key? key,
    required this.tileId,
    required this.title,
    required this.children,
    this.defaultExpanded = false,
    this.backgroundColor,
    this.collapsedIconColor,
    this.iconColor,
    this.childrenPadding,
    this.onExpansionChanged,
    this.leading,
    this.subtitle,
    this.trailing,
    this.expansionAnimationCurve = Curves.easeIn,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前 tile 的展开状态
    final isExpanded = ref.watch(tileExpandedWithDefaultProvider((
      tileId: tileId,
      defaultExpanded: defaultExpanded,
    )));

    // 获取 notifier 以便更新状态
    final notifier = ref.read(expansionTileProvider.notifier);
    return ExpansionTile(
      key: Key('persistent_expansion_tile_$tileId'),
      title: title,
      initiallyExpanded: isExpanded,
      backgroundColor: backgroundColor,
      collapsedIconColor: collapsedIconColor,
      iconColor: iconColor,
      childrenPadding: childrenPadding,
      leading: leading,
      subtitle: subtitle,
      trailing: trailing,
      enabled: enabled,
      onExpansionChanged: (expanded) async {
        // 更新持久化状态
        await notifier.setTileExpanded(tileId, expanded);

        // 调用外部回调
        onExpansionChanged?.call(expanded);
      },
      children: children,
    );
  }
}

/// 创建带有持久化状态的面板卡片的便捷方法
/// 这是对 M3PanelStyles.buildPanelCard 的持久化版本
class PersistentPanelCard extends ConsumerWidget {
  /// 面板的唯一标识符
  final String panelId;

  /// 面板标题
  final String title;

  /// 子组件列表
  final List<Widget> children;

  /// 默认是否展开
  final bool defaultExpanded;

  const PersistentPanelCard({
    Key? key,
    required this.panelId,
    required this.title,
    required this.children,
    this.defaultExpanded = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 获取当前面板的展开状态
    final isExpanded = ref.watch(tileExpandedWithDefaultProvider((
      tileId: panelId,
      defaultExpanded: defaultExpanded,
    )));

    // 获取 notifier 以便更新状态
    final notifier = ref.read(expansionTileProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 移除分割线
        ),
        child: ExpansionTile(
          key: Key('persistent_panel_card_$panelId'),
          initiallyExpanded: isExpanded,
          title: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          collapsedIconColor: colorScheme.onSurfaceVariant,
          iconColor: colorScheme.primary,
          childrenPadding: EdgeInsets.zero, // 移除默认内边距
          onExpansionChanged: (expanded) async {
            // 更新持久化状态
            await notifier.setTileExpanded(panelId, expanded);
          },
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
