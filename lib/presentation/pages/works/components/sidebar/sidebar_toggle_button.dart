import 'package:flutter/material.dart';
import '../../../../theme/app_sizes.dart';

class SidebarToggleButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const SidebarToggleButton({
    super.key,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      child: InkWell(
        onTap: onToggle,
        child: Center(
          child: Icon(
            isExpanded ? Icons.chevron_left : Icons.chevron_right,
            size: 20,
          ),
        ),
      ),
    );
  }
}
