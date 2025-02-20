import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends StatelessWidget with WindowListener {
  const TitleBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: double.infinity, // 确保宽度填满
      color: Theme.of(context).colorScheme.primary,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) async {
          await windowManager.startDragging();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Theme.of(context).colorScheme.primary,
          child: Row(
            children: [
              const Icon(Icons.brush, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '书法集字',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const Spacer(),
              // 窗口控制按钮组
              const WindowButtons(),
            ],
          ),
        ),
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const buttonColor = Colors.white;
    final hoverColor = Colors.white.withOpacity(0.1);

    return Row(
      children: [
        // 最小化按钮
        _WindowButton(
          icon: Icons.remove,
          color: buttonColor,
          hoverColor: hoverColor,
          onPressed: () async {
            await windowManager.minimize();
          },
          tooltip: '最小化',
        ),
        // 最大化/还原按钮
        _WindowButton(
          icon: Icons.crop_square,
          color: buttonColor,
          hoverColor: hoverColor,
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.restore();
            } else {
              await windowManager.maximize();
            }
          },
          tooltip: '最大化',
        ),
        // 关闭按钮
        _WindowButton(
          icon: Icons.close,
          color: buttonColor,
          hoverColor: Colors.red,
          onPressed: () async {
            await windowManager.close();
          },
          tooltip: '关闭',
        ),
      ],
    );
  }
}

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color hoverColor;
  final VoidCallback onPressed;
  final String tooltip;

  const _WindowButton({
    required this.icon,
    required this.color,
    required this.hoverColor,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: hoverColor,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
