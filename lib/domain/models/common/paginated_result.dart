/// Paginated result container
class PaginatedResult<T> {
  /// Items in current page
  final List<T> items;

  /// Total number of items across all pages
  final int totalCount;

  /// Current page number (1-based)
  final int currentPage;

  /// Number of items per page
  final int pageSize;

  /// Constructor
  PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });

  /// Check if there is a next page
  bool get hasNextPage => currentPage < totalPages;

  /// Check if there is a previous page
  bool get hasPreviousPage => currentPage > 1;

  /// Calculate total number of pages
  int get totalPages => (totalCount / pageSize).ceil();
}
