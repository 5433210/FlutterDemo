import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../providers/settings/grid_size_provider.dart';

/// A widget that allows users to select the grid item size
class GridSizeSelector extends ConsumerWidget {
  /// Constructor
  const GridSizeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(gridSizeProvider);
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<GridSizeOption>(
      tooltip: l10n.adjustGridSize,
      initialValue: currentSize,
      icon: const Icon(Icons.grid_view),
      onSelected: (GridSizeOption size) {
        ref.read(gridSizeProvider.notifier).state = size;
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<GridSizeOption>>[
        PopupMenuItem<GridSizeOption>(
          value: GridSizeOption.small,
          child: Text(l10n.gridSizeSmall),
        ),
        PopupMenuItem<GridSizeOption>(
          value: GridSizeOption.medium,
          child: Text(l10n.gridSizeMedium),
        ),
        PopupMenuItem<GridSizeOption>(
          value: GridSizeOption.large,
          child: Text(l10n.gridSizeLarge),
        ),
        PopupMenuItem<GridSizeOption>(
          value: GridSizeOption.extraLarge,
          child: Text(l10n.gridSizeExtraLarge),
        ),
      ],
    );
  }
}
