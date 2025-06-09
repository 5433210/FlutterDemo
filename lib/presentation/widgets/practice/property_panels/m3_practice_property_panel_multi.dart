import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../practice_edit_controller.dart';
import 'm3_panel_styles.dart';
import 'm3_practice_property_panel_base.dart';
import '../../../../infrastructure/logging/edit_page_logger_extension.dart';

/// Material 3 多选属性面板
class M3MultiSelectionPropertyPanel extends M3PracticePropertyPanel {
  final List<String> selectedIds;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const M3MultiSelectionPropertyPanel({
    super.key,
    required PracticeEditController controller,
    required this.selectedIds,
    required this.onElementPropertiesChanged,
  }) : super(controller: controller);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 获取所有选中的元素
    final elements = selectedIds
        .map((id) => controller.state.currentPageElements.firstWhere(
            (e) => e['id'] == id,
            orElse: () => <String, dynamic>{}))
        .where((e) => e.isNotEmpty)
        .toList();

    EditPageLogger.propertyPanelDebug(
      '多选属性面板构建',
      data: {
        'selectedCount': selectedIds.length,
        'validElementsCount': elements.length,
        'selectedIds': selectedIds,
        'operation': 'multi_panel_build',
      },
    );

    if (elements.isEmpty) {
      EditPageLogger.propertyPanelDebug(
        '多选属性面板：无有效元素',
        data: {
          'selectedIds': selectedIds,
          'operation': 'no_valid_elements',
        },
      );
      
      return Center(
        child: Text(
          l10n.noElementsSelected,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // 计算共同属性
    final commonOpacity = _getCommonOpacity(elements);
    final commonLocked = _getCommonLocked(elements);
    final commonHidden = _getCommonHidden(elements);
    final commonLayerId = _getCommonLayerId(elements);

    EditPageLogger.propertyPanelDebug(
      '多选共同属性计算',
      data: {
        'selectedCount': selectedIds.length,
        'commonOpacity': commonOpacity,
        'commonLocked': commonLocked,
        'commonHidden': commonHidden,
        'commonLayerId': commonLayerId,
        'operation': 'common_properties_calculation',
      },
    );

    // 获取图层信息
    final layer = commonLayerId != null
        ? controller.state.layers.firstWhere(
            (l) => l['id'] == commonLayerId,
            orElse: () => <String, dynamic>{},
          )
        : null;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        // 多选标题
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.select_all,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.selected}: ${selectedIds.length} ${l10n.elements}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // 多选操作面板 - 基本属性
        M3PanelStyles.buildPersistentPanelCard(
          context: context,
          panelId: 'multi_selection_basic_properties',
          title: l10n.commonProperties,
          defaultExpanded: true,
          children: [
            // ...existing code... (锁定和可见性控制等)
            // 锁定和可见性控制
            Row(
              children: [
                // 锁定控制
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        l10n.locked,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: commonLocked ?? false,
                      activeColor: colorScheme.primary,
                      onChanged: commonLocked != null
                          ? (value) {
                              _updateAllElements('locked', value);
                            }
                          : null,
                      secondary: Icon(
                        commonLocked == true ? Icons.lock : Icons.lock_open,
                        color: commonLocked == true
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      dense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 可见性控制
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        l10n.visible,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: !(commonHidden ?? false),
                      activeColor: colorScheme.primary,
                      onChanged: commonHidden != null
                          ? (value) {
                              _updateAllElements('hidden', !value);
                            }
                          : null,
                      secondary: Icon(
                        commonHidden == true
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: commonHidden == true
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.primary,
                      ),
                      dense: true,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 透明度控制
            if (commonOpacity != null) ...[
              Text(
                '${l10n.opacity}:',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: commonOpacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label: '${(commonOpacity * 100).round()}%',
                          activeColor: colorScheme.primary,
                          thumbColor: colorScheme.primary,
                          inactiveColor: colorScheme.surfaceContainerHighest,
                          onChanged: (value) {
                            _updateAllElements('opacity', value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${(commonOpacity * 100).round()}%',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 图层信息
            if (layer != null) ...[
              Text(
                '${l10n.layer}:',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.layers,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                    layer['name'] as String? ?? l10n.unnamedLayer,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (layer['isVisible'] as bool? ?? true)
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 16,
                        color: (layer['isVisible'] as bool? ?? true)
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        (layer['isLocked'] as bool? ?? false)
                            ? Icons.lock
                            : Icons.lock_open,
                        size: 16,
                        color: (layer['isLocked'] as bool? ?? false)
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  onTap: () {
                    // 选中图层
                    controller.selectLayer(layer['id'] as String);
                  },
                ),
              ),
            ],
          ],
        ),

        // 多选操作面板 - 对齐工具
        M3PanelStyles.buildPersistentPanelCard(
          context: context,
          panelId: 'multi_selection_alignment_tools',
          title: l10n.alignmentOperations,
          defaultExpanded: false,
          children: [
            // ...existing code... (对齐按钮等)
            // 水平对齐按钮
            Text(
              '${l10n.horizontalAlignment}:',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAlignmentButton(
                      context: context,
                      icon: Icons.align_horizontal_left,
                      tooltip: l10n.alignLeft,
                      onPressed: () => _alignElements('left'),
                      colorScheme: colorScheme,
                    ),
                    _buildAlignmentButton(
                      context: context,
                      icon: Icons.align_horizontal_center,
                      tooltip: l10n.alignHorizontalCenter,
                      onPressed: () => _alignElements('centerH'),
                      colorScheme: colorScheme,
                    ),
                    _buildAlignmentButton(
                      context: context,
                      icon: Icons.align_horizontal_right,
                      tooltip: l10n.alignRight,
                      onPressed: () => _alignElements('right'),
                      colorScheme: colorScheme,
                    ),
                    _buildAlignmentButton(
                      context: context,
                      icon: Icons.horizontal_distribute,
                      tooltip: l10n.distributeHorizontally,
                      onPressed: selectedIds.length > 2
                          ? () => _distributeElements('horizontal')
                          : null,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 垂直对齐按钮
            Text(
              '${l10n.verticalAlignment}:',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAlignmentButton(
                      context: context,
                      icon: Icons.align_vertical_top,
                      tooltip: l10n.alignTop,
                      onPressed: () => _alignElements('top'),
                      colorScheme: colorScheme,
                    ),
                    _buildAlignmentButton(
                      context: context,
                      icon: Icons.align_vertical_center,
                      tooltip: l10n.alignVerticalCenter,
                      onPressed: () => _alignElements('centerV'),
                      colorScheme: colorScheme,
                    ),
                    _buildAlignmentButton(
                      context: context,
                      icon: Icons.align_vertical_bottom,
                      tooltip: l10n.alignBottom,
                      onPressed: () => _alignElements('bottom'),
                      colorScheme: colorScheme,
                    ),
                    _buildAlignmentButton(
                      context: context,
                      icon: Icons.vertical_distribute,
                      tooltip: l10n.distributeVertically,
                      onPressed: selectedIds.length > 2
                          ? () => _distributeElements('vertical')
                          : null,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 多选操作面板 - 组合工具
        M3PanelStyles.buildPersistentPanelCard(
          context: context,
          panelId: 'multi_selection_group_tools',
          title: l10n.groupOperations,
          defaultExpanded: false,
          children: [
            // 组合按钮
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.group,
                  color: colorScheme.primary,
                ),
                title: Text(
                  l10n.group,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  l10n.groupElements,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  controller.groupSelectedElements();
                },
              ),
            ),
          ],
        ),

        // 多选操作面板 - 删除工具
        M3PanelStyles.buildPersistentPanelCard(
          context: context,
          panelId: 'multi_selection_delete_tools',
          title: l10n.practiceEditDangerZone,
          defaultExpanded: false,
          children: [
            // 删除按钮
            ElevatedButton.icon(
              onPressed: () {
                controller.deleteSelectedElements();
              },
              icon: Icon(
                Icons.delete,
                color: colorScheme.error,
                size: 18,
              ),
              label: Text(
                '${l10n.delete} (${selectedIds.length})',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.error,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 对齐元素
  void _alignElements(String alignment) {
    EditPageLogger.propertyPanelDebug(
      '多选元素对齐',
      data: {
        'selectedCount': selectedIds.length,
        'selectedIds': selectedIds,
        'alignment': alignment,
        'operation': 'multi_alignment',
      },
    );
    
    try {
      controller.alignElements(selectedIds, alignment);
    } catch (error, stackTrace) {
      EditPageLogger.propertyPanelError(
        '多选元素对齐失败',
        error: error,
        stackTrace: stackTrace,
        data: {
          'selectedIds': selectedIds,
          'alignment': alignment,
          'operation': 'multi_alignment_error',
        },
      );
    }
  }

  // 构建对齐按钮
  Widget _buildAlignmentButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
  }) {
    final bool isDisabled = onPressed == null;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: isDisabled
              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
              : colorScheme.primary,
        ),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: isDisabled
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : colorScheme.primaryContainer.withValues(alpha: 0.3),
          minimumSize: const Size(40, 40),
        ),
      ),
    );
  }

  // 分布元素
  void _distributeElements(String direction) {
    EditPageLogger.propertyPanelDebug(
      '多选元素分布',
      data: {
        'selectedCount': selectedIds.length,
        'selectedIds': selectedIds,
        'direction': direction,
        'operation': 'multi_distribution',
      },
    );
    
    try {
      controller.distributeElements(selectedIds, direction);
    } catch (error, stackTrace) {
      EditPageLogger.propertyPanelError(
        '多选元素分布失败',
        error: error,
        stackTrace: stackTrace,
        data: {
          'selectedIds': selectedIds,
          'direction': direction,
          'operation': 'multi_distribution_error',
        },
      );
    }
  }

  // 获取共同的可见性状态
  bool? _getCommonHidden(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    bool? commonHidden;
    for (var element in elements) {
      final isHidden = element['hidden'] as bool? ?? false;
      if (commonHidden == null) {
        commonHidden = isHidden;
      } else if (commonHidden != isHidden) {
        return null; // 有不同值，返回null
      }
    }
    return commonHidden;
  }

  // 获取共同的图层ID
  String? _getCommonLayerId(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    String? commonLayerId;
    for (var element in elements) {
      final layerId = element['layerId'] as String?;
      if (commonLayerId == null) {
        commonLayerId = layerId;
      } else if (commonLayerId != layerId) {
        return null; // 有不同值，返回null
      }
    }
    return commonLayerId;
  }

  // 获取共同的锁定状态
  bool? _getCommonLocked(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    bool? commonLocked;
    for (var element in elements) {
      final isLocked = element['locked'] as bool? ?? false;
      if (commonLocked == null) {
        commonLocked = isLocked;
      } else if (commonLocked != isLocked) {
        return null; // 有不同值，返回null
      }
    }
    return commonLocked;
  }

  // 获取共同的不透明度
  double? _getCommonOpacity(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    double? commonOpacity;
    for (var element in elements) {
      final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;
      if (commonOpacity == null) {
        commonOpacity = opacity;
      } else if ((commonOpacity - opacity).abs() > 0.001) {
        return null; // 有不同值，返回null（考虑浮点数精度）
      }
    }
    return commonOpacity;
  }

  // 更新所有选中元素的共同属性
  void _updateAllElements(String property, dynamic value) {
    EditPageLogger.propertyPanelDebug(
      '多选批量属性更新',
      data: {
        'selectedCount': selectedIds.length,
        'selectedIds': selectedIds,
        'property': property,
        'value': value,
        'operation': 'multi_batch_update',
      },
    );
    
    try {
      for (var id in selectedIds) {
        onElementPropertiesChanged({
          'id': id,
          property: value,
        });
      }
      
      EditPageLogger.propertyPanelDebug(
        '多选批量属性更新完成',
        data: {
          'selectedCount': selectedIds.length,
          'property': property,
          'value': value,
          'operation': 'multi_batch_update_complete',
        },
      );
    } catch (error, stackTrace) {
      EditPageLogger.propertyPanelError(
        '多选批量属性更新失败',
        error: error,
        stackTrace: stackTrace,
        data: {
          'selectedIds': selectedIds,
          'property': property,
          'value': value,
          'operation': 'multi_batch_update_error',
        },
      );
    }
  }
}
