import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/work_import_provider.dart';
import 'components/form/work_import_form.dart';
import 'components/preview/work_import_preview.dart';

/// Dialog for importing works with preview and metadata input
class WorkImportDialog extends ConsumerWidget {
  const WorkImportDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workImportProvider);
    final viewModel = ref.read(workImportProvider.notifier);

    return Dialog.fullscreen(
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
              maxHeight: 800,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('导入作品'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        viewModel.reset();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview section
                        const Expanded(
                          flex: 3,
                          child: WorkImportPreview(),
                        ),

                        const SizedBox(width: 24),

                        // Form section
                        Expanded(
                          flex: 2,
                          child: WorkImportForm(
                            state: state,
                            viewModel: viewModel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show the work import dialog
  static Future<bool?> show(BuildContext context) {
    // 确保在打开对话框前重置状态
    ProviderScope.containerOf(context)
        .read(workImportProvider.notifier)
        .reset();

    return showDialog<bool>(
      context: context,
      builder: (context) => const WorkImportDialog(),
    );
  }
}
