import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../practice_edit_controller.dart';
import 'm3_practice_property_panel_base.dart';

/// Material 3 组合属性面板
class M3GroupPropertyPanel extends M3PracticePropertyPanel {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const M3GroupPropertyPanel({
    super.key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
  }) : super(controller: controller);

  @override
  Widget build(BuildContext context) {
    return _M3GroupPropertyPanelContent(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
    );
  }
}

class _M3GroupPropertyPanelContent extends StatefulWidget {
  final PracticeEditController controller;
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const _M3GroupPropertyPanelContent({
    required this.controller,
    required this.element,
    required this.onElementPropertiesChanged,
  });

  @override
  State<_M3GroupPropertyPanelContent> createState() =>
      _M3GroupPropertyPanelContentState();
}

class _M3GroupPropertyPanelContentState
    extends State<_M3GroupPropertyPanelContent> {
  // 🚀 优化：静态变量移至class级别
  static int _buildCount = 0;
  static String _lastGroupId = '';

  // 组名编辑控制器
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;
  bool _isEditingName = false;

  // 🚀 方案B：原始值追踪用于优化undo记录
  double? _originalOpacity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final name = widget.element['name'] as String? ?? l10n.unnamedGroup;
    final isLocked = widget.element['locked'] as bool? ?? false;
    final isHidden = widget.element['hidden'] as bool? ?? false;
    final opacity = (widget.element['opacity'] as num?)?.toDouble() ?? 1.0;
    final layerId = widget.element['layerId'] as String?;

    // 获取图层信息
    Map<String, dynamic>? layer;
    if (layerId != null) {
      layer = widget.controller.state.getLayerById(layerId);
    }

    // 获取组内元素
    final children = _getGroupChildren(widget.element['id'] as String);

    // 🚀 优化：减少分组属性面板的重复构建日志
    _buildCount++;
    final groupId = widget.element['id'] as String;
    final hasSignificantChange = groupId != _lastGroupId || _buildCount % 30 == 0;
    
    if (hasSignificantChange) {
      EditPageLogger.propertyPanelDebug(
        '分组属性面板构建',
        data: {
          'groupId': groupId,
          'childrenCount': children.length,
          'buildCount': _buildCount,
          'changeType': groupId != _lastGroupId ? 'group_change' : 'milestone',
          'optimization': 'group_panel_build_optimized',
        },
      );
      
      _lastGroupId = groupId;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        // 面板标题
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.group_work,
                size: 24,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.groupProperties,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // 基本信息面板
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.basicInfo,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 组名称
                _isEditingName
                    ? TextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        decoration: InputDecoration(
                          labelText: l10n.name,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                        onSubmitted: (_) => _applyNameChange(),
                      )
                    : Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          title: Text(
                            '${l10n.name}:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: l10n.rename,
                            onPressed: _startEditingName,
                          ),
                        ),
                      ),

                const SizedBox(height: 8),

                // 子元素数量
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListTile(
                    title: Text(
                      '${l10n.elements}:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${children.length} ${l10n.elements}',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 图层信息
                if (layer != null)
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      title: Text(
                        '${l10n.layer}:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        layer['name'] as String? ?? l10n.layer1,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.launch),
                        tooltip: l10n.selectTargetLayer,
                        onPressed: () {
                          if (layerId != null) {
                            widget.controller.selectLayer(layerId);
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 状态与显示
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.stateAndDisplay,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 锁定控制
                Card(
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
                    value: isLocked,
                    activeColor: colorScheme.primary,
                    onChanged: (value) {
                      _updateElementProperty('locked', value);
                    },
                    secondary: Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color: isLocked
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 可见性控制
                Card(
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
                    value: !isHidden,
                    activeColor: colorScheme.primary,
                    onChanged: (value) {
                      _updateElementProperty('hidden', !value);
                    },
                    secondary: Icon(
                      isHidden ? Icons.visibility_off : Icons.visibility,
                      color: isHidden
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 不透明度控制
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.opacity}:',
                      style: const TextStyle(
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
                                value: opacity,
                                min: 0.0,
                                max: 1.0,
                                divisions: 100,
                                label: '${(opacity * 100).round()}%',
                                activeColor: colorScheme.primary,
                                thumbColor: colorScheme.primary,
                                onChangeStart: (value) {
                                  // 🚀 方案B：拖动开始时保存原始值
                                  _originalOpacity = opacity;
                                },
                                onChanged: (value) {
                                  // 只更新UI，不记录undo
                                  _updateElementPropertyPreview('opacity', value);
                                },
                                onChangeEnd: (value) {
                                  // 拖动结束时基于原始值记录undo
                                  _updateElementPropertyWithUndo('opacity', value);
                                },
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                '${(opacity * 100).round()}%',
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
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 组操作
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.groupOperations,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 组操作按钮
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // 进入编辑组模式
                        ListTile(
                          leading: Icon(
                            Icons.edit,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            l10n.editGroupContents,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            l10n.editGroupContentsDescription,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () {
                            _enterGroupEditMode();
                          },
                        ),
                        const Divider(),
                        // 解组
                        ListTile(
                          leading: Icon(
                            Icons.unfold_more,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            l10n.ungroup,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            l10n.ungroupDescription,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () {
                            _ungroupElements();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 危险区域 - 删除组
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.dangerZone,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 删除按钮
                ElevatedButton.icon(
                  onPressed: () {
                    _deleteGroup();
                  },
                  icon: Icon(
                    Icons.delete,
                    color: colorScheme.error,
                    size: 18,
                  ),
                  label: Text(
                    l10n.deleteGroup,
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
          ),
        ),

        // 组内元素列表
        if (children.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_list_bulleted,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.groupElements,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 元素列表
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final element = children[index];
                      final elementName =
                          element['name'] as String? ?? l10n.unnamedElement;
                      final type = element['type'] as String;
                      final isHidden = element['hidden'] as bool? ?? false;
                      final isLocked = element['locked'] as bool? ?? false;
                      final opacity =
                          (element['opacity'] as num?)?.toDouble() ?? 1.0;

                      // 获取元素类型图标
                      IconData iconData;
                      switch (type) {
                        case 'text':
                          iconData = Icons.text_fields;
                          break;
                        case 'image':
                          iconData = Icons.image;
                          break;
                        case 'collection':
                          iconData = Icons.font_download;
                          break;
                        case 'group':
                          iconData = Icons.group_work;
                          break;
                        default:
                          iconData = Icons.crop_square;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 0),
                        elevation: 0,
                        color: colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            iconData,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            elementName,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${l10n.opacity}: ${(opacity * 100).round()}%',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isHidden
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 16,
                                color: isHidden
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLocked ? Icons.lock : Icons.lock_open,
                                size: 16,
                                color: isLocked
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void didUpdateWidget(_M3GroupPropertyPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中的元素发生变化时，更新名称控制器
    if (oldWidget.element['id'] != widget.element['id']) {
      final name = widget.element['name'] as String? ?? 'Group';
      _nameController.text = name;
      _isEditingName = false;
    }
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onFocusChange);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    final name = widget.element['name'] as String? ?? 'Group';
    _nameController = TextEditingController(text: name);
    _nameFocusNode = FocusNode();
    _nameFocusNode.addListener(_onFocusChange);
  }

  // 应用名称更改
  void _applyNameChange() {
    final newName = _nameController.text.trim();
    final groupId = widget.element['id'] as String;
    final oldName = widget.element['name'] as String? ?? 'Group';

    if (newName.isNotEmpty && newName != oldName) {
      EditPageLogger.propertyPanelDebug(
        '分组名称修改',
        data: {
          'groupId': groupId,
          'oldName': oldName,
          'newName': newName,
          'operation': 'group_rename',
        },
      );

      try {
        _updateElementProperty('name', newName);

        EditPageLogger.propertyPanelDebug(
          '分组名称修改成功',
          data: {
            'groupId': groupId,
            'newName': newName,
            'operation': 'group_rename_success',
          },
        );
      } catch (error, stackTrace) {
        EditPageLogger.propertyPanelError(
          '分组名称修改失败',
          error: error,
          stackTrace: stackTrace,
          data: {
            'groupId': groupId,
            'newName': newName,
            'operation': 'group_rename_error',
          },
        );
      }
    } else if (newName.isEmpty) {
      // 如果名称为空，恢复原来的名称
      _nameController.text = oldName;

      EditPageLogger.propertyPanelDebug(
        '分组名称恢复',
        data: {
          'groupId': groupId,
          'restoredName': oldName,
          'operation': 'group_name_restore',
        },
      );
    }

    setState(() {
      _isEditingName = false;
    });
  }

  // 删除组
  void _deleteGroup() {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final groupId = widget.element['id'] as String;
    final groupName = widget.element['name'] as String? ?? 'Group';
    final children = _getGroupChildren(groupId);

    EditPageLogger.propertyPanelDebug(
      '显示分组删除确认对话框',
      data: {
        'groupId': groupId,
        'groupName': groupName,
        'childrenCount': children.length,
        'operation': 'group_delete_dialog_show',
      },
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteGroupConfirm),
        content: Text(l10n.deleteMessage(1)),
        actions: [
          TextButton(
            onPressed: () {
              EditPageLogger.propertyPanelDebug(
                '取消删除分组',
                data: {
                  'groupId': groupId,
                  'groupName': groupName,
                  'operation': 'group_delete_cancelled',
                },
              );
              Navigator.of(context).pop();
            },
            child: Text(
              l10n.cancel,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();

              EditPageLogger.propertyPanelDebug(
                '确认删除分组',
                data: {
                  'groupId': groupId,
                  'groupName': groupName,
                  'childrenCount': children.length,
                  'operation': 'group_delete_confirmed',
                },
              );

              try {
                widget.controller.deleteElement(groupId);

                EditPageLogger.propertyPanelDebug(
                  '分组删除成功',
                  data: {
                    'groupId': groupId,
                    'groupName': groupName,
                    'operation': 'group_delete_success',
                  },
                );
              } catch (error, stackTrace) {
                EditPageLogger.propertyPanelError(
                  '分组删除失败',
                  error: error,
                  stackTrace: stackTrace,
                  data: {
                    'groupId': groupId,
                    'groupName': groupName,
                    'operation': 'group_delete_error',
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.error,
            ),
            child: Text(
              l10n.delete,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 进入组编辑模式
  void _enterGroupEditMode() {
    final id = widget.element['id'] as String;
    final groupName = widget.element['name'] as String? ?? 'Group';

    EditPageLogger.propertyPanelDebug(
      '进入分组编辑模式',
      data: {
        'groupId': id,
        'groupName': groupName,
        'operation': 'group_edit_mode_enter',
      },
    );

    try {
      widget.controller.enterGroupEditMode(id);

      EditPageLogger.propertyPanelDebug(
        '分组编辑模式启动成功',
        data: {
          'groupId': id,
          'groupName': groupName,
          'operation': 'group_edit_mode_success',
        },
      );
    } catch (error, stackTrace) {
      EditPageLogger.propertyPanelError(
        '进入分组编辑模式失败',
        error: error,
        stackTrace: stackTrace,
        data: {
          'groupId': id,
          'groupName': groupName,
          'operation': 'group_edit_mode_error',
        },
      );
    }
  }

  // 获取组内的所有元素
  List<Map<String, dynamic>> _getGroupChildren(String groupId) {
    final allElements = widget.controller.state.currentPageElements;
    final groupData = widget.element['groupData'] as Map<String, dynamic>?;

    if (groupData == null || !groupData.containsKey('children')) {
      return [];
    }

    final List<dynamic> childrenIds = groupData['children'] as List<dynamic>;
    return childrenIds
        .map((childId) => childId as String)
        .map((id) => allElements.firstWhere(
              (e) => e['id'] == id,
              orElse: () => <String, dynamic>{},
            ))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // 焦点变化处理
  void _onFocusChange() {
    if (!_nameFocusNode.hasFocus) {
      _applyNameChange();
    }
  }

  // 开始编辑名称
  void _startEditingName() {
    setState(() {
      _isEditingName = true;
    });
    // 确保在下一帧聚焦
    Future.microtask(() => _nameFocusNode.requestFocus());
  }

  // 解组元素
  void _ungroupElements() {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ungroupConfirm),
        content: Text(l10n.ungroupDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancel,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final id = widget.element['id'] as String;
              widget.controller.ungroupElements(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.primary,
            ),
            child: Text(
              l10n.ungroup,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 更新元素属性
  void _updateElementProperty(String key, dynamic value) {
    final id = widget.element['id'] as String;
    final currentValue = widget.element[key];

    if (currentValue != value) {
      EditPageLogger.propertyPanelDebug(
        '分组属性更新',
        data: {
          'groupId': id,
          'propertyKey': key,
          'fromValue': currentValue,
          'toValue': value,
          'operation': 'group_property_update',
        },
      );

      try {
        widget.onElementPropertiesChanged({
          'id': id,
          key: value,
        });

        EditPageLogger.propertyPanelDebug(
          '分组属性更新成功',
          data: {
            'groupId': id,
            'propertyKey': key,
            'value': value,
            'operation': 'group_property_update_success',
          },
        );
      } catch (error, stackTrace) {
        EditPageLogger.propertyPanelError(
          '分组属性更新失败',
          error: error,
          stackTrace: stackTrace,
          data: {
            'groupId': id,
            'propertyKey': key,
            'value': value,
            'operation': 'group_property_update_error',
          },
        );
      }
    }
  }

  /// 仅预览更新元素属性，不记录undo（用于滑块拖动过程中的实时预览）
  void _updateElementPropertyPreview(String key, dynamic value) {
    try {
      // 🚀 方案B：预览更新时暂时禁用undo，只更新UI
      widget.controller.undoRedoManager.undoEnabled = false;
      final id = widget.element['id'] as String;
      widget.onElementPropertiesChanged({
        'id': id,
        key: value,
      });
      // 重新启用undo
      widget.controller.undoRedoManager.undoEnabled = true;
    } catch (error) {
      // 确保在错误情况下也重新启用undo
      widget.controller.undoRedoManager.undoEnabled = true;
      EditPageLogger.propertyPanelError(
        '分组属性预览更新失败',
        error: error,
        data: {
          'propertyKey': key,
          'value': value,
          'operation': 'group_property_preview_update_error',
        },
      );
    }
  }

  /// 🚀 方案B：基于原始值更新元素属性并记录undo操作（用于滑块拖动结束）
  void _updateElementPropertyWithUndo(String key, dynamic value) {
    try {
      if (_originalOpacity != null && _originalOpacity != value) {
        final id = widget.element['id'] as String;
        
        // 先临时禁用undo，恢复到原始值
        widget.controller.undoRedoManager.undoEnabled = false;
        widget.onElementPropertiesChanged({
          'id': id,
          key: _originalOpacity,
        });
        
        // 重新启用undo，然后更新到新值（这会记录一次从原始值到新值的undo）
        widget.controller.undoRedoManager.undoEnabled = true;
        widget.onElementPropertiesChanged({
          'id': id,
          key: value,
        });
        
        EditPageLogger.propertyPanelDebug(
          '分组属性undo优化更新',
          data: {
            'groupId': id,
            'propertyKey': key,
            'originalValue': _originalOpacity,
            'newValue': value,
            'operation': 'group_property_undo_optimized_update',
          },
        );
      }
      // 清空原始值
      _originalOpacity = null;
    } catch (error) {
      // 确保在错误情况下也重新启用undo
      widget.controller.undoRedoManager.undoEnabled = true;
      EditPageLogger.propertyPanelError(
        '分组属性undo更新失败',
        error: error,
        data: {
          'propertyKey': key,
          'value': value,
          'operation': 'group_property_undo_update_error',
        },
      );
    }
  }
}
