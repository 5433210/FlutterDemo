import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';

class DialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const DialogHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.dialogHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }
}