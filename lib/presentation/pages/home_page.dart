import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';

/// Placeholder home page widget.
class HomePagePlaceholder extends StatelessWidget {
  const HomePagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Home Page', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.fontTester);
              },
              child: const Text('字体测试工具'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.fontWeightTester);
              },
              child: const Text('字体粗细测试工具'),
            ),
          ],
        ),
      ),
    );
  }
}
