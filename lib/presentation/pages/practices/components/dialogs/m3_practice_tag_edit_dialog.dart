import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../widgets/tag_editor.dart';

/// Practice tag edit dialog
class M3PracticeTagEditDialog extends StatefulWidget {
  /// Current tags
  final List<String> tags;

  /// Suggested tags
  final List<String> suggestedTags;

  /// Callback when tags are saved
  final Function(List<String>) onSaved;

  const M3PracticeTagEditDialog({
    super.key,
    required this.tags,
    required this.suggestedTags,
    required this.onSaved,
  });

  @override
  State<M3PracticeTagEditDialog> createState() =>
      _M3PracticeTagEditDialogState();
}

class _M3PracticeTagEditDialogState extends State<M3PracticeTagEditDialog> {
  List<String> _currentTags = [];
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.edit),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TagEditor(
              tags: _currentTags,
              suggestedTags: widget.suggestedTags,
              onTagsChanged: (tags) {
                setState(() {
                  _currentTags = tags;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            widget.onSaved(_currentTags);
          },
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _currentTags = List.from(widget.tags);
  }
}
