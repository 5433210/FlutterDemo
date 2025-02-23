import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';

class ScrollableContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool showScrollbar;

  const ScrollableContainer({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.showScrollbar = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      controller: controller,
      padding: padding ?? const EdgeInsets.all(AppSizes.spacingMedium),
      child: child,
    );

    if (showScrollbar) {
      content = Scrollbar(
        controller: controller,
        child: content,
      );
    }

    return content;
  }
}
