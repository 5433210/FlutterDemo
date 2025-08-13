import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/pagination_settings_provider.dart';

/// Material 3 分页控件（支持持久化页面大小设置）
class M3PersistentPaginationControls extends ConsumerStatefulWidget {
  /// 页面标识符（用于区分不同页面的设置）
  final String pageId;

  /// 当前页码
  final int currentPage;

  /// 总项数
  final int totalItems;

  /// 页码变化回调
  final Function(int) onPageChanged;

  /// 页面大小变化回调
  final Function(int) onPageSizeChanged;

  /// 可选的页面大小
  final List<int> availablePageSizes;

  /// 默认页面大小（首次使用时的默认值）
  final int defaultPageSize;

  /// 是否显示页面大小选择器
  final bool showPageSizeSelector;

  const M3PersistentPaginationControls({
    super.key,
    required this.pageId,
    required this.currentPage,
    required this.totalItems,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.availablePageSizes = const [10, 20, 50, 100],
    this.defaultPageSize = 20,
    this.showPageSizeSelector = true,
  });

  @override
  ConsumerState<M3PersistentPaginationControls> createState() =>
      _M3PersistentPaginationControlsState();
}

class _M3PersistentPaginationControlsState
    extends ConsumerState<M3PersistentPaginationControls> {
  int? _currentPageSize;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePageSize();
  }

  /// 初始化页面大小（从持久化存储读取）
  void _initializePageSize() async {
    if (!_isInitialized) {
      try {
        final notifier = ref.read(paginationSettingsNotifierProvider.notifier);
        final size = await notifier.getPageSize(
          widget.pageId,
          defaultSize: widget.defaultPageSize,
        );

        if (mounted) {
          setState(() {
            _currentPageSize = size;
            _isInitialized = true;
          });

          // 仅当与父组件提供的默认 pageSize 不一致时才通知父组件，避免重复刷新
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (size != widget.defaultPageSize) {
              widget.onPageSizeChanged(size);
            }
          });
        }
      } catch (e) {
        // 使用默认值
        if (mounted) {
          setState(() {
            _currentPageSize = widget.defaultPageSize;
            _isInitialized = true;
          });
        }
      }
    }
  }

  /// 处理页面大小变化
  void _handlePageSizeChange(int? newSize) async {
    if (newSize != null && newSize != _currentPageSize) {
      try {
        // 保存到持久化存储
        final notifier = ref.read(paginationSettingsNotifierProvider.notifier);
        await notifier.setPageSize(widget.pageId, newSize);

        // 更新本地状态
        setState(() {
          _currentPageSize = newSize;
        });

        // 通知父组件
        widget.onPageSizeChanged(newSize);
      } catch (e) {
        // 错误处理 - 可以显示错误提示
        debugPrint('保存页面大小设置失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // 如果还未初始化，显示加载状态或使用默认值
    final pageSize = _currentPageSize ?? widget.defaultPageSize;
    final totalPages = (widget.totalItems / pageSize).ceil();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingMedium, vertical: AppSizes.spacingSmall),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 根据可用宽度决定显示模式
          final availableWidth = constraints.maxWidth;
          
          if (availableWidth < 400) {
            // 紧凑版本 - 只显示基本控制
            return _buildCompactLayout(context, pageSize, totalPages, l10n, theme);
          } else if (availableWidth < 600) {
            // 中等版本 - 隐藏总数显示或页面大小选择器
            return _buildMediumLayout(context, pageSize, totalPages, l10n, theme);
          } else {
            // 完整版本 - 显示所有元素
            return _buildFullLayout(context, pageSize, totalPages, l10n, theme);
          }
        },
      ),
    );
  }

  /// 构建紧凑版本的分页控制 - 只显示基本导航
  Widget _buildCompactLayout(
    BuildContext context,
    int pageSize,
    int totalPages,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 只显示上一页和下一页按钮
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: widget.currentPage > 1
              ? () => widget.onPageChanged(widget.currentPage - 1)
              : null,
          tooltip: l10n.previousPage,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.all(4),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 60),
          alignment: Alignment.center,
          child: Text(
            '${widget.currentPage}/$totalPages',
            style: theme.textTheme.bodySmall,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: widget.currentPage < totalPages
              ? () => widget.onPageChanged(widget.currentPage + 1)
              : null,
          tooltip: l10n.nextPage,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.all(4),
        ),
      ],
    );
  }

  /// 构建中等版本的分页控制 - 隐藏部分元素
  Widget _buildMediumLayout(
    BuildContext context,
    int pageSize,
    int totalPages,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 显示总数或页面信息
        Text(
          '${widget.currentPage} / $totalPages',
          style: theme.textTheme.bodyMedium,
        ),
        
        // 分页控制按钮
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.first_page, size: 20),
              onPressed: widget.currentPage > 1
                  ? () => widget.onPageChanged(1)
                  : null,
              tooltip: l10n.firstPage,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(6),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: widget.currentPage > 1
                  ? () => widget.onPageChanged(widget.currentPage - 1)
                  : null,
              tooltip: l10n.previousPage,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(6),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: widget.currentPage < totalPages
                  ? () => widget.onPageChanged(widget.currentPage + 1)
                  : null,
              tooltip: l10n.nextPage,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(6),
            ),
            IconButton(
              icon: const Icon(Icons.last_page, size: 20),
              onPressed: widget.currentPage < totalPages
                  ? () => widget.onPageChanged(totalPages)
                  : null,
              tooltip: l10n.lastPage,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(6),
            ),
          ],
        ),
        
        // 只在有足够空间时显示页面大小选择器
        if (widget.showPageSizeSelector)
          Container(
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: PopupMenuButton<int>(
              initialValue: pageSize,
              onSelected: _handlePageSizeChange,
              position: PopupMenuPosition.under,
              tooltip: l10n.itemsPerPage('$pageSize'),
              itemBuilder: (context) => widget.availablePageSizes
                  .map((size) => PopupMenuItem<int>(
                        value: size,
                        height: 28,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        child: Text(
                          '$size',
                          style: theme.textTheme.bodySmall,
                        ),
                      ))
                  .toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pageSize',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_drop_down, size: 14),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建完整版本的分页控制 - 显示所有元素
  Widget _buildFullLayout(
    BuildContext context,
    int pageSize,
    int totalPages,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 总数显示
        Text(
          l10n.totalItems('${widget.totalItems}'),
          style: theme.textTheme.bodyMedium,
        ),

        // 分页控制
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.first_page, size: 20),
              onPressed: widget.currentPage > 1
                  ? () => widget.onPageChanged(1)
                  : null,
              tooltip: l10n.firstPage,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: widget.currentPage > 1
                  ? () => widget.onPageChanged(widget.currentPage - 1)
                  : null,
              tooltip: l10n.previousPage,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(8),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 80),
              alignment: Alignment.center,
              child: Text(
                '${widget.currentPage} / $totalPages',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: widget.currentPage < totalPages
                  ? () => widget.onPageChanged(widget.currentPage + 1)
                  : null,
              tooltip: l10n.nextPage,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              icon: const Icon(Icons.last_page, size: 20),
              onPressed: widget.currentPage < totalPages
                  ? () => widget.onPageChanged(totalPages)
                  : null,
              tooltip: l10n.lastPage,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),

        // 页面大小选择器
        if (widget.showPageSizeSelector)
          Container(
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: PopupMenuButton<int>(
              initialValue: pageSize,
              onSelected: _handlePageSizeChange,
              position: PopupMenuPosition.under,
              tooltip: l10n.itemsPerPage('$pageSize'),
              itemBuilder: (context) => widget.availablePageSizes
                  .map((size) => PopupMenuItem<int>(
                        value: size,
                        height: 32,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Text(
                          l10n.itemsPerPage('$size'),
                          style: theme.textTheme.bodySmall,
                        ),
                      ))
                  .toList(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.itemsPerPage('$pageSize'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
