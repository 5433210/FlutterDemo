import 'package:flutter/material.dart';

/// Utility class for handling layout issues
class LayoutUtils {
  /// Prevents a widget from overflowing by wrapping it in a flexible container
  ///
  /// This is useful for widgets that might overflow their parent, such as Text or Row widgets
  static Widget preventOverflow(Widget child, {bool clipOverflow = false}) {
    if (clipOverflow) {
      return ClipRect(child: child);
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
          ),
          child: child,
        );
      },
    );
  }

  /// Creates a row that won't overflow by using Flexible widgets
  ///
  /// This is useful for rows that might contain text or other widgets that could overflow
  static Widget createFlexibleRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    double spacing = 8.0,
  }) {
    final List<Widget> rowChildren = [];
    
    for (int i = 0; i < children.length; i++) {
      // Add flexible wrapper around each child
      rowChildren.add(
        Flexible(
          // Use tight fit for the last item to ensure it doesn't overflow
          fit: i == children.length - 1 ? FlexFit.tight : FlexFit.loose,
          child: children[i],
        ),
      );
      
      // Add spacing between children
      if (i < children.length - 1) {
        rowChildren.add(SizedBox(width: spacing));
      }
    }
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: rowChildren,
    );
  }

  /// Creates a row with a start and end section, ensuring neither overflows
  ///
  /// This is useful for headers with a title on the left and actions on the right
  static Widget createHeaderRow({
    required List<Widget> startSection,
    required List<Widget> endSection,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.spaceBetween,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double spacing = 8.0,
  }) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        // Start section with flexible constraint
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _addSpacingBetween(startSection, spacing),
          ),
        ),
        
        SizedBox(width: spacing),
        
        // End section with overflow handling
        Row(
          mainAxisSize: MainAxisSize.min,
          children: _addSpacingBetween(endSection, spacing),
        ),
      ],
    );
  }

  /// Adds spacing widgets between a list of widgets
  static List<Widget> _addSpacingBetween(List<Widget> widgets, double spacing) {
    if (widgets.isEmpty) return [];
    if (widgets.length == 1) return widgets;
    
    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(SizedBox(width: spacing));
      }
    }
    return result;
  }

  /// Creates a text widget that won't overflow by using ellipsis
  ///
  /// This is useful for text that might be too long for its container
  static Widget createOverflowSafeText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
  }) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines ?? 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Creates a compact icon button with reduced padding
  ///
  /// This is useful for fitting more buttons in a limited space
  static Widget createCompactIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    String? tooltip,
    double size = 24.0,
  }) {
    return IconButton(
      icon: Icon(icon, size: size),
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: BoxConstraints(
        minWidth: size + 8,
        minHeight: size + 8,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      color: color,
    );
  }
}
