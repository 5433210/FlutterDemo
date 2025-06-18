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

    debugPrint(
        '🔧 ConfigManagementPage initState: category=${widget.category}');

    // 如果指定了分类，只显示单个页面；否则显示选项卡
    if (widget.category == null) {
      _tabController = TabController(length: 2, vsync: this);
    }

    // 异步初始化配置数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConfigData();
    });
  }

  /// 初始化配置数据
  Future<void> _initializeConfigData() async {
    try {
      debugPrint('🔧 初始化配置数据...');

      // 确保配置初始化完成
      await ref.read(configInitializationProvider.future);

      debugPrint('✅ 配置数据初始化完成');
    } catch (e, stack) {
      debugPrint('❌ 配置数据初始化失败: $e');
      debugPrint('❌ 堆栈: $stack');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('配置数据初始化失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ ConfigManagementPage dispose');

    if (widget.category == null) {
      _tabController.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    try {
      if (widget.category != null) {
        // 单个分类页面
        return _buildSingleCategoryPage(
            widget.category!, widget.title ?? l10n.configManagement);
      } else {
        // 多选项卡页面
        return _buildMultiCategoryPage();
      }
    } catch (e, stack) {
      debugPrint('❌ ConfigManagementPage.build 发生错误: $e');
      debugPrint('❌ 堆栈: $stack');

      // 返回错误页面
      return Scaffold(
        appBar: AppBar(title: Text(l10n.configManagement)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('页面构建错误', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('$e', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
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
          data: (config) {
            // 增强的null检查和数据验证
            if (config == null) {
              debugPrint('⚠️ 配置数据为null: $category');
              return _buildEmptyState(category);
            }

            if (config.items.isEmpty) {
              debugPrint('⚠️ 配置项列表为空: $category');
              return _buildEmptyState(category);
            }

            // 检查数据完整性
            final invalidItems =
                config.items.where((item) => item.key.isEmpty).toList();
            if (invalidItems.isNotEmpty) {
              debugPrint('❌ 发现无效配置项: $category, 数量: ${invalidItems.length}');
              for (final item in invalidItems) {
                debugPrint(
                    '❌   - displayName: ${item.displayName}, key: "${item.key}"');
              }
              return _buildErrorState('配置数据不完整，存在无效的配置项', category);
            }

            debugPrint('✅ 配置数据有效: $category, 配置项数量: ${config.items.length}');
            return _buildConfigItemList(config, category);
          },
          loading: () {
            debugPrint('🔄 正在加载配置: $category');
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stack) {
            debugPrint('❌ 配置加载错误: $category');
            debugPrint('❌ 错误详情: $error');
            debugPrint('❌ 堆栈: $stack');
            return _buildErrorState(error, category);
          },
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

    // 确保所有items都有有效的key，并且进行null安全检查
    if (items.any((item) => item.key.isEmpty)) {
      debugPrint('❌ 发现配置项中有空的key，这可能会导致ReorderableListView错误');
      return _buildErrorState('配置数据不完整，存在无效的配置项', category);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        if (!mounted) return; // 添加mounted检查
        _reorderItems(category, oldIndex, newIndex, items);
      },
      itemBuilder: (context, index) {
        if (index >= items.length) {
          // 防止索引越界
          debugPrint(
              '❌ ReorderableListView itemBuilder 索引越界: $index >= ${items.length}');
          return Container(key: ValueKey('error_$index'));
        }

        final item = items[index];
        if (item.key.isEmpty) {
          // 防止空key导致的问题
          debugPrint('❌ 配置项 $index 的key为空: ${item.displayName}');
          return Container(key: ValueKey('empty_key_$index'));
        }

        // ReorderableListView要求每个item的最外层widget必须有key
        final uniqueKey = '${category}_${item.key}_$index';
        return Container(
          key: ValueKey(uniqueKey), // 最外层必须有key
          child: _buildConfigItemTile(item, category, index),
        );
      },
    );
  }

  Widget _buildConfigItemTile(ConfigItem item, String category, int index) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);

        return Card(
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
              item.displayName.isNotEmpty ? item.displayName : '未命名配置项',
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
                Text(
                    '${l10n.configKey}: ${item.key.isNotEmpty ? item.key : '无效key'}'),
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
                  onChanged: (value) {
                    if (mounted) {
                      _toggleItemActive(category, item.key);
                    }
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (mounted) {
                      _handleItemAction(value, category, item);
                    }
                  },
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
    try {
      debugPrint(
          '🔄 重新排序配置项: $category, $oldIndex -> $newIndex, 总数: ${items.length}');

      if (oldIndex < 0 ||
          oldIndex >= items.length ||
          newIndex < 0 ||
          newIndex > items.length) {
        debugPrint(
            '❌ 重新排序索引无效: oldIndex=$oldIndex, newIndex=$newIndex, length=${items.length}');
        return;
      }

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

      debugPrint('✅ 配置项重新排序完成');
    } catch (e, stack) {
      debugPrint('❌ 重新排序配置项失败: $e');
      debugPrint('❌ 堆栈: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('排序失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
