import 'package:flutter/material.dart';
import 'sort_section.dart';
import 'style_section.dart';
import 'tool_section.dart';
import 'date_section.dart';

class WorkFilterPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SortSection(),
        SizedBox(height: 24),
        StyleSection(),
        SizedBox(height: 24),
        ToolSection(),
        SizedBox(height: 24),
        DateSection(),
      ],
    );
  }
}
