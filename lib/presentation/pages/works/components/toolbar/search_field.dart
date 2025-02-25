import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_sizes.dart';

class SearchField extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.watch(workBrowseProvider);

    return SizedBox(
      width: 240,
      child: TextField(
        controller: state.searchController,
        decoration: InputDecoration(
          hintText: '搜索作品...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: state.searchQuery?.isNotEmpty ?? false
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    state.searchController.clear();
                    viewModel.setSearchQuery('');
                  },
                )
              : null,
        ),
        onChanged: viewModel.setSearchQuery,
      ),
    );
  }
}
