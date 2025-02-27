import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';

/// A standard page layout with consistent structure
class PageLayout extends StatelessWidget {
  final String? title;
  final Widget? toolbar;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const PageLayout({
    super.key,
    this.title,
    this.toolbar,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        leading: showBackButton ? _buildBackButton(context) : null,
        title: toolbar ?? (title != null ? Text(title!) : null),
        actions: actions,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget? _buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
    );
  }
}
