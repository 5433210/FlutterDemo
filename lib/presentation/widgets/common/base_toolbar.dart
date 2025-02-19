import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class BaseToolbar extends StatelessWidget {
  final List<Widget> leftActions;
  final List<Widget> rightActions;
  final bool enableDrag;
  
  const BaseToolbar({
    super.key,
    this.leftActions = const [],
    this.rightActions = const [],
    this.enableDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          ...leftActions,
          const Spacer(),
          ...rightActions,
        ],
      ),
    );

    return enableDrag ? MoveWindow(child: content) : content;
  }
}
