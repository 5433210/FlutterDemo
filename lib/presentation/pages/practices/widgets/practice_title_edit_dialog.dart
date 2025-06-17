import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';

/// Dialog for editing practice title
class PracticeTitleEditDialog extends StatefulWidget {
  final String? initialTitle;
  final Future<bool> Function(String) checkTitleExists;

  const PracticeTitleEditDialog({
    Key? key,
    required this.initialTitle,
    required this.checkTitleExists,
  }) : super(key: key);

  @override
  State<PracticeTitleEditDialog> createState() =>
      _PracticeTitleEditDialogState();
}

class _PracticeTitleEditDialogState extends State<PracticeTitleEditDialog> {
  late TextEditingController _controller;
  String? _errorText;
  bool _isChecking = false;
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _validateAndSubmit(_controller.text);
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        }
      },
      child: AlertDialog(
        title: Text(
            '${AppLocalizations.of(context).edit} ${AppLocalizations.of(context).title}'),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).title,
            errorText: _errorText,
            enabled: !_isChecking,
          ),
          autofocus: true,
          onSubmitted: _validateAndSubmit,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed:
                _isChecking ? null : () => _validateAndSubmit(_controller.text),
            child: _isChecking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context).save),
          ),
        ],
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
    _controller = TextEditingController(text: widget.initialTitle);
  }

  Future<void> _validateAndSubmit(String value) async {
    if (value.isEmpty) {
      setState(() {
        _errorText = AppLocalizations.of(context).titleCannotBeEmpty;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    // Check if title already exists
    if (value != widget.initialTitle) {
      final exists = await widget.checkTitleExists(value);
      if (exists) {
        setState(() {
          _errorText = AppLocalizations.of(context).titleExists;
          _isChecking = false;
        });
        return;
      }
    }

    setState(() {
      _isChecking = false;
    });

    if (mounted) {
      Navigator.of(context).pop(value);
    }
  }
}
