import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/work_browse_provider.dart';

class SearchField extends ConsumerWidget {
  const SearchField({super.key});

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
          // 改进清空按钮逻辑
          suffixIcon: state.searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    state.searchController.clear();
                    viewModel.setSearchQuery('');
                    viewModel.loadWorks(); // 清空后重新加载
                  },
                )
              : null,
        ),
        // 使用 ViewModel 中的防抖方法
        onChanged: viewModel.setSearchQuery,
      ),
    );
  }
}
