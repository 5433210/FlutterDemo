import 'package:flutter/material.dart';
import '../theme/app_sizes.dart';

class MainLayout extends StatefulWidget {
  final Widget? navigationInfo;
  final List<Widget>? actions;
  final Widget? toolbar;
  final Widget body;
  final Widget? sidebar;
  final Widget? footer;

  const MainLayout({
    super.key,
    this.navigationInfo,
    this.actions,
    this.toolbar,
    required this.body,
    this.sidebar,
    this.footer,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const double _sidebarWidth = 320.0;  // 固定宽度

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.navigationInfo,
        actions: widget.actions,
        toolbarHeight: AppSizes.appBarHeight,
      ),
      body: Row(
        children: [
          if (widget.sidebar != null)
            Container(
              width: _sidebarWidth,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: widget.sidebar,
            ),
          Expanded(
            child: Column(
              children: [
                if (widget.toolbar != null)
                  Container(
                    height: AppSizes.appBarHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: widget.toolbar!,
                  ),
                Expanded(child: widget.body),
                if (widget.footer != null) widget.footer!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}