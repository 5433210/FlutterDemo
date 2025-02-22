import 'package:flutter/material.dart';
import '../../../../../../domain/enums/work_style.dart';
import '../../../../../../domain/enums/work_tool.dart';
import '../../../../../theme/app_sizes.dart';
import '../../../../../viewmodels/work_import_view_model.dart';
import '../../../../../viewmodels/states/work_import_state.dart';
import '../../../../../widgets/forms/form_field_wrapper.dart';
import '../../../../../widgets/forms/dropdown_field.dart';

class StyleSection extends StatelessWidget {
  final WorkImportState state;
  final WorkImportViewModel viewModel;

  const StyleSection({
    super.key,
    required this.state,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStyleField(context),
        const SizedBox(height: AppSizes.formSpacing),
        _buildToolField(context),
      ],
    );
  }

  Widget _buildStyleField(BuildContext context) {
    return FormFieldWrapper(
      label: '书法风格',
      tooltip: '作品的书法风格类型',
      child: DropdownField<WorkStyle>(
        value: state.style,
        items: WorkStyle.values,
        itemBuilder: (style) => Text(style.label),
        onChanged: (value) => viewModel.setStyle,
        hint: '请选择书法风格',
      ),
    );
  }

  Widget _buildToolField(BuildContext context) {
    return FormFieldWrapper(
      label: '书写工具',
      tooltip: '创作所使用的书写工具',
      child: DropdownField<WorkTool>(
        value: state.tool,
        items: WorkTool.values,
        itemBuilder: (tool) => Text(tool.label),
        onChanged: (value) => viewModel.setTool(value!.value),
        hint: '请选择书写工具',
      ),
    );
  }
}