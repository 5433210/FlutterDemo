import 'package:flutter/material.dart';

/// Placeholder home page widget.
class HomePagePlaceholder extends StatelessWidget {
  const HomePagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: const Center(
        child: Text('Home Page'),
      ),
    );
  }
}
