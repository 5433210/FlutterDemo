import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../domain/enums/work_style.dart';
import '../../../../../domain/enums/work_tool.dart';
import '../../../../../theme/app_sizes.dart';
import '../../../../viewmodels/states/work_import_state.dart';
import '../../../../viewmodels/work_import_view_model.dart';
import '../../../../widgets/inputs/date_input_field.dart';
import '../../../../widgets/inputs/dropdown_field.dart';

/// Form for entering work metadata during import
class WorkImportForm extends StatefulWidget {
  final WorkImportState state;
  final WorkImportViewModel viewModel;

  const WorkImportForm({
    super.key,
    required this.state,
    required this.viewModel,
  });

  @override
  State<WorkImportForm> createState() => _WorkImportFormState();
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

class _WorkImportFormState extends State<WorkImportForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleFocus = FocusNode();
  final _authorFocus = FocusNode();
  final _remarkFocus = FocusNode();

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _remarkController = TextEditingController();

  bool _hasInteracted = false;

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
              // 标题 (Ctrl+T)
              _buildFieldWithTooltip(
                shortcut: 'Ctrl+T',
                tooltip: '按 Ctrl+T 快速跳转到标题输入框',
                helpText: '作品的主要标题，将显示在作品列表中',
                helpIcon: Icons.info_outline,
                child: TextFormField(
                  focusNode: _titleFocus,
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: '标题 *',
                    hintText: '请输入标题',
                    suffixText: _titleFocus.hasFocus ? 'Ctrl+T' : null,
                    errorStyle: const TextStyle(height: 0),
                    counterText: '${_titleController.text.length}/100',
                  ),
                  onChanged: widget.viewModel.setTitle,
                  validator: _validateTitle,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => _authorFocus.requestFocus(),
                  enabled: !widget.state.isProcessing,
                  maxLength: 100,
                ),
              ),
              if (_hasInteracted &&
                  _validateTitle(_titleController.text) != null)
                _ErrorAnimation(
                  errorText: _validateTitle(_titleController.text)!,
                  color: theme.colorScheme.error,
                ),
              const SizedBox(height: AppSizes.m),

              // 作者 (Ctrl+A)
              _buildFieldWithTooltip(
                shortcut: 'Ctrl+A',
                tooltip: '按 Ctrl+A 快速跳转到作者输入框',
                helpText: '可选，作品的创作者',
                helpIcon: Icons.person_outline,
                child: TextFormField(
                  focusNode: _authorFocus,
                  controller: _authorController,
                  decoration: InputDecoration(
                    labelText: '作者',
                    hintText: '请输入作者名',
                    suffixText: _authorFocus.hasFocus ? 'Ctrl+A' : null,
                    errorStyle: const TextStyle(height: 0),
                    counterText: '${_authorController.text.length}/50',
                  ),
                  onChanged: widget.viewModel.setAuthor,
                  validator: _validateAuthor,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  enabled: !widget.state.isProcessing,
                  maxLength: 50,
                ),
              ),
              if (_hasInteracted &&
                  _validateAuthor(_authorController.text) != null)
                _ErrorAnimation(
                  errorText: _validateAuthor(_authorController.text)!,
                  color: theme.colorScheme.error,
                ),
              const SizedBox(height: AppSizes.m),

              // 画风
              _buildFieldWithTooltip(
                shortcut: 'Tab',
                tooltip: '按 Tab 键导航到下一个字段',
                helpText: '作品的主要画风类型',
                helpIcon: Icons.palette_outlined,
                child: DropdownField<String>(
                  label: '画风',
                  value: widget.state.style?.value,
                  items: WorkStyle.values
                      .map((e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(e.label),
                          ))
                      .toList(),
                  onChanged: _handleStyleChange,
                ),
              ),
              const SizedBox(height: AppSizes.m),

              // 创作工具
              _buildFieldWithTooltip(
                shortcut: 'Tab',
                tooltip: '按 Tab 键导航到下一个字段',
                helpText: '创作本作品使用的主要工具',
                helpIcon: Icons.brush_outlined,
                child: DropdownField<String>(
                  label: '创作工具',
                  value: widget.state.tool?.value,
                  items: WorkTool.values
                      .map((e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(e.label),
                          ))
                      .toList(),
                  onChanged: _handleToolChange,
                ),
              ),
              const SizedBox(height: AppSizes.m),

              // 创作日期
              _buildFieldWithTooltip(
                shortcut: 'Tab',
                tooltip: '按 Tab 键导航到下一个字段',
                helpText: '作品的完成日期',
                helpIcon: Icons.calendar_today_outlined,
                child: DateInputField(
                  label: '创作日期',
                  value: widget.state.creationDate,
                  onChanged: _handleDateChange,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => _remarkFocus.requestFocus(),
                ),
              ),
              const SizedBox(height: AppSizes.m),

              // 备注 (Ctrl+R)
              _buildFieldWithTooltip(
                shortcut: 'Ctrl+R',
                tooltip: '按 Ctrl+R 快速跳转到备注输入框',
                helpText: '可选，关于作品的其他说明',
                helpIcon: Icons.notes_outlined,
                child: TextFormField(
                  focusNode: _remarkFocus,
                  controller: _remarkController,
                  decoration: InputDecoration(
                    labelText: '备注',
                    hintText: '可选',
                    suffixText: _remarkFocus.hasFocus ? 'Ctrl+R' : null,
                    errorStyle: const TextStyle(height: 0),
                    counterText: '${_remarkController.text.length}/500',
                  ),
                  maxLines: 3,
                  onChanged: widget.viewModel.setRemark,
                  validator: _validateRemark,
                  textInputAction: TextInputAction.done,
                  enabled: !widget.state.isProcessing,
                  maxLength: 500,
                ),
              ),
              if (_hasInteracted &&
                  _validateRemark(_remarkController.text) != null)
                _ErrorAnimation(
                  errorText: _validateRemark(_remarkController.text)!,
                  color: theme.colorScheme.error,
                ),

              if (widget.state.error != null) ...[
                const SizedBox(height: AppSizes.m),
                _ErrorAnimation(
                  errorText: widget.state.error!,
                  color: theme.colorScheme.error,
                ),
              ],

              // Keyboard shortcuts help
              const SizedBox(height: AppSizes.l),
              Text(
                '键盘快捷键:',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSizes.s),
              Text(
                'Ctrl+T: 标题  Ctrl+A: 作者  Ctrl+R: 备注\n'
                'Enter: 确认  Tab: 下一项  Shift+Tab: 上一项',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(WorkImportForm oldWidget) {
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
    _updateControllers();
    _setupKeyboardListeners();
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
      widget.viewModel.setCreationDate(date);
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
      case LogicalKeyboardKey.enter:
        _handleSubmit();
        break;
      default:
        break;
    }
  }

  void _handleStyleChange(String? value) {
    if (value != null && !widget.state.isProcessing) {
      widget.viewModel.setStyle(value);
      FocusScope.of(context).nextFocus();
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _hasInteracted = true);

    if (_formKey.currentState?.validate() ?? false) {
      try {
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '重试',
              onPressed: _handleSubmit,
              textColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        );
      }
    }
  }

  void _handleToolChange(String? value) {
    if (value != null && !widget.state.isProcessing) {
      widget.viewModel.setTool(value);
      FocusScope.of(context).nextFocus();
    }
  }

  void _setupKeyboardListeners() {
    _titleFocus.addListener(_handleFocusChange);
    _authorFocus.addListener(_handleFocusChange);
    _remarkFocus.addListener(_handleFocusChange);
  }

  void _updateControllers() {
    final newText = widget.state.title;
    if (_titleController.text != newText) {
      _titleController.value = TextEditingValue(
        text: newText,
        // 如果选择范围超出新文本长度，则将其设为文本末尾
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    final newAuthor = widget.state.author ?? '';
    if (_authorController.text != newAuthor) {
      _authorController.value = TextEditingValue(
        text: newAuthor,
        selection: TextSelection.collapsed(offset: newAuthor.length),
      );
    }

    final newRemark = widget.state.remark ?? '';
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

    if (value == null || value.trim().isEmpty) {
      return '请输入作品标题';
    }
    if (value.trim().length < 2) {
      return '标题至少需要2个字符';
    }
    if (value.trim().length > 100) {
      return '标题不能超过100个字符';
    }
    return null;
  }
}
