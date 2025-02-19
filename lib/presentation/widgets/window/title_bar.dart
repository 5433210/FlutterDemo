import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({super.key});
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40, // 固定高度
      child: MoveWindow(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Theme.of(context).colorScheme.primary,
          child: Row(
            children: [
              const Icon(Icons.brush, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('书法集字', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
              const Spacer(),
              // 使用 bitsdojo_window 内置按钮
              MinimizeWindowButton(),
              MaximizeWindowButton(),
              CloseWindowButton(),
            ],
          ),
        ),
      ),
    );
  }
}
