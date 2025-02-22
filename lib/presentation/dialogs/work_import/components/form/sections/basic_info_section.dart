import 'package:flutter/material.dart';
import '../../../../../theme/app_sizes.dart';
import '../../../../../viewmodels/work_import_view_model.dart';
import '../../../../../viewmodels/states/work_import_state.dart';
import '../../../../../widgets/forms/form_field_wrapper.dart';

class BasicInfoSection extends StatelessWidget {
  final WorkImportState state;
  final WorkImportViewModel viewModel;

  const BasicInfoSection({
    super.key,
    required this.state,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormFieldWrapper(
          label: '作品名称',
          required: true,
          child: TextFormField(
            initialValue: state.name,
            onChanged: viewModel.setName,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return '请输入作品名称';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: AppSizes.formSpacing),
        FormFieldWrapper(
          label: '作者',
          child: TextFormField(
            initialValue: state.author,
            onChanged: viewModel.setAuthor,
          ),
        ),
      ],
    );
  }
}