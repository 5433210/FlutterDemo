import 'package:flutter/material.dart';
import '../../theme/app_sizes.dart';
import 'page_bar.dart';

class PageLayout extends StatefulWidget {
  final Widget? navigationInfo;
  final List<Widget>? actions;
  final Widget? toolbar;
  final Widget body;
  final Widget? sidebar;
  final Widget? footer;

  const PageLayout({
    super.key,
    this.navigationInfo,
    this.actions,
    this.toolbar,
    required this.body,
    this.sidebar,
    this.footer,
  });

  @override
  State<PageLayout> createState() => _PageLayoutState();
}

class _PageLayoutState extends State<PageLayout> {
  static const double _sidebarWidth = 320.0;  // 固定宽度

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageBar(
        title: widget.navigationInfo,
        actions: widget.actions,
        toolbarHeight: 50,  // 更新常量名
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
                    height: AppSizes.pageToolbarHeight,  // 更新常量名
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