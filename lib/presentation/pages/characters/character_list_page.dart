import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../../dialogs/character_edit_dialog.dart';
import '../../widgets/character/character_detail_view.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/page_toolbar.dart';
import '../../widgets/search/search_box.dart';
import '../../widgets/section_header.dart';

class CharacterListPage extends StatefulWidget {
  const CharacterListPage({super.key});

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  String? _selectedCharId;
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      navigationInfo: const Text('集字列表'),
      toolbar: PageToolbar(
        leading: [
          FilledButton.icon(
            onPressed: _showAddCharacterDialog,
            icon: const Icon(Icons.add),
            label: const Text('新建字符'),
          ),
        ],
        trailing: [
          SearchBox(
            controller: _searchController,
            hintText: '搜索字符...',
            onSubmitted: _handleSearch,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: '所有字符',
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.spacingMedium,
                    AppSizes.spacingMedium,
                    AppSizes.spacingMedium,
                    0,
                  ),
                ),
                Expanded(
                  child: _buildCharacterGrid(),
                ),
              ],
            ),
          ),
          if (_selectedCharId != null) ...[
            const VerticalDivider(width: 1),
            Expanded(
              child: CharacterDetailView(charId: _selectedCharId!),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildCharacterGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: AppSizes.spacingMedium,
        crossAxisSpacing: AppSizes.spacingMedium,
        childAspectRatio: 1,
      ),
      itemCount: 20,
      itemBuilder: _buildCharacterItem,
    );
  }

  Widget _buildCharacterItem(BuildContext context, int index) {
    final theme = Theme.of(context);
    final charId = 'char_$index';
    final isSelected = charId == _selectedCharId;

    return Card(
      elevation:
          isSelected ? AppSizes.cardElevationSelected : AppSizes.cardElevation,
      color: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => setState(() => _selectedCharId = charId),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  '字$index',
                  style: theme.textTheme.headlineLarge,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacingSmall),
              child: Text(
                '来自：作品X',
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearch() {
    // 实现搜索逻辑
  }

  void _showAddCharacterDialog() {
    showDialog(
      context: context,
      builder: (context) => const CharacterEditDialog(
        charId: '',
      ),
    );
  }
}
