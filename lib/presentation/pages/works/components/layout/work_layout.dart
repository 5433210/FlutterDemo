import 'package:flutter/material.dart';

class WorkLayout extends StatelessWidget {
  final Widget child;
  final Widget filterPanel;

  const WorkLayout({
    super.key,
    required this.child,
    required this.filterPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        filterPanel,
      ],
    );
  }
}
