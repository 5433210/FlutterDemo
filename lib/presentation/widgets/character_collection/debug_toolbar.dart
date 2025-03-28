import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/debug/debug_options_provider.dart';

/// 调试工具栏组件
class DebugToolbar extends ConsumerWidget {
  const DebugToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugOptions = ref.watch(debugOptionsProvider);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.black87,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme),
                const Divider(color: Colors.white24),
                _buildToggles(debugOptions, ref),
                const Divider(color: Colors.white24),
                _buildAdjustments(debugOptions, ref),
                const Divider(color: Colors.white24),
                _buildFooter(ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustments(DebugOptions options, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSlider(
          label: '网格大小',
          value: options.gridSize,
          min: 20,
          max: 100,
          divisions: 8,
          onChanged: (value) =>
              ref.read(debugOptionsProvider.notifier).setGridSize(value),
        ),
        _buildSlider(
          label: '文本缩放',
          value: options.textScale,
          min: 0.5,
          max: 2.0,
          divisions: 6,
          onChanged: (value) =>
              ref.read(debugOptionsProvider.notifier).setTextScale(value),
        ),
        _buildSlider(
          label: '不透明度',
          value: options.opacity,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          onChanged: (value) =>
              ref.read(debugOptionsProvider.notifier).setOpacity(value),
        ),
      ],
    );
  }

  Widget _buildFooter(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextButton.icon(
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('重置'),
        onPressed: () =>
            ref.read(debugOptionsProvider.notifier).resetToDefaults(),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.bug_report,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '调试工具',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.blue,
              overlayColor: Colors.blue.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildToggle({
    required String label,
    String? tooltip,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final toggle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
          activeTrackColor: Colors.blue.withOpacity(0.5),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        if (tooltip != null)
          Tooltip(
            message: tooltip,
            child: const Icon(
              Icons.keyboard,
              color: Colors.white38,
              size: 14,
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: toggle,
    );
  }

  Widget _buildToggles(DebugOptions options, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToggle(
          label: '网格',
          tooltip: 'Alt+G',
          value: options.showGrid,
          onChanged: (value) =>
              ref.read(debugOptionsProvider.notifier).toggleGrid(),
        ),
        _buildToggle(
          label: '坐标',
          tooltip: 'Alt+C',
          value: options.showCoordinates,
          onChanged: (value) =>
              ref.read(debugOptionsProvider.notifier).toggleCoordinates(),
        ),
        _buildToggle(
          label: '详细信息',
          value: options.showDetails,
          onChanged: (value) =>
              ref.read(debugOptionsProvider.notifier).toggleDetails(),
        ),
        _buildToggle(
          label: '图像信息',
          value: options.showImageInfo,
          onChanged: (value) =>
              ref.read(debugOptionsProvider.notifier).toggleImageInfo(),
        ),
        _buildToggle(
          label: '日志',
          tooltip: 'Alt+L',
          value: options.enableLogging,
          onChanged: (value) =>
              ref.read(debugOptionsProvider.notifier).toggleLogging(),
        ),
      ],
    );
  }
}
