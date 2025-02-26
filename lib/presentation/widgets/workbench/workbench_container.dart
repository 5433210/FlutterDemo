import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

class WorkbenchContainer extends StatelessWidget {
  final Widget? toolbar;
  final Widget body;
  final Widget? sidebar;
  final double? sidebarWidth;
  final Widget? footer;

  const WorkbenchContainer({
    super.key,
    this.toolbar,
    required this.body,
    this.sidebar,
    this.sidebarWidth = 320.0,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (toolbar != null)
          Container(
            height: AppSizes.pageToolbarHeight,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: toolbar,
          ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: body),
              if (sidebar != null) ...[
                VerticalDivider(
                    width: 1, color: Theme.of(context).dividerColor),
                SizedBox(
                  width: sidebarWidth,
                  child: sidebar!,
                ),
              ],
            ],
          ),
        ),
        if (footer != null)
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: footer,
          ),
      ],
    );
  }
}
