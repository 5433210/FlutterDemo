import 'package:flutter/material.dart';

/// A simplified standard page layout with consistent structure.
/// Only includes toolbar and body areas - the toolbar should include
/// all title/navigation/action elements combined.
class PageLayout extends StatelessWidget {
  /// The toolbar widget that appears at the top of the page
  /// This should contain all title elements and action buttons
  final Widget? toolbar;

  /// The main content of the page
  final Widget body;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// Height of the toolbar. If null, toolbar will size to its content.
  final double? toolbarHeight;

  const PageLayout({
    super.key,
    this.toolbar,
    required this.body,
    this.floatingActionButton,
    this.toolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // No AppBar, using our own toolbar
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toolbar with consistent styling
            if (toolbar != null)
              Material(
                elevation: 0,
                color: theme.colorScheme.surface,
                child: Container(
                  height: toolbarHeight ?? kToolbarHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  child: toolbar!,
                ),
              ),

            // Main content
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
