import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';

class M3TitleBar extends StatefulWidget {
  final String? title;

  const M3TitleBar({super.key, this.title});

  @override
  State<M3TitleBar> createState() => _M3TitleBarState();
}

class M3WindowButtons extends StatefulWidget {
  const M3WindowButtons({super.key});

  @override
  State<M3WindowButtons> createState() => _M3WindowButtonsState();
}

class _M3TitleBarState extends State<M3TitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onDoubleTap: _handleDoubleClick,
      child: Container(
        height: AppSizes.appBarHeight,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant,
              width: AppSizes.dividerThickness,
            ),
          ),
        ),
        child: Row(
          children: [
            // 应用图标
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s),
              child: Icon(
                Icons.brush_outlined,
                color: colorScheme.primary,
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
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),

            // 窗口按钮
            const M3WindowButtons(),
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

class _M3WindowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isClose;

  const _M3WindowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                ? colorScheme.error
                    .withAlpha(25) // ~10% opacity (0.1 * 255 ≈ 25)
                : colorScheme.onSurface
                    .withAlpha(13), // ~5% opacity (0.05 * 255 ≈ 13)
            child: Icon(
              icon,
              size: AppSizes.iconSmall,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _M3WindowButtonsState extends State<M3WindowButtons> with WindowListener {
  bool _isMaximized = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        _M3WindowButton(
          icon: Icons.remove,
          tooltip: l10n.windowButtonMinimize,
          onPressed: () async {
            await windowManager.minimize();
          },
        ),
        _M3WindowButton(
          icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
          tooltip: _isMaximized
              ? l10n.windowButtonRestore
              : l10n.windowButtonMaximize,
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        _M3WindowButton(
          icon: Icons.close,
          tooltip: l10n.windowButtonClose,
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

  void _init() async {
    _isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }
}
