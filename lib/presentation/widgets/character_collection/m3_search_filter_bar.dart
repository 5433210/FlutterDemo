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
              constraints: const BoxConstraints(maxWidth: 10, minWidth: 5),
              controller: TextEditingController(text: searchTerm),
              hintText: l10n.characterCollectionSearchHint,
              leading: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
              onChanged: onSearchChanged,
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
                  label: Text(l10n.characterCollectionFilterAll),
                ),
                ButtonSegment<FilterType>(
                  value: FilterType.recent,
                  label: Text(l10n.characterCollectionFilterRecent),
                ),
                ButtonSegment<FilterType>(
                  value: FilterType.favorite,
                  label: Text(l10n.characterCollectionFilterFavorite),
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

  DropdownMenuItem<FilterType> _buildDropdownItem(
      FilterType value, String text, BuildContext context) {
    return DropdownMenuItem<FilterType>(
      value: value,
      child: Text(text),
    );
  }
}
