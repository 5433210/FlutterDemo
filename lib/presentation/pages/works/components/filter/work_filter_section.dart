import 'package:flutter/material.dart';

class WorkFilterSection extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const WorkFilterSection({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (actions != null) ...actions!,
      ],
    );
  }
}
