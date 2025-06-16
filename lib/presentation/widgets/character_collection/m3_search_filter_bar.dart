import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../viewmodels/states/character_grid_state.dart';

class M3SearchFilterBar extends StatelessWidget {
  final String searchTerm;
  final FilterType filterType;
  final Function(String) onSearchChanged;
  final Function(FilterType) onFilterChanged;

  const M3SearchFilterBar({
    super.key,
    required this.searchTerm,
    required this.filterType,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          // Search input field
          Expanded(
            flex: 1,
            child: SearchBar(
              controller: TextEditingController(text: searchTerm)
                ..selection =
                    TextSelection.collapsed(offset: searchTerm.length),
              hintText: l10n.characterCollectionSearchHint,
              leading: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
              onChanged: onSearchChanged,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8.0),
              ),
              trailing: [
                if (searchTerm.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => onSearchChanged(''),
                    tooltip: '',
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Filter dropdown menu
          Expanded(
            flex: 2,
            child: SegmentedButton<FilterType>(
              segments: [
                ButtonSegment<FilterType>(
                  value: FilterType.all,
                  label: Text(l10n.all),
                ),
                ButtonSegment<FilterType>(
                  value: FilterType.recent,
                  label: Text(l10n.recent),
                ),
                ButtonSegment<FilterType>(
                  value: FilterType.favorite,
                  label: Text(l10n.favorite),
                ),
              ],
              selected: {filterType},
              onSelectionChanged: (Set<FilterType> selected) {
                if (selected.isNotEmpty) {
                  onFilterChanged(selected.first);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
