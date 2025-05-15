import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../domain/models/practice/practice_filter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/common/resizable_panel.dart';
import '../../widgets/common/sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/pagination/m3_pagination_controls.dart';
import 'components/m3_practice_filter_panel.dart';
import 'components/m3_practice_grid_view.dart';
import 'components/m3_practice_list_navigation_bar.dart';
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
  bool _isFilterPanelExpanded = true;

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

  // Sorting and filtering
  String _sortField = 'updateTime';
  String _sortOrder = 'desc';

  // 过滤器
  late PracticeFilter _filter;

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
          // Access a string from the extension to keep the import
          final errorMsg = '${l10n.practiceListFilterTitle}: $_errorMessage';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
          setState(() {
            _hasError = false;
          });
        }
      });
    }

    return PageLayout(
      toolbar: M3PracticeListNavigationBar(
        isGridView: _isGridView,
        onToggleViewMode: () => setState(() => _isGridView = !_isGridView),
        isBatchMode: _isBatchMode,
        onToggleBatchMode: _toggleBatchMode,
        selectedCount: _selectedPractices.length,
        onDeleteSelected:
            _selectedPractices.isNotEmpty ? _confirmDeleteSelected : null,
        onNewPractice: () => _navigateToEditPage(),
        // 排序和搜索功能已移至过滤面板
        onSearch: (_) {},
        sortField: _sortField,
        sortOrder: _sortOrder,
        onSortFieldChanged: (_) {},
        onSortOrderChanged: () {},
        onBackPressed: () {
          // Check if we can safely pop
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 左侧过滤面板
                if (_isFilterPanelExpanded)
                  ResizablePanel(
                    initialWidth: 300,
                    minWidth: 280,
                    maxWidth: 400,
                    isLeftPanel: true,
                    child: M3PracticeFilterPanel(
                      filter: _filter,
                      onFilterChanged: _updateFilter,
                      onSearch: _searchPractices,
                      onToggleExpand: _toggleFilterPanel,
                    ),
                  ),

                // 过滤面板切换按钮
                SidebarToggle(
                  isOpen: _isFilterPanelExpanded,
                  onToggle: _toggleFilterPanel,
                  alignRight: false,
                ),

                // 主内容区域
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
              ],
            ),
          ),

          // 分页控件
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
    // 初始化过滤器
    _filter = PracticeFilter(
      sortField: _sortField,
      sortOrder: _sortOrder,
      limit: _pageSize,
      offset: (_currentPage - 1) * _pageSize,
    );
    _loadPractices();
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

      // 更新过滤器的分页信息
      final filter = _filter.copyWith(
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

  // 切换过滤面板显示/隐藏
  void _toggleFilterPanel() {
    setState(() {
      _isFilterPanelExpanded = !_isFilterPanelExpanded;
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

  // 更新过滤器
  void _updateFilter(PracticeFilter newFilter) {
    setState(() {
      _filter = newFilter;
      _sortField = newFilter.sortField;
      _sortOrder = newFilter.sortOrder;
      _currentPage = 1; // 重置到第一页
    });
    _loadPractices();
  }
}
