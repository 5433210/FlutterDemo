import 'package:flutter/material.dart';

import '../../common/persistent_expansion_tile.dart';

/// Material 3 共享面板样式工具类
/// 用于确保所有属性面板具有一致的视觉风格
class M3PanelStyles {
  /// 构建信息提示框
  static Widget buildInfoBox({
    required BuildContext context,
    required String message,
    bool isWarning = false,
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = isWarning
        ? colorScheme.tertiaryContainer.withAlpha(76) // 0.3 透明度
        : colorScheme.primaryContainer.withAlpha(76); // 0.3 透明度

    final textColor = isWarning ? colorScheme.tertiary : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon ?? (isWarning ? Icons.warning_amber : Icons.info_outline),
              color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标准的面板卡片
  static Widget buildPanelCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
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
          initiallyExpanded: initiallyExpanded,
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

  /// 构建带有状态持久化功能的面板卡片
  static Widget buildPersistentPanelCard({
    required BuildContext context,
    required String panelId,
    required String title,
    required List<Widget> children,
    bool defaultExpanded = true,
  }) {
    return PersistentPanelCard(
      panelId: panelId,
      title: title,
      defaultExpanded: defaultExpanded,
      children: children,
    );
  }

  /// 构建预览容器
  static Widget buildPreviewContainer({
    required BuildContext context,
    required Widget child,
    Color? backgroundColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: child,
    );
  }

  /// 构建标题文本
  static Widget buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建标准的滑块控件
  static Widget buildSlider({
    required BuildContext context,
    required double value,
    required double min,
    required double max,
    required String label,
    required Function(double) onChanged,
    int? divisions,
    String? suffix,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: suffix != null ? '$label$suffix' : label,
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.surfaceContainerHighest,
            thumbColor: colorScheme.primary,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            suffix != null ? '$label$suffix' : label,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
