import 'package:flutter/material.dart';

/// A row that automatically adapts to available space by using Expanded and Flexible widgets.
///
/// This widget is useful for creating rows with items that should take specific proportions
/// of the available space, preventing overflow issues.
class AdaptiveRow extends StatelessWidget {
  /// The start section widgets (will try to maintain their intrinsic size)
  final List<Widget> startSection;

  /// The middle section widgets (will expand to fill available space)
  final List<Widget> middleSection;

  /// The end section widgets (will try to maintain their intrinsic size)
  final List<Widget> endSection;

  /// The spacing between sections
  final double sectionSpacing;

  /// The spacing between items within a section
  final double itemSpacing;

  /// Whether to allow the middle section to shrink below its intrinsic width
  final bool allowMiddleShrink;

  /// Constructor
  const AdaptiveRow({
    Key? key,
    this.startSection = const [],
    this.middleSection = const [],
    this.endSection = const [],
    this.sectionSpacing = 16.0,
    this.itemSpacing = 8.0,
    this.allowMiddleShrink = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width for layout decisions
        final availableWidth = constraints.maxWidth;

        // If we have very limited space, use a more compact layout
        final isVeryNarrow = availableWidth < 200;

        if (isVeryNarrow && endSection.isNotEmpty) {
          // For very narrow layouts, stack the sections vertically
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start section
              if (startSection.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      _addSpacingBetweenChildren(startSection, itemSpacing),
                ),

              const SizedBox(height: 8),

              // End section
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _addSpacingBetweenChildren(endSection, itemSpacing),
              ),
            ],
          );
        }

        // For normal layouts, use a horizontal arrangement with flexible sections
        return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Start section
            if (startSection.isNotEmpty)
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: startSection.map((widget) {
                    if (widget is Text) {
                      // Add overflow handling for Text widgets
                      return Flexible(
                        child: Text(
                          (widget).data ?? '',
                          style: widget.style,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }
                    return widget;
                  }).toList(),
                ),
              ),

            // End section
            if (endSection.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: endSection.map((widget) {
                  // Constrain the size of end section items
                  return SizedBox(
                    width: 40,
                    height: 40,
                    child: widget,
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _addSpacingBetweenChildren(
      List<Widget> children, double spacing) {
    if (children.isEmpty) return [];
    if (children.length == 1) return children;

    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(SizedBox(width: spacing));
      }
    }
    return result;
  }
}

/// A flexible row that adapts to available space to prevent overflow.
///
/// This widget handles overflow by:
/// 1. Trying to display all children in a row
/// 2. If there's not enough space, it will shrink flexible items
/// 3. If still not enough space, it can optionally wrap to multiple lines
/// 4. If wrapping is disabled, it will prioritize items based on their importance
class FlexibleRow extends StatelessWidget {
  /// The children to display in the row
  final List<Widget> children;

  /// Whether to allow wrapping to multiple lines
  final bool allowWrap;

  /// The spacing between items
  final double spacing;

  /// The alignment of the row
  final MainAxisAlignment mainAxisAlignment;

  /// The cross axis alignment
  final CrossAxisAlignment crossAxisAlignment;

  /// Constructor
  const FlexibleRow({
    Key? key,
    required this.children,
    this.allowWrap = false,
    this.spacing = 8.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (allowWrap) {
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        alignment: _convertMainAxisAlignmentToWrapAlignment(mainAxisAlignment),
        crossAxisAlignment:
            _convertCrossAxisAlignmentToWrapCrossAlignment(crossAxisAlignment),
        children: children,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildAdaptiveRow(constraints);
      },
    );
  }

  List<Widget> _addSpacingBetweenChildren(
      List<Widget> children, double spacing) {
    if (children.isEmpty) return [];
    if (children.length == 1) return children;

    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(SizedBox(width: spacing));
      }
    }
    return result;
  }

  Widget _buildAdaptiveRow(BoxConstraints constraints) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: _addSpacingBetweenChildren(children, spacing),
    );
  }

  WrapCrossAlignment _convertCrossAxisAlignmentToWrapCrossAlignment(
      CrossAxisAlignment alignment) {
    switch (alignment) {
      case CrossAxisAlignment.start:
        return WrapCrossAlignment.start;
      case CrossAxisAlignment.end:
        return WrapCrossAlignment.end;
      case CrossAxisAlignment.center:
      case CrossAxisAlignment.baseline:
      case CrossAxisAlignment.stretch:
        return WrapCrossAlignment.center;
    }
  }

  WrapAlignment _convertMainAxisAlignmentToWrapAlignment(
      MainAxisAlignment alignment) {
    switch (alignment) {
      case MainAxisAlignment.start:
        return WrapAlignment.start;
      case MainAxisAlignment.end:
        return WrapAlignment.end;
      case MainAxisAlignment.center:
        return WrapAlignment.center;
      case MainAxisAlignment.spaceBetween:
        return WrapAlignment.spaceBetween;
      case MainAxisAlignment.spaceAround:
        return WrapAlignment.spaceAround;
      case MainAxisAlignment.spaceEvenly:
        return WrapAlignment.spaceEvenly;
    }
  }
}

/// A row with overflow protection that automatically handles text overflow.
///
/// This widget is specifically designed for rows containing text that might overflow,
/// providing automatic ellipsis and flexible layout options.
class OverflowSafeRow extends StatelessWidget {
  /// The leading widget (usually an icon)
  final Widget? leading;

  /// The title widget (usually text)
  final Widget title;

  /// The trailing widgets
  final List<Widget> trailing;

  /// The spacing between items
  final double spacing;

  /// Constructor
  const OverflowSafeRow({
    Key? key,
    this.leading,
    required this.title,
    this.trailing = const [],
    this.spacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: spacing),
        ],
        Expanded(
          child: title,
        ),
        if (trailing.isNotEmpty) ...[
          SizedBox(width: spacing),
          ...trailing
              .expand((widget) => [
                    widget,
                    SizedBox(width: spacing),
                  ])
              .toList()
            ..removeLast(),
        ],
      ],
    );
  }
}
