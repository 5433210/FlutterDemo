import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  const SettingsSection({
    super.key,
    required this.title,
    this.icon,
    required this.children,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }
}
