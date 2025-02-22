import 'package:flutter/material.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../viewmodels/work_import_view_model.dart';
import '../../../../viewmodels/states/work_import_state.dart';
import '../../../../widgets/forms/form_field_wrapper.dart';
import '../../../../widgets/forms/date_picker_field.dart';
import 'sections/basic_info_section.dart';
import 'sections/style_section.dart';

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
          BasicInfoSection(
            state: state,
            viewModel: viewModel,
          ),
          const SizedBox(height: AppSizes.l), // 增加间距
          StyleSection(
            state: state,
            viewModel: viewModel,
          ),
          const SizedBox(height: AppSizes.l),
          FormFieldWrapper(
            label: '创作日期',
            child: DatePickerField(
              value: state.creationDate,
              onChanged: viewModel.setCreationDate,              
            ),
          ),
          const SizedBox(height: AppSizes.l),
          FormFieldWrapper(
            label: '备注',
            child: TextFormField(
              initialValue: state.remarks,
              maxLines: 3,
              onChanged: viewModel.setRemarks,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: '可选',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.l),
          // 保持原有优化选项部分...
        ],
      ),
    );
  }
}