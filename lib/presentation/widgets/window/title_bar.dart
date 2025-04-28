import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../theme/app_sizes.dart';

class TitleBar extends StatefulWidget {
  final String? title;

  const TitleBar({super.key, this.title});

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _TitleBarState extends State<TitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onDoubleTap: _handleDoubleClick,
      child: Container(
        height: AppSizes.appBarHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor,
              width: AppSizes.dividerThickness,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // 应用图标
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s),
              child: Icon(
                Icons.brush_outlined,
                color: theme.colorScheme.primary,
                size: AppSizes.iconMedium,
              ),
            ),
            // 标题拖动区域
            Expanded(
              child: DragToMoveArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s),
                  child: Text(
                    widget.title ?? '字字珠玑',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            // 窗口按钮
            const WindowButtons(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowRestore() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  Future<void> _handleDoubleClick() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  void _init() async {
    _isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }
}

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: SizedBox(
        height: AppSizes.appBarHeight,
        width: 46,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            hoverColor: isClose
                ? theme.colorScheme.error.withOpacity(0.1)
                : theme.colorScheme.onSurface.withOpacity(0.05),
            child: Icon(
              icon,
              size: AppSizes.iconSmall,
              color: isClose
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowButtonsState extends State<WindowButtons> with WindowListener {
  bool _isMaximized = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WindowButton(
          icon: Icons.remove,
          tooltip: '最小化',
          onPressed: () async {
            await windowManager.minimize();
          },
        ),
        _WindowButton(
          icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
          tooltip: _isMaximized ? '还原' : '最大化',
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        _WindowButton(
          icon: Icons.close,
          tooltip: '关闭',
          isClose: true,
          onPressed: () async {
            await windowManager.close();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowRestore() {
    setState(() => _isMaximized = false);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  Future<void> _init() async {
    _isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }
}
