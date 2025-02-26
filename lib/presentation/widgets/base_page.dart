import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';

class BasePage extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? toolbar;
  final Widget body;
  final Widget? sidebar;
  final Widget? footer;

  const BasePage({
    super.key,
    required this.title,
    this.actions,
    this.toolbar,
    required this.body,
    this.sidebar,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        toolbarHeight: AppSizes.appBarHeight,
      ),
      body: Row(
        children: [
          if (sidebar != null)
            SizedBox(
              width: AppSizes.sidebarWidth,
              child: sidebar!,
            ),
          Expanded(
            child: Column(
              children: [
                if (toolbar != null)
                  SizedBox(
                    height: AppSizes.appBarHeight,
                    child: toolbar!,
                  ),
                Expanded(child: body),
                if (footer != null)
                  SizedBox(
                    height: AppSizes.tableHeaderHeight,
                    child: footer!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
