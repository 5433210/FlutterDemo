import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../domain/models/practice/practice_filter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_sizes.dart';
import '../../widgets/common/base_navigation_bar.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/pagination/m3_pagination_controls.dart';
import 'components/m3_practice_grid_view.dart';
import 'components/m3_practice_list_view.dart';

/// Material 3 practice list page
class M3PracticeListPage extends ConsumerStatefulWidget {
  const M3PracticeListPage({super.key});

  @override
  ConsumerState<M3PracticeListPage> createState() => _M3PracticeListPageState();
}

class _M3PracticeListPageState extends ConsumerState<M3PracticeListPage> {
  bool _isGridView = true;
  bool _isBatchMode = false;
  final Set<String> _selectedPractices = {};

  // List to store practices data
  List<Map<String, dynamic>> _practices = [];
  final List<Map<String, dynamic>> _filteredPractices = [];

  // Loading and error states
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Pagination
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalItems = 0;

  // Sorting
  String _sortField = 'updateTime';
  String _sortOrder = 'desc';

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Show error snackbar if needed
    if (_hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage)),
          );
          setState(() {
            _hasError = false;
          });
        }
      });
    }

    return PageLayout(
      toolbar: _buildToolbar(theme, l10n),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : (_isGridView
                    ? M3PracticeGridView(
                        practices: _filteredPractices,
                        isBatchMode: _isBatchMode,
                        selectedPractices: _selectedPractices,
                        onPracticeTap: _handlePracticeTap,
                        onPracticeLongPress: _handlePracticeLongPress,
                        isLoading: false,
                        errorMessage: null,
                      )
                    : M3PracticeListView(
                        practices: _filteredPractices,
                        isBatchMode: _isBatchMode,
                        selectedPractices: _selectedPractices,
                        onPracticeTap: _handlePracticeTap,
                        onPracticeLongPress: _handlePracticeLongPress,
                        isLoading: false,
                        errorMessage: null,
                      )),
          ),
          // Pagination controls
          if (!_isLoading)
            M3PaginationControls(
              currentPage: _currentPage,
              pageSize: _pageSize,
              totalItems: _totalItems,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
                _loadPractices();
              },
              onPageSizeChanged: (size) {
                setState(() {
                  _pageSize = size;
                  _currentPage =
                      1; // Reset to first page when changing page size
                });
                _loadPractices();
              },
              availablePageSizes: const [10, 20, 50, 100],
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPractices();
  }

  Widget _buildToolbar(ThemeData theme, AppLocalizations l10n) {
    return BaseNavigationBar(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      title: Row(
        children: [
          // 左侧按钮组
          FilledButton.icon(
            onPressed: () => _navigateToEditPage(),
            icon: const Icon(Icons.add),
            label: Text(l10n.practiceListNewPractice),
          ),
          const SizedBox(width: AppSizes.spacingMedium),
          // Batch mode button
          OutlinedButton.icon(
            icon: Icon(_isBatchMode ? Icons.close : Icons.checklist),
            label: Text(_isBatchMode
                ? l10n.practiceListBatchDone
                : l10n.practiceListBatchMode),
            onPressed: _toggleBatchMode,
          ),
          if (_isBatchMode) ...[
            const SizedBox(width: AppSizes.m),
            // 显示已选择数量
            Text(
              l10n.selectedCount(_selectedPractices.length),
              style: theme.textTheme.bodyMedium,
            ),
            // 使用FilledButton.tonalIcon显示删除按钮，无论是否有选中项目
            Padding(
              padding: const EdgeInsets.only(left: AppSizes.s),
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.delete),
                label: Text(l10n.practiceListDeleteSelected),
                onPressed: _selectedPractices.isNotEmpty
                    ? _confirmDeleteSelected
                    : null,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // 排序下拉菜单
        PopupMenuButton<String>(
          tooltip: 'Sort',
          icon: const Icon(Icons.sort),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'updateTime',
              child: Row(
                children: [
                  Icon(
                    _sortOrder == 'desc'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    size: 18,
                    color: _sortField == 'updateTime'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.practiceListSortByUpdateTime),
                  if (_sortField == 'updateTime')
                    Icon(
                      Icons.check,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'createTime',
              child: Row(
                children: [
                  Icon(
                    _sortOrder == 'desc'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    size: 18,
                    color: _sortField == 'createTime'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.practiceListSortByCreateTime),
                  if (_sortField == 'createTime')
                    Icon(
                      Icons.check,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'title',
              child: Row(
                children: [
                  Icon(
                    _sortOrder == 'desc'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    size: 18,
                    color: _sortField == 'title'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.practiceListSortByTitle),
                  if (_sortField == 'title')
                    Icon(
                      Icons.check,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            setState(() {
              if (_sortField == value) {
                _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
              } else {
                _sortField = value;
                _sortOrder = 'desc';
              }
            });
            _loadPractices();
          },
        ),
        const SizedBox(width: AppSizes.spacingMedium),

        // 搜索框
        SizedBox(
          width: 240,
          child: SearchBar(
            controller: _searchController,
            hintText: l10n.practiceListSearch,
            leading: const Icon(Icons.search, size: AppSizes.searchBarIconSize),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
            ),
            onChanged: _searchPractices,
            trailing: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  return AnimatedOpacity(
                    opacity: value.text.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(
                        milliseconds: AppSizes.animationDurationMedium),
                    child: IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: AppSizes.searchBarClearIconSize,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _searchPractices('');
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.spacingMedium),

        // 视图切换按钮 - 改成使用BaseNavigationBar.createActionButton
        BaseNavigationBar.createActionButton(
          icon: _isGridView ? Icons.view_list : Icons.grid_view,
          tooltip: _isGridView
              ? l10n.practiceListListView
              : l10n.practiceListGridView,
          onPressed: () => setState(() => _isGridView = !_isGridView),
          isPrimary: true,
        ),
      ],
    );
  }

  void _confirmDeleteSelected() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.practiceListDeleteConfirm),
        content: Text(l10n.practiceListDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSelectedPractices();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedPractices() async {
    if (_selectedPractices.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final practiceService = ref.read(practiceServiceProvider);
      await practiceService.deletePractices(_selectedPractices.toList());

      setState(() {
        _isLoading = false;
        _isBatchMode = false;
        _selectedPractices.clear();
      });

      // Reload practices
      _loadPractices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).delete),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '${AppLocalizations.of(context).practiceListError}: $e';
      });
    }
  }

  void _handlePracticeLongPress(String practiceId) {
    if (!_isBatchMode) {
      setState(() {
        _isBatchMode = true;
        _togglePracticeSelection(practiceId);
      });
    }
  }

  void _handlePracticeTap(String practiceId) {
    if (_isBatchMode) {
      _togglePracticeSelection(practiceId);
    } else {
      _navigateToPracticeDetail(context, practiceId);
    }
  }

  Future<void> _loadPractices() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final practiceService = ref.read(practiceServiceProvider);

      // Create filter with sort and pagination parameters
      final filter = PracticeFilter(
        sortField: _sortField,
        sortOrder: _sortOrder,
        limit: _pageSize,
        offset: (_currentPage - 1) * _pageSize,
      );

      // Query practices
      var practicesResult = [];
      try {
        practicesResult = await practiceService.queryPractices(filter);
      } catch (e) {
        debugPrint('Query practices failed: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage =
                '${AppLocalizations.of(context).practiceListError}: $e';
          });
        }
        return;
      }

      // Get total count
      int totalCount = 0;
      try {
        totalCount = await practiceService.count(filter);
      } catch (e) {
        debugPrint('Get total count failed: $e');
      }

      // Convert PracticeEntity list to Map<String, dynamic> list
      final List<Map<String, dynamic>> practicesMap = [];

      for (final practice in practicesResult) {
        try {
          final Map<String, dynamic> practiceMap = {
            'id': practice.id,
            'title': practice.title,
            'status': practice.status,
            'createTime': practice.createTime.toIso8601String(),
            'updateTime': practice.updateTime.toIso8601String(),
            'pageCount': practice.pages.length,
            'thumbnail': practice.thumbnail,
          };

          practicesMap.add(practiceMap);
        } catch (e) {
          debugPrint('Convert practice entity failed: $e');
        }
      }

      if (mounted) {
        setState(() {
          _practices = practicesMap;
          _filteredPractices.clear();
          _filteredPractices.addAll(practicesMap);
          _totalItems = totalCount;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Load practices failed: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              '${AppLocalizations.of(context).practiceListError}: $e';
        });
      }
    }
  }

  void _navigateToEditPage([String? practiceId]) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.practiceEdit,
      arguments: practiceId,
    );

    // Refresh practices when returning
    _loadPractices();
  }

  void _navigateToPracticeDetail(BuildContext context, String practiceId) {
    _navigateToEditPage(practiceId);
  }

  void _searchPractices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPractices.clear();
        _filteredPractices.addAll(_practices);
      } else {
        _filteredPractices.clear();
        _filteredPractices.addAll(_practices.where((practice) {
          final title = practice['title'] as String? ?? '';
          return title.toLowerCase().contains(query.toLowerCase());
        }));
      }
    });
  }

  void _toggleBatchMode() {
    setState(() {
      _isBatchMode = !_isBatchMode;
      if (!_isBatchMode) {
        _selectedPractices.clear();
      }
    });
  }

  void _togglePracticeSelection(String id) {
    setState(() {
      if (_selectedPractices.contains(id)) {
        _selectedPractices.remove(id);
      } else {
        _selectedPractices.add(id);
      }
    });
  }
}
