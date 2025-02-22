import 'package:flutter/material.dart';
import '../../theme/app_sizes.dart';
import 'loading_button.dart';

class DialogButtonGroup extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String cancelText;
  final String submitText;

  const DialogButtonGroup({
    super.key,
    this.isLoading = false,
    required this.onCancel,
    required this.onSubmit,
    this.cancelText = '取消',
    this.submitText = '确认',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: isLoading ? null : onCancel,
          child: Text(cancelText),
        ),
        const SizedBox(width: AppSizes.m),
        LoadingButton(
          text: submitText,
          onPressed: isLoading ? null : onSubmit,
          isLoading: isLoading,
        ),
      ],
    );
  }
}