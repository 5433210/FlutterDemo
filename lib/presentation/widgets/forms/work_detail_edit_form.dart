import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/enums/work_style.dart';
import '../../../domain/enums/work_tool.dart';
import '../../../domain/models/work/work_entity.dart';
import '../../../presentation/providers/work_detail_provider.dart';
import '../../../theme/app_sizes.dart';
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

            // 简约风格的作品名称输入
            _buildSimpleFormField(
              label: '作品名称',
              controller: _nameController,
              validator: _validateName,
              hintText: '请输入作品名称',
            ),
            const SizedBox(height: AppSizes.spacingSmall),

            // 简约风格的作者输入
            _buildSimpleFormField(
              label: '作者',
              controller: _authorController,
              hintText: '请输入作者名称',
            ),
            const SizedBox(height: AppSizes.spacingSmall),

            // 简约风格的风格选择
            _buildSimpleDropdownField(
              label: '作品风格',
              value: _selectedStyle,
              items: WorkStyle.values,
              getLabel: (style) => style.label,
              onChanged: (value) {
                setState(() {
                  _selectedStyle = value;
                  _formModified = true;
                });

                // 添加通知
                ref.read(workDetailProvider.notifier).updateWorkBasicInfo(
                      style: value,
                    );
                ref.read(workDetailProvider.notifier).markAsChanged();
              },
            ),
            const SizedBox(height: AppSizes.spacingSmall),

            // 简约风格的工具选择
            _buildSimpleDropdownField(
              label: '使用工具',
              value: _selectedTool,
              items: WorkTool.values,
              getLabel: (tool) => tool.label,
              onChanged: (value) {
                setState(() {
                  _selectedTool = value;
                  _formModified = true;
                });

                // 添加通知
                ref.read(workDetailProvider.notifier).updateWorkBasicInfo(
                      tool: value,
                    );
                ref.read(workDetailProvider.notifier).markAsChanged();
              },
            ),
            const SizedBox(height: AppSizes.spacingSmall),

            // 简约风格的日期选择
            _buildSimpleDateField(
              label: '创作日期',
              value: _selectedDate,
              onChanged: (date) {
                setState(() {
                  _selectedDate = date;
                  _formModified = true;
                });

                // 添加通知
                ref.read(workDetailProvider.notifier).updateWorkBasicInfo(
                      creationDate: date,
                    );
                ref.read(workDetailProvider.notifier).markAsChanged();
              },
            ),
            const SizedBox(height: AppSizes.spacingSmall),

            // 简约风格的备注输入
            _buildSimpleFormField(
              label: '备注',
              controller: _remarkController,
              hintText: '可选的备注信息',
              maxLines: 3,
            ),

            const SizedBox(height: AppSizes.spacingLarge),
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

  // 简约日期选择
  Widget _buildSimpleDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
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
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1500),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onChanged(date);
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
              value != null ? DateFormat('yyyy-MM-dd').format(value) : '未设置',
            ),
          ),
        ),
      ],
    );
  }

  // 简约下拉选择
  Widget _buildSimpleDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) getLabel,
    required ValueChanged<T?> onChanged,
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
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(getLabel(item)),
                  ))
              .toList(),
          onChanged: onChanged,
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

  // 简约表单字段 - 修改为确保每次变化都触发状态更新
  Widget _buildSimpleFormField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    FormFieldValidator<String>? validator,
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
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
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
          onChanged: (value) {
            setState(() {
              _formModified = true;
            });

            // 确定当前是哪个字段，调用对应的更新方法
            if (controller == _nameController) {
              ref
                  .read(workDetailProvider.notifier)
                  .updateWorkBasicInfo(title: value);
            } else if (controller == _authorController) {
              ref
                  .read(workDetailProvider.notifier)
                  .updateWorkBasicInfo(author: value);
            } else if (controller == _remarkController) {
              ref
                  .read(workDetailProvider.notifier)
                  .updateWorkBasicInfo(remark: value);
            }

            // 标记已更改状态
            ref.read(workDetailProvider.notifier).markAsChanged();
          },
        ),
      ],
    );
  }

  // 初始化表单值
  void _initFormValues() {
    final work = widget.work;

    // 初始化控制器，但不添加监听器
    _nameController = TextEditingController(text: work?.title ?? '');
    _authorController = TextEditingController(text: work?.author ?? '');
    _remarkController = TextEditingController(text: work?.remark ?? '');

    _selectedStyle = work?.style;
    _selectedTool = work?.tool;
    _selectedDate = work?.creationDate;

    _formModified = false;
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
