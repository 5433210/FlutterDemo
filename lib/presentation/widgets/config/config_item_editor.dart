import 'package:flutter/material.dart';

import '../../../domain/models/config/config_item.dart';
import '../../../l10n/app_localizations.dart';

/// 配置项编辑器对话框
class ConfigItemEditor extends StatefulWidget {
  final String category;
  final ConfigItem? item;
  final Function(ConfigItem) onSave;

  const ConfigItemEditor({
    super.key,
    required this.category,
    this.item,
    required this.onSave,
  });

  @override
  State<ConfigItemEditor> createState() => _ConfigItemEditorState();
}

class _ConfigItemEditorState extends State<ConfigItemEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keyController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _sortOrderController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _keyController = TextEditingController(text: item?.key ?? '');
    _displayNameController =
        TextEditingController(text: item?.displayName ?? '');
    _sortOrderController =
        TextEditingController(text: item?.sortOrder.toString() ?? '1');
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _displayNameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.item != null;
    final isSystemItem = widget.item?.isSystem ?? false;

    return AlertDialog(
      title: Text(isEditing ? l10n.editConfigItem : l10n.newConfigItem),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 键输入框
              TextFormField(
                controller: _keyController,
                decoration: InputDecoration(
                  labelText: '${l10n.key} *',
                  hintText: l10n.keyHint,
                  helperText: l10n.keyHelperText,
                ),
                enabled: !isSystemItem, // 系统项不允许修改键
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.keyCannotBeEmpty;
                  }

                  final key = value.trim();
                  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(key)) {
                    return l10n.keyInvalidCharacters;
                  }

                  if (key.length < 2) {
                    return l10n.keyMinLength;
                  }

                  if (key.length > 50) {
                    return l10n.keyMaxLength;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 显示名称输入框
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: '${l10n.displayName} *',
                  hintText: l10n.displayNameHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.displayNameCannotBeEmpty;
                  }

                  if (value.trim().length > 100) {
                    return l10n.displayNameMaxLength;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 排序顺序输入框
              TextFormField(
                controller: _sortOrderController,
                decoration: InputDecoration(
                  labelText: l10n.sortOrderLabel,
                  hintText: l10n.sortOrderHint,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.sortOrderCannotBeEmpty;
                  }

                  final order = int.tryParse(value.trim());
                  if (order == null) {
                    return l10n.invalidNumber;
                  }

                  if (order < 1 || order > 999) {
                    return l10n.sortOrderRange;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 激活状态开关
              SwitchListTile(
                title: Text(l10n.activeStatus),
                subtitle: Text(_isActive
                    ? l10n.activatedDescription
                    : l10n.disabledDescription),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),

              // 系统配置项提示
              if (isSystemItem)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.systemConfigItemNote,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saveItem,
          child: Text(isEditing ? l10n.save : l10n.create),
        ),
      ],
    );
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final key = _keyController.text.trim();
    final displayName = _displayNameController.text.trim();
    final sortOrder = int.parse(_sortOrderController.text.trim());

    final item = widget.item?.copyWith(
          displayName: displayName,
          sortOrder: sortOrder,
          isActive: _isActive,
          updateTime: DateTime.now(),
        ) ??
        ConfigItem(
          key: key,
          displayName: displayName,
          sortOrder: sortOrder,
          isSystem: false,
          isActive: _isActive,
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        );

    widget.onSave(item);
    Navigator.of(context).pop();
  }
}
