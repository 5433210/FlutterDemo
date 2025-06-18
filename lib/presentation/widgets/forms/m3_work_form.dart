import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Note: style and tool are now String types instead of enums
import '../../../infrastructure/providers/config_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../common/section_title.dart';
import '../inputs/dropdown_field.dart';

/// Material 3 version of the unified form component for work entity data entry
/// Can be used in both import and edit scenarios
///
class M3WorkForm extends ConsumerStatefulWidget {
  /// The form title
  final String? title;

  /// Initial title value
  final String initialTitle;

  /// Initial author value
  final String? initialAuthor;

  /// Initial style value (as string key)
  final String? initialStyle;

  /// Initial tool value (as string key)
  final String? initialTool;

  /// Initial remark value
  final String? initialRemark;

  /// Whether the form is in processing state (disabled)
  final bool isProcessing;

  /// Error message to display
  final String? error;

  /// Callback when title changes
  final ValueChanged<String>? onTitleChanged;

  /// Callback when author changes
  final ValueChanged<String?>? onAuthorChanged;

  /// Callback when style changes (string key)
  final ValueChanged<String?>? onStyleChanged;

  /// Callback when tool changes (string key)
  final ValueChanged<String?>? onToolChanged;

  /// Callback when remark changes
  final ValueChanged<String?>? onRemarkChanged;

  /// Which fields are required
  final Set<WorkFormField> requiredFields;

  /// Which fields to display
  final Set<WorkFormField> visibleFields;

  /// Show help text under fields
  final bool showHelp;

  /// Show keyboard shortcuts
  final bool showKeyboardShortcuts;

  /// Custom field builders for extending the form
  final Map<String, WidgetBuilder> customFieldBuilders;

  /// Positions to insert custom fields (by field name)
  final Map<WorkFormField, List<String>> insertPositions;

  /// Form key for validation
  final GlobalKey<FormState>? formKey;

  const M3WorkForm({
    super.key,
    this.title,
    this.initialTitle = '',
    this.initialAuthor,
    this.initialStyle,
    this.initialTool,
    this.initialRemark,
    this.isProcessing = false,
    this.error,
    this.onTitleChanged,
    this.onAuthorChanged,
    this.onStyleChanged,
    this.onToolChanged,
    this.onRemarkChanged,
    this.requiredFields = const {WorkFormField.title},
    this.visibleFields = const {
      WorkFormField.title,
      WorkFormField.author,
      WorkFormField.style,
      WorkFormField.tool,
      WorkFormField.remark,
    },
    this.showHelp = true,
    this.showKeyboardShortcuts = true,
    this.customFieldBuilders = const {},
    this.insertPositions = const {},
    this.formKey,
  });
  @override
  ConsumerState<M3WorkForm> createState() => _M3WorkFormState();
}

/// Fields available in the work form
enum WorkFormField {
  title,
  author,
  style,
  tool,
  remark,
}

/// Preset configurations for common WorkForm use cases
class WorkFormPresets {
  /// Import form configuration
  static Set<WorkFormField> importFields = {
    WorkFormField.title,
    WorkFormField.author,
    WorkFormField.style,
    WorkFormField.tool,
    WorkFormField.remark,
  };

  /// Edit form configuration
  static Set<WorkFormField> editFields = {
    WorkFormField.title,
    WorkFormField.author,
    WorkFormField.style,
    WorkFormField.tool,
    WorkFormField.remark,
  };

  /// Minimal form configuration
  static Set<WorkFormField> minimalFields = {
    WorkFormField.title,
    WorkFormField.author,
  };
}

class _ErrorAnimation extends StatefulWidget {
  final String errorText;
  final Color color;

  const _ErrorAnimation({
    required this.errorText,
    required this.color,
  });

  @override
  State<_ErrorAnimation> createState() => _ErrorAnimationState();
}

class _ErrorAnimationState extends State<_ErrorAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use a softer color for error text
    final errorColor = theme.colorScheme.tertiary.withAlpha(204);

    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.1, 0),
          end: Offset.zero,
        ).animate(_animation),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: Row(
            children: [
              Icon(
                Icons.info_outline, // Use info icon instead of error icon
                size: 14,
                color: errorColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.errorText,
                  style: TextStyle(
                    color: errorColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }
}

class _HelpText extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _HelpText({
    required this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: theme.hintColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _M3WorkFormState extends ConsumerState<M3WorkForm> {
  final _titleFocus = FocusNode();
  final _authorFocus = FocusNode();
  final _remarkFocus = FocusNode();

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _remarkController = TextEditingController();

  bool _hasInteracted = false;
  late GlobalKey<FormState> _formKey;
  // Check if form is in read-only mode based on callback presence
  bool get _isReadOnly {
    return widget.isProcessing ||
        (widget.onTitleChanged == null &&
            widget.onAuthorChanged == null &&
            widget.onStyleChanged == null &&
            widget.onToolChanged == null &&
            widget.onRemarkChanged == null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // Use a more gentle color for form error message
    final errorColor = theme.colorScheme.tertiary;

    return Focus(
      onKeyEvent: (_, event) {
        _handleKeyPress(event);
        return KeyEventResult.ignored;
      },
      child: Form(
        key: _formKey,
        autovalidateMode: _hasInteracted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.title != null) ...[
                SectionTitle(title: widget.title!),
                const SizedBox(height: AppSizes.spacingMedium),
              ],

              // Title field
              if (widget.visibleFields.contains(WorkFormField.title))
                _buildTitleField(),

              // Insert custom fields after title
              ..._buildCustomFields(WorkFormField.title),

              // Author field
              if (widget.visibleFields.contains(WorkFormField.author)) ...[
                const SizedBox(height: AppSizes.spacingMedium),
                _buildAuthorField(),
              ],

              // Insert custom fields after author
              ..._buildCustomFields(WorkFormField.author),

              // Style field
              if (widget.visibleFields.contains(WorkFormField.style)) ...[
                const SizedBox(height: AppSizes.spacingMedium),
                _buildStyleField(),
              ],

              // Insert custom fields after style
              ..._buildCustomFields(WorkFormField.style),

              // Tool field
              if (widget.visibleFields.contains(WorkFormField.tool)) ...[
                const SizedBox(height: AppSizes.spacingMedium),
                _buildToolField(),
              ], // Insert custom fields after tool
              ..._buildCustomFields(WorkFormField.tool),

              // Remark field
              if (widget.visibleFields.contains(WorkFormField.remark)) ...[
                const SizedBox(height: AppSizes.spacingMedium),
                _buildRemarkField(),
              ],

              // Insert custom fields after remark
              ..._buildCustomFields(WorkFormField.remark),

              // Form error message with gentler styling
              if (widget.error != null) ...[
                const SizedBox(height: AppSizes.spacingMedium),
                _ErrorAnimation(
                  errorText: widget.error!,
                  color: errorColor, // Use gentler color
                ),
              ],

              // Keyboard shortcuts section
              if (widget.showKeyboardShortcuts) ...[
                Text(
                  l10n.shortcuts,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSizes.spacingSmall),
                Text(
                  'Ctrl+T: ${l10n.title}  Ctrl+A: ${l10n.author}  Ctrl+R: ${l10n.remarks}\n'
                  'Enter: ${l10n.confirm}  Tab: ${l10n.nextField}  Shift+Tab: ${l10n.previousField}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(M3WorkForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateControllers();
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    _authorFocus.dispose();
    _remarkFocus.dispose();

    _titleController.dispose();
    _authorController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? GlobalKey<FormState>();
    _updateControllers();
    _setupKeyboardListeners();
  }

  // Mark form as interacted to show validation errors
  void markAsInteracted() {
    setState(() => _hasInteracted = true);
  }

  Widget _buildAuthorField() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final readOnlyFillColor = theme.disabledColor.withAlpha(13);

    return _buildFieldWithTooltip(
      shortcut: 'Ctrl+A',
      tooltip: l10n.workFormAuthorTooltip,
      helpText: widget.showHelp ? l10n.workFormAuthorHelp : null,
      helpIcon: Icons.person_outline,
      child: TextFormField(
        focusNode: _authorFocus,
        controller: _authorController,
        decoration: InputDecoration(
          labelText: l10n.author,
          hintText: _isReadOnly ? null : l10n.workFormAuthorHint,
          suffixText: _authorFocus.hasFocus && !_isReadOnly ? 'Ctrl+A' : null,
          errorStyle: const TextStyle(height: 0),
          counterText: '${_authorController.text.length}/50',
          filled: _isReadOnly,
          fillColor: _isReadOnly ? readOnlyFillColor : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: widget.onAuthorChanged,
        validator: _validateAuthor,
        textInputAction: TextInputAction.next,
        onEditingComplete: () => FocusScope.of(context).nextFocus(),
        enabled: true,
        readOnly: _isReadOnly,
        maxLength: 50,
        // Update readOnly style to match normal input style
        style: theme.textTheme.bodyLarge?.copyWith(
          color: _isReadOnly
              ? theme.textTheme.bodyLarge?.color
              : theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  List<Widget> _buildCustomFields(WorkFormField position) {
    final customFieldNames = widget.insertPositions[position] ?? [];
    return customFieldNames.map((name) {
      final builder = widget.customFieldBuilders[name];
      if (builder == null) return const SizedBox.shrink();

      return Column(
        children: [
          const SizedBox(height: AppSizes.spacingMedium),
          builder(context),
        ],
      );
    }).toList();
  }

  Widget _buildFieldWithTooltip({
    required Widget child,
    required String shortcut,
    required String tooltip,
    String? helpText,
    IconData? helpIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: tooltip,
          waitDuration: const Duration(milliseconds: 500),
          child: child,
        ),
        if (helpText != null)
          _HelpText(
            text: helpText,
            icon: helpIcon,
          ),
      ],
    );
  }

  Widget _buildRemarkField() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final readOnlyFillColor = theme.disabledColor.withAlpha(13);

    return _buildFieldWithTooltip(
      shortcut: 'Ctrl+R',
      tooltip: l10n.workFormRemarkTooltip,
      helpText: widget.showHelp ? l10n.workFormRemarkHelp : null,
      helpIcon: Icons.notes_outlined,
      child: TextFormField(
        focusNode: _remarkFocus,
        controller: _remarkController,
        decoration: InputDecoration(
          labelText: l10n.remarks,
          hintText: _isReadOnly ? null : l10n.optional,
          suffixText: _remarkFocus.hasFocus && !_isReadOnly ? 'Ctrl+R' : null,
          errorStyle: const TextStyle(height: 0),
          counterText: '${_remarkController.text.length}/500',
          filled: _isReadOnly,
          fillColor: _isReadOnly ? readOnlyFillColor : null,
          border: const OutlineInputBorder(),
        ),
        maxLines: 1,
        onChanged: widget.onRemarkChanged,
        validator: _validateRemark,
        textInputAction: TextInputAction.done,
        enabled: true,
        readOnly: _isReadOnly,
        maxLength: 500,
        // Update readOnly style to match normal input style
        style: theme.textTheme.bodyLarge?.copyWith(
          color: _isReadOnly
              ? theme.textTheme.bodyLarge?.color
              : theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildStyleField() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // 如果是只读模式，使用简化的显示方式
    if (_isReadOnly) {
      return _buildFieldWithTooltip(
        shortcut: 'Tab',
        tooltip: l10n.tabToNextField,
        helpText: widget.showHelp ? l10n.workFormStyleHelp : null,
        helpIcon: Icons.palette_outlined,
        child: _buildReadOnlyDropdown(
          label: l10n.calligraphyStyle,
          value: widget.initialStyle,
          displayNamesProvider: ref.watch(styleDisplayNamesProvider),
          fallbackDisplayName: widget.initialStyle ?? '',
        ),
      );
    }

    // Read dynamic configuration data
    final activeStyleItems = ref.watch(activeStyleItemsProvider);

    return _buildFieldWithTooltip(
      shortcut: 'Tab',
      tooltip: l10n.tabToNextField,
      helpText: widget.showHelp ? l10n.workFormStyleHelp : null,
      helpIcon: Icons.palette_outlined,
      child: activeStyleItems.when(
        data: (styleItems) {
          return DropdownField<String>(
            label: l10n.calligraphyStyle,
            value: widget.initialStyle,
            items: styleItems.map((item) {
              return DropdownMenuItem(
                value: item.key,
                child: Consumer(
                  builder: (context, ref, child) {
                    final displayName = ref
                        .watch(styleDisplayNamesProvider)
                        .maybeWhen(
                          data: (names) => names[item.key] ?? item.displayName,
                          orElse: () => item.displayName,
                        );
                    return Text(displayName);
                  },
                ),
              );
            }).toList(),
            onChanged: _handleStyleChange,
            enabled: true,
            readOnly: _isReadOnly,
            textStyle: theme.textTheme.bodyLarge,
          );
        },
        loading: () => DropdownField<String>(
          label: l10n.calligraphyStyle,
          value: widget.initialStyle,
          items: const [
            DropdownMenuItem(
              value: '',
              child: Text('Loading...'),
            ),
          ],
          onChanged: null,
          enabled: false,
          readOnly: true,
          textStyle: theme.textTheme.bodyLarge,
        ),
        error: (error, stackTrace) {
          // Fallback to hardcoded options on error
          return DropdownField<String>(
            label: l10n.calligraphyStyle,
            value: widget.initialStyle,
            items: [
              DropdownMenuItem(
                value: 'regular',
                child: Text(l10n.workStyleRegular),
              ),
              DropdownMenuItem(
                value: 'running',
                child: Text(l10n.workStyleRunning),
              ),
              DropdownMenuItem(
                value: 'cursive',
                child: Text(l10n.workStyleCursive),
              ),
              DropdownMenuItem(
                value: 'clerical',
                child: Text(l10n.workStyleClerical),
              ),
              DropdownMenuItem(
                value: 'seal',
                child: Text(l10n.workStyleSeal),
              ),
              DropdownMenuItem(
                value: 'other',
                child: Text(l10n.workToolOther),
              ),
            ],
            onChanged: _handleStyleChange,
            enabled: true,
            readOnly: _isReadOnly,
            textStyle: theme.textTheme.bodyLarge,
          );
        },
      ),
    );
  }

  Widget _buildTitleField() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final readOnlyFillColor = theme.disabledColor.withAlpha(13);

    return _buildFieldWithTooltip(
      shortcut: 'Ctrl+T',
      tooltip: l10n.workFormTitleTooltip,
      helpText: widget.showHelp ? l10n.workFormTitleHelp : null,
      helpIcon: Icons.info_outline,
      child: TextFormField(
        focusNode: _titleFocus,
        controller: _titleController,
        decoration: InputDecoration(
          labelText: widget.requiredFields.contains(WorkFormField.title)
              ? '${l10n.title} *'
              : l10n.title,
          hintText: _isReadOnly ? null : l10n.inputTitle,
          suffixText: _titleFocus.hasFocus && !_isReadOnly ? 'Ctrl+T' : null,
          errorStyle: const TextStyle(height: 0),
          counterText: '${_titleController.text.length}/100',
          filled: _isReadOnly,
          fillColor: _isReadOnly ? readOnlyFillColor : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: widget.onTitleChanged,
        validator: _validateTitle,
        textInputAction: TextInputAction.next,
        onEditingComplete: () => _authorFocus.requestFocus(),
        enabled: true,
        readOnly: _isReadOnly,
        maxLength: 100,
        // Update readOnly style to match normal input style
        style: theme.textTheme.bodyLarge?.copyWith(
          color: _isReadOnly
              ? theme.textTheme.bodyLarge?.color
              : theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildToolField() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // 如果是只读模式，使用简化的显示方式
    if (_isReadOnly) {
      return _buildFieldWithTooltip(
        shortcut: 'Tab',
        tooltip: l10n.tabToNextField,
        helpText: widget.showHelp ? l10n.workFormToolHelp : null,
        helpIcon: Icons.brush_outlined,
        child: _buildReadOnlyDropdown(
          label: l10n.writingTool,
          value: widget.initialTool,
          displayNamesProvider: ref.watch(toolDisplayNamesProvider),
          fallbackDisplayName: widget.initialTool ?? '',
        ),
      );
    }

    // Read dynamic configuration data
    final activeToolItems = ref.watch(activeToolItemsProvider);

    return _buildFieldWithTooltip(
      shortcut: 'Tab',
      tooltip: l10n.tabToNextField,
      helpText: widget.showHelp ? l10n.workFormToolHelp : null,
      helpIcon: Icons.brush_outlined,
      child: activeToolItems.when(
        data: (toolItems) {
          return DropdownField<String>(
            label: l10n.writingTool,
            value: widget.initialTool,
            items: toolItems.map((item) {
              return DropdownMenuItem(
                value: item.key,
                child: Consumer(
                  builder: (context, ref, child) {
                    final displayName = ref
                        .watch(toolDisplayNamesProvider)
                        .maybeWhen(
                          data: (names) => names[item.key] ?? item.displayName,
                          orElse: () => item.displayName,
                        );
                    return Text(displayName);
                  },
                ),
              );
            }).toList(),
            onChanged: _handleToolChange,
            enabled: true,
            readOnly: _isReadOnly,
            textStyle: theme.textTheme.bodyLarge,
          );
        },
        loading: () => DropdownField<String>(
          label: l10n.writingTool,
          value: widget.initialTool,
          items: const [
            DropdownMenuItem(
              value: '',
              child: Text('Loading...'),
            ),
          ],
          onChanged: null,
          enabled: false,
          readOnly: true,
          textStyle: theme.textTheme.bodyLarge,
        ),
        error: (error, stackTrace) {
          // Fallback to hardcoded options on error
          return DropdownField<String>(
            label: l10n.writingTool,
            value: widget.initialTool,
            items: [
              DropdownMenuItem(
                value: 'brush',
                child: Text(l10n.workToolBrush),
              ),
              DropdownMenuItem(
                value: 'hardPen',
                child: Text(l10n.workToolHardPen),
              ),
              DropdownMenuItem(
                value: 'other',
                child: Text(l10n.workToolOther),
              ),
            ],
            onChanged: _handleToolChange,
            enabled: true,
            readOnly: _isReadOnly,
            textStyle: theme.textTheme.bodyLarge,
          );
        },
      ),
    );
  }

  /// 为只读模式创建简化的下拉字段，直接显示配置项的显示名称
  Widget _buildReadOnlyDropdown({
    required String label,
    required String? value,
    required AsyncValue<Map<String, String>> displayNamesProvider,
    required String fallbackDisplayName,
  }) {
    final theme = Theme.of(context);

    return displayNamesProvider.when(
      data: (displayNames) {
        final displayText =
            value != null ? displayNames[value] ?? fallbackDisplayName : '';

        return TextFormField(
          initialValue: displayText,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: theme.disabledColor,
            ),
            filled: true,
            fillColor: theme.disabledColor.withValues(alpha: 0.05),
          ),
          enabled: true,
          readOnly: true,
          style: theme.textTheme.bodyLarge,
        );
      },
      loading: () => TextFormField(
        initialValue: 'Loading...',
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: theme.disabledColor,
          ),
          filled: true,
          fillColor: theme.disabledColor.withValues(alpha: 0.05),
        ),
        enabled: false,
        readOnly: true,
        style: theme.textTheme.bodyLarge,
      ),
      error: (error, stackTrace) => TextFormField(
        initialValue: fallbackDisplayName,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: theme.disabledColor,
          ),
          filled: true,
          fillColor: theme.disabledColor.withValues(alpha: 0.05),
        ),
        enabled: true,
        readOnly: true,
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  void _handleFocusChange() {
    setState(() {});
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (!HardwareKeyboard.instance.isControlPressed) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyT:
        _titleFocus.requestFocus();
        break;
      case LogicalKeyboardKey.keyA:
        _authorFocus.requestFocus();
        break;
      case LogicalKeyboardKey.keyR:
        _remarkFocus.requestFocus();
        break;
      default:
        break;
    }
  }

  void _handleStyleChange(String? value) {
    if (value != null && !widget.isProcessing) {
      widget.onStyleChanged?.call(value);
      FocusScope.of(context).nextFocus();
    }
  }

  void _handleToolChange(String? value) {
    if (value != null && !widget.isProcessing) {
      widget.onToolChanged?.call(value);
      FocusScope.of(context).nextFocus();
    }
  }

  void _setupKeyboardListeners() {
    _titleFocus.addListener(_handleFocusChange);
    _authorFocus.addListener(_handleFocusChange);
    _remarkFocus.addListener(_handleFocusChange);
  }

  void _updateControllers() {
    final newText = widget.initialTitle;
    if (_titleController.text != newText) {
      _titleController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    final newAuthor = widget.initialAuthor ?? '';
    if (_authorController.text != newAuthor) {
      _authorController.value = TextEditingValue(
        text: newAuthor,
        selection: TextSelection.collapsed(offset: newAuthor.length),
      );
    }

    final newRemark = widget.initialRemark ?? '';
    if (_remarkController.text != newRemark) {
      _remarkController.value = TextEditingValue(
        text: newRemark,
        selection: TextSelection.collapsed(offset: newRemark.length),
      );
    }
  }

  String? _validateAuthor(String? value) {
    if (!_hasInteracted) return null;
    final l10n = AppLocalizations.of(context);
    if (value != null && value.trim().length > 50) {
      return l10n.workFormAuthorMaxLength;
    }
    return null;
  }

  String? _validateRemark(String? value) {
    if (!_hasInteracted) return null;
    final l10n = AppLocalizations.of(context);
    if (value != null && value.trim().length > 500) {
      return l10n.workFormRemarkMaxLength;
    }
    return null;
  }

  String? _validateTitle(String? value) {
    if (!_hasInteracted) return null;
    final l10n = AppLocalizations.of(context);

    if (widget.requiredFields.contains(WorkFormField.title)) {
      if (value == null || value.trim().isEmpty) {
        return l10n.workFormTitleRequired;
      }
      if (value.trim().length < 2) {
        return l10n.workFormTitleMinLength;
      }
    }

    if (value != null && value.trim().length > 100) {
      return l10n.workFormTitleMaxLength;
    }

    return null;
  }
}
