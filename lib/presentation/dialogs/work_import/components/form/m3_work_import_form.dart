import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../viewmodels/states/work_import_state.dart';
import '../../../../viewmodels/work_import_view_model.dart';
import '../../../../widgets/forms/m3_work_form.dart';

/// Material 3 version of the form for entering work metadata during import
class M3WorkImportForm extends StatefulWidget {
  final WorkImportState state;
  final WorkImportViewModel viewModel;

  const M3WorkImportForm({
    super.key,
    required this.state,
    required this.viewModel,
  });

  @override
  State<M3WorkImportForm> createState() => _M3WorkImportFormState();
}

class _M3WorkImportFormState extends State<M3WorkImportForm> {
  final _formKey = GlobalKey<FormState>();
  bool _hasInteracted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isProcessing = widget.state.isProcessing;

    return Focus(
      onKeyEvent: (_, event) {
        _handleKeyPress(event);
        return KeyEventResult.ignored;
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: M3WorkForm(
            formKey: _formKey,
            initialTitle: widget.state.title,
            initialAuthor: widget.state.author,
            initialStyle: widget.state.style,
            initialTool: widget.state.tool,
            initialCreationDate: widget.state.creationDate,
            initialRemark: widget.state.remark,
            isProcessing: isProcessing,
            error: widget.state.error,
            onTitleChanged: widget.viewModel.setTitle,
            onAuthorChanged: widget.viewModel.setAuthor,
            onStyleChanged: widget.viewModel.setStyle,
            onToolChanged: widget.viewModel.setTool,
            onCreationDateChanged: _handleDateChange,
            onRemarkChanged: widget.viewModel.setRemark,
            requiredFields: const {WorkFormField.title},
            visibleFields: WorkFormPresets.importFields,
            showHelp: true,
            showKeyboardShortcuts: true,
          ),
        ),
      ),
    );
  }

  void _handleDateChange(DateTime? date) {
    final l10n = AppLocalizations.of(context);
    if (date != null) {
      if (date.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.workFormCreationDate),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      widget.viewModel.setCreationDate(date);
    }
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (!HardwareKeyboard.instance.isControlPressed) return;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _handleSubmit();
    }
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _hasInteracted = true);

    if (_formKey.currentState?.validate() ?? false) {
      try {
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.workImportDialogError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: l10n.workBrowseReload,
              onPressed: _handleSubmit,
              textColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        );
      }
    }
  }
}
