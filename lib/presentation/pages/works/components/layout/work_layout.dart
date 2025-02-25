import 'package:flutter/material.dart';
import '../../../../theme/app_sizes.dart';

class WorkLayout extends StatelessWidget {
  final Widget toolbar;
  final Widget body;
  final Widget? sidebar;

  const WorkLayout({
    super.key,
    required this.toolbar,
    required this.body,
    this.sidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        toolbar,
        Expanded(
          child: Row(
            children: [
              if (sidebar != null) ...[
                SizedBox(
                  width: AppSizes.sidebarWidth,
                  child: sidebar!,
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: body),
            ],
          ),
        ),
      ],
    );
  }
}
