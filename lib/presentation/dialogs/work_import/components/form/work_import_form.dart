import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../viewmodels/states/work_import_state.dart';
import '../../../../viewmodels/work_import_view_model.dart';
import '../../../../widgets/forms/work_form.dart';

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

class _WorkImportFormState extends State<WorkImportForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isProcessing = widget.state.isProcessing;

    return Focus(
      onKeyEvent: (_, event) {
        _handleKeyPress(event);
        return KeyEventResult.ignored;
      },
      child: WorkForm(
        formKey: _formKey,
        initialTitle: widget.state.title,
        initialAuthor: widget.state.author,
        initialStyle: widget.state.style,
        initialTool: widget.state.tool,
        initialRemark: widget.state.remark,
        isProcessing: isProcessing,
        error: widget.state.error,
        onTitleChanged: widget.viewModel.setTitle,
        onAuthorChanged: widget.viewModel.setAuthor,
        onStyleChanged: widget.viewModel.setStyle,
        onToolChanged: widget.viewModel.setTool,
        onRemarkChanged: widget.viewModel.setRemark,
        requiredFields: const {WorkFormField.title},
        visibleFields: WorkFormPresets.importFields,
        showHelp: true,
        showKeyboardShortcuts: true,
      ),
    );
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (!HardwareKeyboard.instance.isControlPressed) return;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _handleSubmit();
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.submitFailed(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: l10n.retry,
              onPressed: _handleSubmit,
              textColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        );
      }
    }
  }
}
