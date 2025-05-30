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
        hintText: l10n.characterEditInputHint,
        hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      style: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      keyboardType: TextInputType.multiline,
      maxLines: 5,
      minLines: 3,
      onChanged: (value) {
        // Get current content and new content
        final oldCharacters = _lastInputText;

        // Immediately update character content for UI responsiveness
        widget.onTextChanged(value);

        // Record the last input text
        _lastInputText = value;

        // Logic to select newly added characters
        if (value.length > oldCharacters.length && oldCharacters.isNotEmpty) {
          // Find the position of the newly added character
          int newCharIndex = -1;

          // If characters were added at the end
          if (value.startsWith(oldCharacters)) {
            newCharIndex = oldCharacters.length;
          }
          // If characters were added in the middle or beginning
          else {
            // Simple algorithm to find the new character position
            for (int i = 0; i < value.length; i++) {
              if (i >= oldCharacters.length || value[i] != oldCharacters[i]) {
                newCharIndex = i;
                break;
              }
            }
          }

          // Select the new character if found
          if (newCharIndex >= 0 && newCharIndex < value.length) {
            widget.onSelectedCharIndexChanged(newCharIndex);
          } else {
            // If we can't determine the new position, select the last character
            widget.onSelectedCharIndexChanged(value.length - 1);
          }
        }
        // If characters were deleted or content was cleared
        else if (value.length < oldCharacters.length) {
          widget.onSelectedCharIndexChanged(value.isEmpty
              ? 0
              : math.min(widget.selectedCharIndex, value.length - 1));
        }
        // If this is the first input
        else if (oldCharacters.isEmpty && value.isNotEmpty) {
          widget.onSelectedCharIndexChanged(0);
        }

        // Debounce to process final input
        if (_debounceTimer?.isActive ?? false) {
          _debounceTimer!.cancel();
        }

        // Delay processing by 300ms
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          // Use the most recent input
          final textToProcess = _lastInputText;

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
    if (_textController.text != widget.initialText) {
      _textController.text = widget.initialText;
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
    _textController = TextEditingController(text: widget.initialText);
    _lastInputText = widget.initialText;
  }
}
