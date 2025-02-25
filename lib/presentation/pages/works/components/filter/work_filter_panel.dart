import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sort_section.dart';
import 'style_section.dart';
import 'tool_section.dart';
import 'date_section.dart';

class WorkFilterPanel extends ConsumerWidget {
  const WorkFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SortSection(),
        const SizedBox(height: 24),
        const StyleSection(),
        const SizedBox(height: 24),
        const ToolSection(),
        const SizedBox(height: 24),
        const DateSection(),
      ],
    );
  }
}
