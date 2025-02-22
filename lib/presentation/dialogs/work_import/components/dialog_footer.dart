import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';
import '../../../widgets/buttons/loading_button.dart';

class DialogFooter extends StatelessWidget {
  final String? error;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const DialogFooter({
    super.key,
    this.error,
    this.isLoading = false,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 56,
      padding: const EdgeInsets.all(AppSizes.m),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          if (error != null)
            Expanded(
              child: Text(
                error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: onCancel,
            child: const Text('取消'),
          ),
          const SizedBox(width: AppSizes.m),
          LoadingButton(
            text: '确定',
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}