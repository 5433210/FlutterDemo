import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/enums/work_style.dart';
import '../../../domain/enums/work_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../common/section_title.dart';
import '../inputs/date_input_field.dart';
import '../inputs/dropdown_field.dart';

/// Material 3 version of the unified form component for work entity data entry
/// Can be used in both import and edit scenarios
///
class M3WorkForm extends StatefulWidget {
  /// The form title
  final String? title;

  /// Initial title value
  final String initialTitle;

  /// Initial author value
  final String? initialAuthor;

  /// Initial style value
  final WorkStyle? initialStyle;

  /// Initial tool value
  final WorkTool? initialTool;

  /// Initial creation date
  final DateTime? initialCreationDate;

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

  /// Callback when style changes
  final ValueChanged<WorkStyle?>? onStyleChanged;

  /// Callback when tool changes
  final ValueChanged<WorkTool?>? onToolChanged;

  /// Callback when creation date changes
  final ValueChanged<DateTime?>? onCreationDateChanged;

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
    this.initialCreationDate,
    this.initialRemark,
    this.isProcessing = false,
    this.error,
    this.onTitleChanged,
    this.onAuthorChanged,
    this.onStyleChanged,
    this.onToolChanged,
    this.onCreationDateChanged,
    this.onRemarkChanged,
    this.requiredFields = const {WorkFormField.title},
    this.visibleFields = const {
      WorkFormField.title,
      WorkFormField.author,
      WorkFormField.style,
      WorkFormField.tool,
      WorkFormField.creationDate,
      WorkFormField.remark,
    },
    this.showHelp = true,
    this.showKeyboardShortcuts = true,
    this.customFieldBuilders = const {},
    this.insertPositions = const {},
    this.formKey,
  });

  @override
  State<M3WorkForm> createState() => _M3WorkFormState();
}

/// Fields available in the work form
enum WorkFormField {
  title,
  author,
  style,
  tool,
  creationDate,
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
    WorkFormField.creationDate,
    WorkFormField.remark,
  };

  /// Edit form configuration
  static Set<WorkFormField> editFields = {
    WorkFormField.title,
    WorkFormField.author,
    WorkFormField.style,
    WorkFormField.tool,
    WorkFormField.creationDate,
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

class _M3WorkFormState extends State<M3WorkForm> {
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
            widget.onCreationDateChanged == null &&
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
              ],

              // Insert custom fields after tool
              ..._buildCustomFields(WorkFormField.tool),

              // Creation date field
              if (widget.visibleFields
                  .contains(WorkFormField.creationDate)) ...[
                const SizedBox(height: AppSizes.spacingMedium),
                _buildDateField(),
              ],

              // Insert custom fields after creation date
              ..._buildCustomFields(WorkFormField.creationDate),

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

  Widget _buildDateField() {
    final l10n = AppLocalizations.of(context);
    return _buildFieldWithTooltip(
      shortcut: 'Tab',
      tooltip: l10n.tabToNextField,
      helpText: widget.showHelp ? l10n.workFormDateHelp : null,
      helpIcon: Icons.calendar_today_outlined,
      child: DateInputField(
        label: l10n.creationDate,
        value: widget.initialCreationDate,
        onChanged: _handleDateChange,
        textInputAction: TextInputAction.next,
        onEditingComplete:
            _isReadOnly ? null : () => _remarkFocus.requestFocus(),
        enabled: true,
        readOnly: _isReadOnly,
      ),
    );
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

    return _buildFieldWithTooltip(
      shortcut: 'Tab',
      tooltip: l10n.tabToNextField,
      helpText: widget.showHelp ? l10n.workFormStyleHelp : null,
      helpIcon: Icons.palette_outlined,
      child: DropdownField<String>(
        label: l10n.calligraphyStyle,
        value: widget.initialStyle?.value,
        items: [
          DropdownMenuItem(
            value: WorkStyle.regular.value,
            child: Text(l10n.workStyleRegular),
          ),
          DropdownMenuItem(
            value: WorkStyle.running.value,
            child: Text(l10n.workStyleRunning),
          ),
          DropdownMenuItem(
            value: WorkStyle.cursive.value,
            child: Text(l10n.workStyleCursive),
          ),
          DropdownMenuItem(
            value: WorkStyle.clerical.value,
            child: Text(l10n.workStyleClerical),
          ),
          DropdownMenuItem(
            value: WorkStyle.seal.value,
            child: Text(l10n.workStyleSeal),
          ),
          DropdownMenuItem(
            value: WorkStyle.other.value,
            child: Text(l10n.workToolOther),
          ),
        ],
        onChanged: _handleStyleChange,
        enabled: true,
        readOnly: _isReadOnly,
        // Ensure dropdown text uses the same style as other fields
        textStyle: theme.textTheme.bodyLarge,
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

    return _buildFieldWithTooltip(
      shortcut: 'Tab',
      tooltip: l10n.tabToNextField,
      helpText: widget.showHelp ? l10n.workFormToolHelp : null,
      helpIcon: Icons.brush_outlined,
      child: DropdownField<String>(
        label: l10n.writingTool,
        value: widget.initialTool?.value,
        items: [
          DropdownMenuItem(
            value: WorkTool.brush.value,
            child: Text(l10n.workToolBrush),
          ),
          DropdownMenuItem(
            value: WorkTool.hardPen.value,
            child: Text(l10n.workToolHardPen),
          ),
          DropdownMenuItem(
            value: WorkTool.other.value,
            child: Text(l10n.workToolOther),
          ),
        ],
        onChanged: _handleToolChange,
        enabled: true,
        readOnly: _isReadOnly,
        // Ensure dropdown text uses the same style as other fields
        textStyle: theme.textTheme.bodyLarge,
      ),
    );
  }

  void _handleDateChange(DateTime? date) {
    final l10n = AppLocalizations.of(context);
    if (date != null) {
      if (date.isAfter(DateTime.now())) {
        // Date cannot be in the future
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.creationDate),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      widget.onCreationDateChanged?.call(date);
    }
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
      final style = WorkStyle.values.firstWhere(
        (s) => s.value == value,
        orElse: () => WorkStyle.other,
      );
      widget.onStyleChanged?.call(style);
      FocusScope.of(context).nextFocus();
    }
  }

  void _handleToolChange(String? value) {
    if (value != null && !widget.isProcessing) {
      final tool = WorkTool.values.firstWhere(
        (t) => t.value == value,
        orElse: () => WorkTool.other,
      );
      widget.onToolChanged?.call(tool);
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
