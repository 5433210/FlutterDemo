import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';

enum ResponsiveBreakpoint { xs, sm, md, lg }

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, ResponsiveBreakpoint) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = _getBreakpoint(constraints.maxWidth);
        return builder(context, breakpoint);
      },
    );
  }

  ResponsiveBreakpoint _getBreakpoint(double width) {
    if (width < AppSizes.breakpointXs) return ResponsiveBreakpoint.xs;
    if (width < AppSizes.breakpointMd) return ResponsiveBreakpoint.sm;
    if (width < AppSizes.breakpointLg) return ResponsiveBreakpoint.md;
    return ResponsiveBreakpoint.lg;
  }
}
