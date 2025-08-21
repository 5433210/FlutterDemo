import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../common/editable_number_field.dart';

/// Material 3 Text format panel for collection elements
class M3TextFormatPanel extends StatefulWidget {
  final Map<String, dynamic> content;
  final Function(String, dynamic) onContentPropertyChanged;
  final Function(String, dynamic)? onContentPropertyUpdateStart;
  final Function(String, dynamic)? onContentPropertyUpdatePreview;
  final Function(String, dynamic, dynamic)? onContentPropertyUpdateWithUndo;

  const M3TextFormatPanel({
    Key? key,
    required this.content,
    required this.onContentPropertyChanged,
    this.onContentPropertyUpdateStart,
    this.onContentPropertyUpdatePreview,
    this.onContentPropertyUpdateWithUndo,
  }) : super(key: key);

  @override
  State<M3TextFormatPanel> createState() => _M3TextFormatPanelState();
}

class _M3TextFormatPanelState extends State<M3TextFormatPanel> {
  // 滑块拖动时的原始值
  double? _originalFontSize;
  double? _originalLetterSpacing;
  double? _originalLineSpacing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final fontSize = (widget.content['fontSize'] as num?)?.toDouble() ?? 100.0;
    final lineSpacing =
        (widget.content['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final letterSpacing =
        (widget.content['letterSpacing'] as num?)?.toDouble() ?? 5.0;
    final textAlign = widget.content['textAlign'] as String? ?? 'left';
    final verticalAlign = widget.content['verticalAlign'] as String? ?? 'top';
    final writingMode =
        widget.content['writingMode'] as String? ?? 'horizontal-l';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Font size
        Text(
          '${l10n.fontSize}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: fontSize.clamp(10, 500), // Clamp for slider range
                min: 10,
                max:
                    500, // Slider max 500 for usability, but input field allows up to 2000
                divisions: 490,
                label: '${fontSize.round()}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChangeStart: (value) {
                  // 拖动开始时保存原始值
                  _originalFontSize = fontSize;
                  if (widget.onContentPropertyUpdateStart != null) {
                    widget.onContentPropertyUpdateStart!('fontSize', fontSize);
                  }
                },
                onChanged: (value) {
                  if (widget.onContentPropertyUpdatePreview != null) {
                    widget.onContentPropertyUpdatePreview!('fontSize', value);
                  } else {
                    _updateContentPropertyPreview('fontSize', value);
                  }
                },
                onChangeEnd: (value) {
                  _updateContentPropertyWithUndo(
                      'fontSize', value, _originalFontSize);
                  _originalFontSize = null;
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.fontSize,
                value: fontSize,
                suffix: 'px',
                min: 10,
                max: 2000,
                onChanged: (value) {
                  widget.onContentPropertyChanged('fontSize', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Letter spacing
        Text(
          '${l10n.letterSpacing}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: letterSpacing.clamp(0, 500),
                min: 0,
                max: 500,
                divisions: 500,
                label: '${letterSpacing.round()}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChangeStart: (value) {
                  // 拖动开始时保存原始值
                  _originalLetterSpacing = letterSpacing;
                  if (widget.onContentPropertyUpdateStart != null) {
                    widget.onContentPropertyUpdateStart!(
                        'letterSpacing', letterSpacing);
                  }
                },
                onChanged: (value) {
                  if (widget.onContentPropertyUpdatePreview != null) {
                    widget.onContentPropertyUpdatePreview!(
                        'letterSpacing', value);
                  } else {
                    _updateContentPropertyPreview('letterSpacing', value);
                  }
                },
                onChangeEnd: (value) {
                  _updateContentPropertyWithUndo(
                      'letterSpacing', value, _originalLetterSpacing);
                  _originalLetterSpacing = null;
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.letterSpacing,
                value: letterSpacing,
                suffix: 'px',
                min: 0,
                max: 500,
                decimalPlaces: 1,
                onChanged: (value) {
                  widget.onContentPropertyChanged('letterSpacing', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Line spacing
        Text(
          '${l10n.lineHeight}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: lineSpacing.clamp(0, 500),
                min: 0,
                max: 500,
                divisions: 500,
                label: '${lineSpacing.round()}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChangeStart: (value) {
                  // 拖动开始时保存原始值
                  _originalLineSpacing = lineSpacing;
                  if (widget.onContentPropertyUpdateStart != null) {
                    widget.onContentPropertyUpdateStart!(
                        'lineSpacing', lineSpacing);
                  }
                },
                onChanged: (value) {
                  if (widget.onContentPropertyUpdatePreview != null) {
                    widget.onContentPropertyUpdatePreview!(
                        'lineSpacing', value);
                  } else {
                    _updateContentPropertyPreview('lineSpacing', value);
                  }
                },
                onChangeEnd: (value) {
                  _updateContentPropertyWithUndo(
                      'lineSpacing', value, _originalLineSpacing);
                  _originalLineSpacing = null;
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.lineHeight,
                value: lineSpacing,
                suffix: 'px',
                min: 0,
                max: 500,
                decimalPlaces: 1,
                onChanged: (value) {
                  widget.onContentPropertyChanged('lineSpacing', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Horizontal alignment - using Card with IconButtons like text panel
        Text(
          '${l10n.textAlign}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left align
                Tooltip(
                  message: l10n.alignLeft,
                  child: IconButton(
                    icon: const Icon(Icons.format_align_left),
                    isSelected: textAlign == 'left',
                    selectedIcon: Icon(Icons.format_align_left,
                        color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged('textAlign', 'left');
                    },
                  ),
                ),
                // Center align
                Tooltip(
                  message: l10n.alignCenter,
                  child: IconButton(
                    icon: const Icon(Icons.format_align_center),
                    isSelected: textAlign == 'center',
                    selectedIcon: Icon(Icons.format_align_center,
                        color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged('textAlign', 'center');
                    },
                  ),
                ),
                // Right align
                Tooltip(
                  message: l10n.alignRight,
                  child: IconButton(
                    icon: const Icon(Icons.format_align_right),
                    isSelected: textAlign == 'right',
                    selectedIcon: Icon(Icons.format_align_right,
                        color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged('textAlign', 'right');
                    },
                  ),
                ),
                // Justify
                Tooltip(
                  message: l10n.distribution,
                  child: IconButton(
                    icon: const Icon(Icons.format_align_justify),
                    isSelected: textAlign == 'justify',
                    selectedIcon: Icon(Icons.format_align_justify,
                        color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged('textAlign', 'justify');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // Vertical alignment - using Card with IconButtons like text panel
        Text(
          '${l10n.verticalAlignment}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Top align
                Tooltip(
                  message: l10n.alignTop,
                  child: IconButton(
                    icon: const Icon(Icons.vertical_align_top),
                    isSelected: verticalAlign == 'top',
                    selectedIcon: Icon(Icons.vertical_align_top,
                        color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged('verticalAlign', 'top');
                    },
                  ),
                ),
                // Middle align
                Tooltip(
                  message: l10n.alignMiddle,
                  child: IconButton(
                    icon: const Icon(Icons.vertical_align_center),
                    isSelected: verticalAlign == 'middle',
                    selectedIcon: Icon(Icons.vertical_align_center,
                        color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged(
                          'verticalAlign', 'middle');
                    },
                  ),
                ),
                // Bottom align
                Tooltip(
                  message: l10n.alignBottom,
                  child: IconButton(
                    icon: const Icon(Icons.vertical_align_bottom),
                    isSelected: verticalAlign == 'bottom',
                    selectedIcon: Icon(Icons.vertical_align_bottom,
                        color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged(
                          'verticalAlign', 'bottom');
                    },
                  ),
                ),
                // Justify
                Tooltip(
                  message: l10n.distribution,
                  child: IconButton(
                    icon: const Icon(Icons.height),
                    isSelected: verticalAlign == 'justify',
                    selectedIcon:
                        Icon(Icons.height, color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged(
                          'verticalAlign', 'justify');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // Writing direction - using Card with IconButtons like text panel
        Text(
          '${l10n.writingMode}:',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Horizontal Left-to-Right
                Tooltip(
                  message: l10n.horizontalLeftToRight,
                  child: IconButton(
                    icon: const Icon(Icons.format_textdirection_l_to_r),
                    isSelected: writingMode == 'horizontal-l',
                    selectedIcon: Icon(Icons.format_textdirection_l_to_r,
                        color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged(
                          'writingMode', 'horizontal-l');
                    },
                  ),
                ),
                // Vertical Right-to-Left
                Tooltip(
                  message: l10n.verticalRightToLeft,
                  child: IconButton(
                    icon: const Icon(Icons.format_textdirection_r_to_l),
                    isSelected: writingMode == 'vertical-r',
                    selectedIcon: Icon(Icons.format_textdirection_r_to_l,
                        color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged(
                          'writingMode', 'vertical-r');
                    },
                  ),
                ),
                // Horizontal Right-to-Left
                Tooltip(
                  message: l10n.horizontalRightToLeft,
                  child: IconButton(
                    icon: const Icon(Icons.format_textdirection_r_to_l),
                    isSelected: writingMode == 'horizontal-r',
                    selectedIcon: Icon(Icons.format_textdirection_r_to_l,
                        color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged(
                          'writingMode', 'horizontal-r');
                    },
                  ),
                ),
                // Vertical Left-to-Right
                Tooltip(
                  message: l10n.verticalLeftToRight,
                  child: IconButton(
                    icon: const Icon(Icons.format_textdirection_l_to_r),
                    isSelected: writingMode == 'vertical-l',
                    selectedIcon: Icon(Icons.format_textdirection_l_to_r,
                        color: colorScheme.primary),
                    onPressed: () {
                      widget.onContentPropertyChanged(
                          'writingMode', 'vertical-l');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 仅预览更新内容属性，不记录undo（用于滑块拖动过程中的实时预览）
  void _updateContentPropertyPreview(String key, dynamic value) {
    // 这个组件没有访问controller，所以暂时使用setState来更新UI
    setState(() {
      // UI会根据新值重新渲染
    });
  }

  /// 基于原始值更新内容属性并记录undo操作（用于滑块拖动结束）
  void _updateContentPropertyWithUndo(
      String key, dynamic newValue, dynamic originalValue) {
    // 如果有原始值且值发生了变化，使用撤销机制
    if (originalValue != null && originalValue != newValue) {
      // 优先使用主面板的撤销回调
      if (widget.onContentPropertyUpdateWithUndo != null) {
        widget.onContentPropertyUpdateWithUndo!(key, newValue, originalValue);
      } else {
        // 备用方案：使用本地撤销逻辑
        // 先调用开始回调保存原始值
        if (widget.onContentPropertyUpdateStart != null) {
          widget.onContentPropertyUpdateStart!(key, originalValue);
        }

        // 然后更新到最终值
        widget.onContentPropertyChanged(key, newValue);
      }
    } else {
      // 值没有变化，直接更新
      widget.onContentPropertyChanged(key, newValue);
    }
  }
}
