import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/config/config_item.dart';
import '../../../domain/services/config_service.dart';
import '../../../infrastructure/providers/config_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/config/config_item_editor.dart';

/// 配置管理页面
class ConfigManagementPage extends ConsumerStatefulWidget {
  final String? category;
  final String? title;

  const ConfigManagementPage({
    super.key,
    this.category,
    this.title,
  });

  @override
  ConsumerState<ConfigManagementPage> createState() =>
      _ConfigManagementPageState();
}

class _ConfigManagementPageState extends ConsumerState<ConfigManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // 如果指定了分类，只显示单个页面；否则显示选项卡
    if (widget.category == null) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    if (widget.category == null) {
      _tabController.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.category != null) {
      // 单个分类页面
      return _buildSingleCategoryPage(
          widget.category!, widget.title ?? l10n.configManagement);
    } else {
      // 多选项卡页面
      return _buildMultiCategoryPage();
    }
  }

  Widget _buildSingleCategoryPage(String category, String title) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchDialog(),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, category),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'add',
                    child: ListTile(
                      leading: const Icon(Icons.add),
                      title: Text(l10n.addConfigItem),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reset',
                    child: ListTile(
                      leading: const Icon(Icons.refresh),
                      title: Text(l10n.resetToDefault),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: const Icon(Icons.download),
                      title: Text(l10n.exportConfig),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'import',
                    child: ListTile(
                      leading: const Icon(Icons.upload),
                      title: Text(l10n.importConfig),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _buildConfigList(category),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddItemDialog(category),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildMultiCategoryPage() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.configManagement),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                    text: l10n.calligraphyStyle,
                    icon: const Icon(Icons.brush_outlined)),
                Tab(
                    text: l10n.writingTool,
                    icon: const Icon(Icons.edit_outlined)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchDialog(),
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildConfigList(ConfigCategories.style),
              _buildConfigList(ConfigCategories.tool),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfigList(String category) {
    final notifierProvider = category == ConfigCategories.style
        ? styleConfigNotifierProvider
        : toolConfigNotifierProvider;

    return Consumer(
      builder: (context, ref, child) {
        final configState = ref.watch(notifierProvider);

        return configState.when(
          data: (config) => config != null
              ? _buildConfigItemList(config, category)
              : _buildEmptyState(category),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error, category),
        );
      },
    );
  }

  Widget _buildConfigItemList(ConfigCategory config, String category) {
    var items = config.items;

    // 应用搜索过滤
    if (_searchQuery.isNotEmpty) {
      items = items
          .where((item) =>
              item.displayName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              item.key.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (items.isEmpty && _searchQuery.isNotEmpty) {
      return _buildSearchEmptyState();
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) =>
          _reorderItems(category, oldIndex, newIndex, items),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildConfigItemTile(item, category, index);
      },
    );
  }

  Widget _buildConfigItemTile(ConfigItem item, String category, int index) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Card(
          key: ValueKey(item.key),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_handle),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: item.isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isActive
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              item.displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: item.isActive
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l10n.configKey}: ${item.key}'),
                if (item.isSystem)
                  Chip(
                    label: Text(l10n.systemConfig),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: item.isActive,
                  onChanged: (value) => _toggleItemActive(category, item.key),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleItemAction(value, category, item),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: const Icon(Icons.edit),
                        title: Text(l10n.edit),
                      ),
                    ),
                    if (!item.isSystem)
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: Text(l10n.delete),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            onTap: () => _showItemDetails(item),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String category) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final categoryName = category == ConfigCategories.style
            ? l10n.calligraphyStyle
            : l10n.writingTool;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category == ConfigCategories.style
                    ? Icons.brush_outlined
                    : Icons.edit_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noConfigItems(categoryName),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.addConfigItemHint(categoryName),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showAddItemDialog(category),
                icon: const Icon(Icons.add),
                label: Text(l10n.addCategoryItem(categoryName)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchEmptyState() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noMatchingConfigItems,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tryOtherKeywords,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(Object error, String category) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.loadConfigFailed,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _retryLoading(category),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSearchDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.searchConfigDialogTitle),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.searchConfigHint,
            prefixIcon: const Icon(Icons.search),
          ),
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.of(context).pop();
            },
            child: Text(l10n.filterClear),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => ConfigItemEditor(
        category: category,
        onSave: (item) => _addItem(category, item),
      ),
    );
  }

  void _showEditItemDialog(String category, ConfigItem item) {
    showDialog(
      context: context,
      builder: (context) => ConfigItemEditor(
        category: category,
        item: item,
        onSave: (updatedItem) => _updateItem(category, updatedItem),
      ),
    );
  }

  void _showItemDetails(ConfigItem item) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(l10n.key, item.key),
            _buildDetailRow(l10n.displayName, item.displayName),
            _buildDetailRow(l10n.sortOrder, item.sortOrder.toString()),
            _buildDetailRow(
                l10n.status, item.isActive ? l10n.activated : l10n.disabled),
            _buildDetailRow(
                l10n.type, item.isSystem ? l10n.systemConfig : l10n.userConfig),
            if (item.createTime != null)
              _buildDetailRow(
                  l10n.createTime, _formatDateTime(item.createTime!)),
            if (item.updateTime != null)
              _buildDetailRow(
                  l10n.updateTime, _formatDateTime(item.updateTime!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleMenuAction(String action, String category) async {
    final notifier = ref.read(
      category == ConfigCategories.style
          ? styleConfigNotifierProvider.notifier
          : toolConfigNotifierProvider.notifier,
    );

    switch (action) {
      case 'add':
        _showAddItemDialog(category);
        break;
      case 'reset':
        _confirmReset(category, notifier);
        break;
      case 'export':
        _exportConfig(category, notifier);
        break;
      case 'import':
        _importConfig(category, notifier);
        break;
    }
  }

  Future<void> _handleItemAction(
      String action, String category, ConfigItem item) async {
    final notifier = ref.read(
      category == ConfigCategories.style
          ? styleConfigNotifierProvider.notifier
          : toolConfigNotifierProvider.notifier,
    );

    switch (action) {
      case 'edit':
        _showEditItemDialog(category, item);
        break;
      case 'delete':
        _confirmDelete(category, item.key, notifier);
        break;
    }
  }

  Future<void> _addItem(String category, ConfigItem item) async {
    final notifier = ref.read(
      category == ConfigCategories.style
          ? styleConfigNotifierProvider.notifier
          : toolConfigNotifierProvider.notifier,
    );

    await notifier.addItem(item);

    // 刷新所有相关的配置provider
    refreshConfigs(ref);
  }

  Future<void> _updateItem(String category, ConfigItem item) async {
    final notifier = ref.read(
      category == ConfigCategories.style
          ? styleConfigNotifierProvider.notifier
          : toolConfigNotifierProvider.notifier,
    );

    await notifier.updateItem(item);

    // 刷新所有相关的配置provider
    refreshConfigs(ref);
  }

  Future<void> _toggleItemActive(String category, String itemKey) async {
    final notifier = ref.read(
      category == ConfigCategories.style
          ? styleConfigNotifierProvider.notifier
          : toolConfigNotifierProvider.notifier,
    );

    await notifier.toggleItemActive(itemKey);

    // 刷新所有相关的配置provider
    refreshConfigs(ref);
  }

  Future<void> _reorderItems(String category, int oldIndex, int newIndex,
      List<ConfigItem> items) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reorderedItems = List<ConfigItem>.from(items);
    final item = reorderedItems.removeAt(oldIndex);
    reorderedItems.insert(newIndex, item);

    final keyOrder = reorderedItems.map((item) => item.key).toList();

    final notifier = ref.read(
      category == ConfigCategories.style
          ? styleConfigNotifierProvider.notifier
          : toolConfigNotifierProvider.notifier,
    );

    await notifier.reorderItems(keyOrder);

    // 刷新所有相关的配置provider
    refreshConfigs(ref);
  }

  void _confirmReset(String category, ConfigNotifier notifier) {
    final l10n = AppLocalizations.of(context);
    final categoryName = category == ConfigCategories.style
        ? l10n.calligraphyStyleText
        : l10n.writingToolText;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetCategoryConfig(categoryName)),
        content: Text(l10n.resetCategoryConfigMessage(categoryName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await notifier.resetToDefault();
              // 刷新所有相关的配置provider
              refreshConfigs(ref);
            },
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      String category, String itemKey, ConfigNotifier notifier) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfigItem),
        content: Text(l10n.deleteConfigItemMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await notifier.deleteItem(itemKey);
              // 刷新所有相关的配置provider
              refreshConfigs(ref);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteText),
          ),
        ],
      ),
    );
  }

  Future<void> _exportConfig(String category, ConfigNotifier notifier) async {
    final l10n = AppLocalizations.of(context);
    final config = await notifier.exportConfig();
    if (config != null && mounted) {
      // TODO: 实现配置导出功能（文件保存）
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportNotImplemented)),
      );
    }
  }

  Future<void> _importConfig(String category, ConfigNotifier notifier) async {
    final l10n = AppLocalizations.of(context);
    // TODO: 实现配置导入功能（文件选择）
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importNotImplemented)),
      );
    }
  }

  void _retryLoading(String category) {
    final notifierProvider = category == ConfigCategories.style
        ? styleConfigNotifierProvider
        : toolConfigNotifierProvider;

    ref.read(notifierProvider.notifier).reload();
  }
}
