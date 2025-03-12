/// 数据库状态
class DatabaseState {
  /// 是否初始化完成
  final bool isInitialized;

  /// 当前版本
  final int version;

  /// 上次更新时间
  final DateTime? lastUpdate;

  /// 错误信息
  final String? error;

  const DatabaseState({
    this.isInitialized = false,
    this.version = 0,
    this.lastUpdate,
    this.error,
  });

  /// 创建错误状态
  factory DatabaseState.error(String error) => DatabaseState(
        isInitialized: false,
        error: error,
      );

  /// 创建初始状态
  factory DatabaseState.initial() => const DatabaseState();

  /// 创建已初始化状态
  factory DatabaseState.initialized(int version) => DatabaseState(
        isInitialized: true,
        version: version,
        lastUpdate: DateTime.now(),
      );

  /// 复制并修改部分属性
  DatabaseState copyWith({
    bool? isInitialized,
    int? version,
    DateTime? lastUpdate,
    String? error,
  }) {
    return DatabaseState(
      isInitialized: isInitialized ?? this.isInitialized,
      version: version ?? this.version,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'DatabaseState(initialized: $isInitialized, version: $version, lastUpdate: $lastUpdate, error: $error)';
  }
}
