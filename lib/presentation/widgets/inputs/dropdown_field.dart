import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DropdownField<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isRequired;
  final String? Function(T?)? validator;
  final String? hintText;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final bool enabled;

  const DropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
    this.validator,
    this.hintText,
    this.textInputAction,
    this.onEditingComplete,
    this.enabled = true,
  });

  @override
  State<DropdownField<T>> createState() => _DropdownFieldState<T>();
}

class _DropdownFieldState<T> extends State<DropdownField<T>> {
  final _focusNode = FocusNode();
  bool _hasFocus = false;
  bool _isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.enabled && widget.onChanged != null;

    return FormField<T>(
      initialValue: widget.value,
      validator:
          widget.validator ?? (widget.isRequired ? _requiredValidator : null),
      builder: (FormFieldState<T> field) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: field.errorText,
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.outline,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
              ),
              suffixIcon: Icon(
                Icons.arrow_drop_down,
                color:
                    _hasFocus && isEnabled ? theme.colorScheme.primary : null,
              ),
              filled: _hasFocus && isEnabled,
              fillColor: _hasFocus && isEnabled
                  ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                  : null,
              enabled: isEnabled,
            ),
            isEmpty: widget.value == null,
            isFocused: _hasFocus,
            child: Focus(
              focusNode: _focusNode,
              onKeyEvent: isEnabled ? _handleKeyEvent : null,
              child: GestureDetector(
                onTap: isEnabled ? _showDropdown : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _buildText(theme, isEnabled),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(DropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateSelectedIndex();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isDropdownOpen = false;
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _updateSelectedIndex();
  }

  Widget _buildText(ThemeData theme, bool isEnabled) {
    if (widget.value != null) {
      final selectedItem = widget.items.firstWhere(
        (item) => item.value == widget.value,
        orElse: () => widget.items.first,
      );
      return DefaultTextStyle(
        style: theme.textTheme.bodyMedium!.copyWith(
          color: isEnabled ? null : theme.disabledColor,
        ),
        child: selectedItem.child,
      );
    }
    return Text(
      widget.hintText ?? '',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.hintColor,
      ),
    );
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
        if (!_hasFocus) {
          _hideDropdown();
        }
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (!_isDropdownOpen) {
        _showDropdown();
      } else {
        _selectNextItem();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp && _isDropdownOpen) {
      _selectPreviousItem();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      if (_isDropdownOpen && _selectedIndex >= 0) {
        _selectCurrentItem();
      } else {
        _showDropdown();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape && _isDropdownOpen) {
      _hideDropdown();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _hideDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) {
        setState(() => _isDropdownOpen = false);
      }
    }
  }

  String? _requiredValidator(T? value) {
    if (widget.isRequired && value == null) {
      return '请选择${widget.label}';
    }
    return null;
  }

  void _selectCurrentItem() {
    if (_selectedIndex >= 0 && _selectedIndex < widget.items.length) {
      final selectedItem = widget.items[_selectedIndex];
      widget.onChanged!(selectedItem.value);
      _hideDropdown();
      if (widget.onEditingComplete != null) {
        widget.onEditingComplete!();
      }
    }
  }

  void _selectNextItem() {
    if (_selectedIndex < widget.items.length - 1) {
      setState(() {
        _selectedIndex++;
        _updateOverlay();
      });
    }
  }

  void _selectPreviousItem() {
    if (_selectedIndex > 0) {
      setState(() {
        _selectedIndex--;
        _updateOverlay();
      });
    }
  }

  void _showDropdown() {
    if (!widget.enabled || widget.onChanged == null) return;

    if (_isDropdownOpen) {
      _hideDropdown();
      return;
    }

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 5.0),
            child: Material(
              elevation: 4.0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == _selectedIndex;

                    return InkWell(
                      onTap: () {
                        widget.onChanged!(item.value);
                        _hideDropdown();
                        if (widget.onEditingComplete != null) {
                          widget.onEditingComplete!();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: DefaultTextStyle(
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : null,
                                  ),
                          child: item.child,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );

    setState(() => _isDropdownOpen = true);
    overlay.insert(_overlayEntry!);
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _updateSelectedIndex() {
    if (widget.value != null) {
      _selectedIndex =
          widget.items.indexWhere((item) => item.value == widget.value);
    }
  }
}
