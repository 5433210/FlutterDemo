import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/commands/work_edit_commands.dart';
import '../../../domain/enums/work_style.dart';
import '../../../domain/enums/work_tool.dart';
import '../../../domain/value_objects/work/work_entity.dart';
import '../../../presentation/providers/work_detail_provider.dart';
import '../../../theme/app_sizes.dart';
import '../../widgets/inputs/date_input_field.dart';
import '../../widgets/inputs/dropdown_field.dart';
import '../common/section_title.dart';

class WorkDetailEditForm extends ConsumerStatefulWidget {
  final WorkEntity? work;

  const WorkDetailEditForm({
    super.key,
    required this.work,
  });

  @override
  ConsumerState<WorkDetailEditForm> createState() => _WorkDetailEditFormState();
}

class _WorkDetailEditFormState extends ConsumerState<WorkDetailEditForm> {
  final _formKey = GlobalKey<FormState>();

  // 表单控制器
  late TextEditingController _nameController;
  late TextEditingController _authorController;
  late TextEditingController _remarkController;

  // 表单状态
  WorkStyle? _selectedStyle;
  WorkTool? _selectedTool;
  DateTime? _selectedDate;

  // 跟踪是否已修改表单
  bool _formModified = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      onChanged: () {
        setState(() {
          _formModified = true;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: '基本信息'),
            const SizedBox(height: AppSizes.spacingMedium),

            // 作品名称（必填）
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '作品名称',
                hintText: '请输入作品名称',
              ),
              textInputAction: TextInputAction.next,
              validator: _validateName,
              onChanged: (_) => _formModified = true,
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            // 作者
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: '作者',
                hintText: '请输入作者名称',
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => _formModified = true,
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            // 风格下拉菜单
            DropdownField<WorkStyle>(
              label: '作品风格',
              value: _selectedStyle,
              items: WorkStyle.values
                  .map((style) => DropdownMenuItem(
                        value: style,
                        child: Text(style.label),
                      ))
                  .toList(),
              onChanged: (style) {
                setState(() {
                  _selectedStyle = style;
                  _formModified = true;
                });
              },
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            // 工具下拉菜单
            DropdownField<WorkTool>(
              label: '使用工具',
              value: _selectedTool,
              items: WorkTool.values
                  .map((tool) => DropdownMenuItem(
                        value: tool,
                        child: Text(tool.label),
                      ))
                  .toList(),
              onChanged: (tool) {
                setState(() {
                  _selectedTool = tool;
                  _formModified = true;
                });
              },
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            // 创建日期
            DateInputField(
              label: '创作日期',
              value: _selectedDate,
              format: DateFormat('yyyy-MM-dd'),
              onChanged: (date) {
                setState(() {
                  _selectedDate = date;
                  _formModified = true;
                });
              },
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            // 备注（多行文本）
            TextFormField(
              controller: _remarkController,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '可选的备注信息',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => _formModified = true,
            ),

            const SizedBox(height: AppSizes.spacingLarge),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _formModified ? _resetForm : null,
                  child: const Text('重置'),
                ),
                const SizedBox(width: AppSizes.spacingSmall),
                FilledButton(
                  onPressed: _formModified ? _submitForm : null,
                  child: const Text('应用更改'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant WorkDetailEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.work != widget.work) {
      _initFormValues();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initFormValues();
  }

  // 初始化表单值
  void _initFormValues() {
    final work = widget.work;

    _nameController = TextEditingController(text: work?.name ?? '');
    _authorController = TextEditingController(text: work?.author ?? '');
    _remarkController = TextEditingController(text: work?.remark ?? '');

    _selectedStyle = work?.style;
    _selectedTool = work?.tool;
    _selectedDate = work?.creationDate;

    _formModified = false;
  }

  // 重置表单
  void _resetForm() {
    _initFormValues();
    setState(() {});
  }

  // 提交表单
  void _submitForm() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // 获取当前作品以用于比较
    final oldWork = widget.work;
    if (oldWork == null) return;

    // 创建更新命令
    final command = UpdateInfoCommand(
      // 新值
      newName: _nameController.text,
      newAuthor: _authorController.text,
      newStyle: _selectedStyle,
      newTool: _selectedTool,
      newCreationDate: _selectedDate,
      newRemark: _remarkController.text,

      // 旧值（用于撤销）
      oldName: oldWork.name,
      oldAuthor: oldWork.author,
      oldStyle: oldWork.style,
      oldTool: oldWork.tool,
      oldCreationDate: oldWork.creationDate,
      oldRemark: oldWork.remark,
    );

    // 执行命令
    ref.read(workDetailProvider.notifier).executeCommand(command);

    // 重置表单修改状态（但保留当前值）
    setState(() {
      _formModified = false;
    });
  }

  // 验证作品名称
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入作品名称';
    }
    if (value.length > 100) {
      return '名称不能超过100个字符';
    }
    return null;
  }
}
