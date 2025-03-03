import 'package:flutter/material.dart';

class CollectionToolbar extends StatelessWidget {
  final String title;
  final bool autoDetectStrokes;
  final double noiseReduction;
  final double binarization;
  final double grayscaleRange;
  final ValueChanged<bool> onAutoDetectStrokesChanged;
  final ValueChanged<double> onNoiseReductionChanged;
  final ValueChanged<double> onBinarizationChanged;
  final ValueChanged<double> onGrayscaleRangeChanged;
  final VoidCallback onReset;
  final VoidCallback onClose;

  const CollectionToolbar({
    super.key,
    required this.title,
    required this.autoDetectStrokes,
    required this.noiseReduction,
    required this.binarization,
    required this.grayscaleRange,
    required this.onAutoDetectStrokesChanged,
    required this.onNoiseReductionChanged,
    required this.onBinarizationChanged,
    required this.onGrayscaleRangeChanged,
    required this.onReset,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left: Close button and title
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            tooltip: '退出集字模式',
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 32),

          // Center: Preprocessing tools group
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Auto detect strokes switch
                Row(
                  children: [
                    const Text('自动识别笔画'),
                    const SizedBox(width: 8),
                    Switch(
                      value: autoDetectStrokes,
                      onChanged: onAutoDetectStrokesChanged,
                    ),
                  ],
                ),
                const SizedBox(width: 24),

                // Noise reduction slider
                Flexible(
                  child: Row(
                    children: [
                      const Text('降噪'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: noiseReduction,
                          onChanged: onNoiseReductionChanged,
                        ),
                      ),
                    ],
                  ),
                ),

                // Binarization slider
                Flexible(
                  child: Row(
                    children: [
                      const Text('二值化'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: binarization,
                          onChanged: onBinarizationChanged,
                        ),
                      ),
                    ],
                  ),
                ),

                // Grayscale range slider
                Flexible(
                  child: Row(
                    children: [
                      const Text('灰度范围'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: grayscaleRange,
                          onChanged: onGrayscaleRangeChanged,
                        ),
                      ),
                    ],
                  ),
                ),

                // Reset button
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重置'),
                ),
              ],
            ),
          ),

          // Right: Operation tools group
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: () {
                  // Handle undo
                },
                tooltip: '撤销',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: () {
                  // Handle redo
                },
                tooltip: '重做',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
