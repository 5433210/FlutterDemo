import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Material 3 Character input field for collection content
class M3CharacterInputField extends StatefulWidget {
  final String initialText;
  final int selectedCharIndex;
  final Function(String) onTextChanged;
  final Function(int) onSelectedCharIndexChanged;

  const M3CharacterInputField({
    Key? key,
    required this.initialText,
    required this.selectedCharIndex,
    required this.onTextChanged,
    required this.onSelectedCharIndexChanged,
  }) : super(key: key);

  @override
  State<M3CharacterInputField> createState() => _M3CharacterInputFieldState();
}

class _M3CharacterInputFieldState extends State<M3CharacterInputField> {
  late TextEditingController _textController;
  Timer? _debounceTimer;
  String _lastInputText = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        hintText: l10n.inputHint,
        hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        // 添加字符计数器
        counterText: '${_textController.text.length}/800',
        counterStyle: TextStyle(
          color: _textController.text.length > 800 
              ? colorScheme.error 
              : colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      style: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      keyboardType: TextInputType.multiline,
      maxLines: 5,
      minLines: 3,
      maxLength: 800, // 设置最大字符数为800
      onChanged: (value) {
        // 确保文本不超过800字符限制
        String trimmedValue = value;
        if (value.length > 800) {
          trimmedValue = value.substring(0, 800);
          // 如果文本被截断，更新控制器
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_textController.text.length > 800) {
              _textController.value = _textController.value.copyWith(
                text: trimmedValue,
                selection: TextSelection.collapsed(offset: trimmedValue.length),
              );
            }
          });
        }
        
        // 立即更新UI以显示字符计数器
        setState(() {});
        
        // Get current content and new content
        final oldCharacters = _lastInputText;

        // Immediately update character content for UI responsiveness
        widget.onTextChanged(trimmedValue);

        // Record the last input text
        _lastInputText = trimmedValue;

        // Logic to select newly added characters
        if (trimmedValue.length > oldCharacters.length && oldCharacters.isNotEmpty) {
          // Find the position of the newly added character
          int newCharIndex = -1;

          // If characters were added at the end
          if (trimmedValue.startsWith(oldCharacters)) {
            newCharIndex = oldCharacters.length;
          }
          // If characters were added in the middle or beginning
          else {
            // Simple algorithm to find the new character position
            for (int i = 0; i < trimmedValue.length; i++) {
              if (i >= oldCharacters.length || trimmedValue[i] != oldCharacters[i]) {
                newCharIndex = i;
                break;
              }
            }
          }

          // Select the new character if found
          if (newCharIndex >= 0 && newCharIndex < trimmedValue.length) {
            widget.onSelectedCharIndexChanged(newCharIndex);
          } else {
            // If we can't determine the new position, select the last character
            widget.onSelectedCharIndexChanged(trimmedValue.length - 1);
          }
        }
        // If characters were deleted or content was cleared
        else if (trimmedValue.length < oldCharacters.length) {
          widget.onSelectedCharIndexChanged(trimmedValue.isEmpty
              ? 0
              : math.min(widget.selectedCharIndex, trimmedValue.length - 1));
        }
        // If this is the first input
        else if (oldCharacters.isEmpty && trimmedValue.isNotEmpty) {
          widget.onSelectedCharIndexChanged(0);
        }

        // Debounce to process final input
        if (_debounceTimer?.isActive ?? false) {
          _debounceTimer!.cancel();
        }

        // Delay processing by 300ms
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          // Use the most recent input (确保也限制在800字符内)
          String textToProcess = _lastInputText;
          if (textToProcess.length > 800) {
            textToProcess = textToProcess.substring(0, 800);
            _lastInputText = textToProcess;
          }

          // Update text to trigger any operations like loading candidate characters
          widget.onTextChanged(textToProcess);
        });
      },
    );
  }

  @override
  void didUpdateWidget(M3CharacterInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller text when it actually changes to avoid cursor position reset
    String newText = widget.initialText;
    
    // 确保外部设置的文本也不超过800字符
    if (newText.length > 800) {
      newText = newText.substring(0, 800);
      // 通知父组件文本已被截断
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTextChanged(newText);
      });
    }
    
    if (_textController.text != newText) {
      _textController.text = newText;
      _lastInputText = newText;
      // 更新UI以显示字符计数器
      setState(() {});
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 确保初始文本不超过800字符
    String initialText = widget.initialText;
    if (initialText.length > 800) {
      initialText = initialText.substring(0, 800);
      // 如果初始文本被截断，通知父组件
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTextChanged(initialText);
      });
    }
    
    _textController = TextEditingController(text: initialText);
    _lastInputText = initialText;
  }
}
