import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/enums/work_style.dart';
import '../../../domain/enums/work_tool.dart';
import '../../../theme/app_sizes.dart';
import '../common/section_title.dart';
import '../inputs/date_input_field.dart';
import '../inputs/dropdown_field.dart';

/// A unified form component for work entity data entry
/// Can be used in both import and edit scenarios
class WorkForm extends StatefulWidget {
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

  const WorkForm({
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
  State<WorkForm> createState() => _WorkFormState();
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
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.1, 0),
          end: Offset.zero,
        ).animate(_animation),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: Text(
            widget.errorText,
            style: TextStyle(
              color: widget.color,
              fontSize: 12,
            ),
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

class _WorkFormState extends State<WorkForm> {
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

    return Focus(
      onKey: (_, event) {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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

              // Form error message
              if (widget.error != null) ...[
                const SizedBox(height: AppSizes.spacingMedium),
                _ErrorAnimation(
                  errorText: widget.error!,
                  color: theme.colorScheme.error,
                ),
              ],

              // Keyboard shortcuts section
              if (widget.showKeyboardShortcuts) ...[
                const SizedBox(height: AppSizes.spacingLarge),
                Text(
                  '键盘快捷键:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSizes.spacingSmall),
                Text(
                  'Ctrl+T: 标题  Ctrl+A: 作者  Ctrl+R: 备注\n'
                  'Enter: 确认  Tab: 下一项  Shift+Tab: 上一项',
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
  void didUpdateWidget(WorkForm oldWidget) {
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
    final readOnlyFillColor = theme.disabledColor.withOpacity(0.05);

    return _buildFieldWithTooltip(
      shortcut: 'Ctrl+A',
      tooltip: '按 Ctrl+A 快速跳转到作者输入框',
      helpText: widget.showHelp ? '可选，作品的创作者' : null,
      helpIcon: Icons.person_outline,
      child: TextFormField(
        focusNode: _authorFocus,
        controller: _authorController,
        decoration: InputDecoration(
          labelText: '作者',
          hintText: _isReadOnly ? null : '请输入作者名',
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
        style: _isReadOnly
            ? TextStyle(color: theme.textTheme.bodyLarge?.color)
            : null,
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
    return _buildFieldWithTooltip(
      shortcut: 'Tab',
      tooltip: '按 Tab 键导航到下一个字段',
      helpText: widget.showHelp ? '作品的完成日期' : null,
      helpIcon: Icons.calendar_today_outlined,
      child: DateInputField(
        label: '创作日期',
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
    final readOnlyFillColor = theme.disabledColor.withOpacity(0.05);

    return _buildFieldWithTooltip(
      shortcut: 'Ctrl+R',
      tooltip: '按 Ctrl+R 快速跳转到备注输入框',
      helpText: widget.showHelp ? '可选，关于作品的其他说明' : null,
      helpIcon: Icons.notes_outlined,
      child: TextFormField(
        focusNode: _remarkFocus,
        controller: _remarkController,
        decoration: InputDecoration(
          labelText: '备注',
          hintText: _isReadOnly ? null : '可选',
          suffixText: _remarkFocus.hasFocus && !_isReadOnly ? 'Ctrl+R' : null,
          errorStyle: const TextStyle(height: 0),
          counterText: '${_remarkController.text.length}/500',
          filled: _isReadOnly,
          fillColor: _isReadOnly ? readOnlyFillColor : null,
          border: const OutlineInputBorder(),
        ),
        maxLines: 3,
        onChanged: widget.onRemarkChanged,
        validator: _validateRemark,
        textInputAction: TextInputAction.done,
        enabled: true,
        readOnly: _isReadOnly,
        maxLength: 500,
        style: _isReadOnly
            ? TextStyle(color: theme.textTheme.bodyLarge?.color)
            : null,
      ),
    );
  }

  Widget _buildStyleField() {
    return _buildFieldWithTooltip(
      shortcut: 'Tab',
      tooltip: '按 Tab 键导航到下一个字段',
      helpText: widget.showHelp ? '作品的主要画风类型' : null,
      helpIcon: Icons.palette_outlined,
      child: DropdownField<String>(
        label: '画风',
        value: widget.initialStyle?.value,
        items: WorkStyle.values
            .map((e) => DropdownMenuItem(
                  value: e.value,
                  child: Text(e.label),
                ))
            .toList(),
        onChanged: _handleStyleChange,
        enabled: true,
        readOnly: _isReadOnly,
      ),
    );
  }

  Widget _buildTitleField() {
    final theme = Theme.of(context);
    final readOnlyFillColor = theme.disabledColor.withOpacity(0.05);

    return _buildFieldWithTooltip(
      shortcut: 'Ctrl+T',
      tooltip: '按 Ctrl+T 快速跳转到标题输入框',
      helpText: widget.showHelp ? '作品的主要标题，将显示在作品列表中' : null,
      helpIcon: Icons.info_outline,
      child: TextFormField(
        focusNode: _titleFocus,
        controller: _titleController,
        decoration: InputDecoration(
          labelText: widget.requiredFields.contains(WorkFormField.title)
              ? '标题 *'
              : '标题',
          hintText: _isReadOnly ? null : '请输入标题',
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
        style: _isReadOnly
            ? TextStyle(color: theme.textTheme.bodyLarge?.color)
            : null,
      ),
    );
  }

  Widget _buildToolField() {
    return _buildFieldWithTooltip(
      shortcut: 'Tab',
      tooltip: '按 Tab 键导航到下一个字段',
      helpText: widget.showHelp ? '创作本作品使用的主要工具' : null,
      helpIcon: Icons.brush_outlined,
      child: DropdownField<String>(
        label: '创作工具',
        value: widget.initialTool?.value,
        items: WorkTool.values
            .map((e) => DropdownMenuItem(
                  value: e.value,
                  child: Text(e.label),
                ))
            .toList(),
        onChanged: _handleToolChange,
        enabled: true,
        readOnly: _isReadOnly,
      ),
    );
  }

  void _handleDateChange(DateTime? date) {
    if (date != null) {
      if (date.isAfter(DateTime.now())) {
        // 日期不能超过当前日期
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('创作日期不能超过当前日期'),
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

  void _handleKeyPress(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    if (!event.isControlPressed) return;

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
    if (value != null && value.trim().length > 50) {
      return '作者名不能超过50个字符';
    }
    return null;
  }

  String? _validateRemark(String? value) {
    if (!_hasInteracted) return null;
    if (value != null && value.trim().length > 500) {
      return '备注不能超过500个字符';
    }
    return null;
  }

  String? _validateTitle(String? value) {
    if (!_hasInteracted) return null;

    if (widget.requiredFields.contains(WorkFormField.title)) {
      if (value == null || value.trim().isEmpty) {
        return '请输入作品标题';
      }
      if (value.trim().length < 2) {
        return '标题至少需要2个字符';
      }
    }

    if (value != null && value.trim().length > 100) {
      return '标题不能超过100个字符';
    }

    return null;
  }
}
