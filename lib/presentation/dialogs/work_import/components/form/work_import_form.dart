import 'package:flutter/material.dart';
import '../../../../../domain/enums/work_style.dart';
import '../../../../../domain/enums/work_tool.dart';
import '../../../../../theme/app_sizes.dart';
import '../../../../viewmodels/states/work_import_state.dart';
import '../../../../viewmodels/work_import_view_model.dart';
import '../../../../widgets/form/form_section.dart';
import '../../../../widgets/forms/form_field_wrapper.dart';

class WorkImportForm extends StatelessWidget {
  final WorkImportState state;
  final WorkImportViewModel viewModel;

  const WorkImportForm({
    super.key,
    required this.state,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.l,
        vertical: AppSizes.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 作品名称
          FormFieldWrapper(
            label: '作品名称',
            required: true,
            child: TextFormField(
              initialValue: state.name,
              onChanged: viewModel.setName,
              style: theme.textTheme.bodyLarge,
              decoration: _getInputDecoration(theme, '请输入作品名称'),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '请输入作品名称';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: AppSizes.m),

          // 作者
          FormFieldWrapper(
            label: '作者',
            required: true,
            child: TextFormField(
              initialValue: state.author,
              onChanged: viewModel.setAuthor,
              style: theme.textTheme.bodyLarge,
              decoration: _getInputDecoration(theme, '请输入作者姓名'),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '请输入作者姓名';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: AppSizes.m),

          // 书法风格
          FormFieldWrapper(
            label: '书法风格',
            required: true,
            child: DropdownButtonFormField<String>(
              value: state.style?.toString().split('.').last,
              items: WorkStyle.values.map((style) {
                return DropdownMenuItem(
                  value: style.value,
                  child: Text(style.label),
                );
              }).toList(),
              onChanged: viewModel.setStyle,
              decoration: _getInputDecoration(theme, '请选择书法风格'),
              style: theme.textTheme.bodyLarge,
              validator: (value) {
                if (value == null) {
                  return '请选择书法风格';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: AppSizes.m),

          // 书写工具
          FormFieldWrapper(
            label: '书写工具',
            required: true,
            child: DropdownButtonFormField<String>(
              value: state.tool?.toString().split('.').last,
              items: WorkTool.values.map((tool) {
                return DropdownMenuItem(
                  value: tool.value,
                  child: Text(tool.label),
                );
              }).toList(),
              onChanged: viewModel.setTool,
              decoration: _getInputDecoration(theme, '请选择书写工具'),
              style: theme.textTheme.bodyLarge,
              validator: (value) {
                if (value == null) {
                  return '请选择书写工具';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: AppSizes.m),

          // 创作日期
          FormFieldWrapper(
            label: '创作日期',
            required: true,
            child: TextFormField(
              controller: TextEditingController(
                text: state.creationDate?.toString().split(' ')[0],
              ),
              readOnly: true,
              style: theme.textTheme.bodyLarge,
              decoration: _getInputDecoration(
                theme, 
                '请选择创作日期',
                suffix: const Icon(Icons.calendar_today),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '请选择创作日期';
                }
                return null;
              },
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: state.creationDate ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  viewModel.setCreationDate(date);
                }
              },
            ),
          ),

          const SizedBox(height: AppSizes.m),

          // 备注
          FormFieldWrapper(
            label: '备注',
            child: TextFormField(
              initialValue: state.remarks,
              maxLines: 3,
              style: theme.textTheme.bodyLarge,
              decoration: _getInputDecoration(theme, '可选'),
              onChanged: viewModel.setRemarks,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(ThemeData theme, String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.outline,
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.xs),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffix,
    );
  }
}