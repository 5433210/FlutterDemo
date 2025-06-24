import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../routes/app_routes.dart';

/// Placeholder home page widget.
class HomePagePlaceholder extends StatelessWidget {
  const HomePagePlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homePage)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.homePage, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.fontTester);
              },
              child: Text(l10n.fontTester),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.fontWeightTester);
              },
              child: Text(l10n.fontWeightTester),
            ),
          ],
        ),
      ),
    );
  }
}
