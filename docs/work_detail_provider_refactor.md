# Work Detail Provider Refactoring Design

## Directory Structure
```
lib/
├── presentation/
│   ├── providers/
│   │   └── work_detail_provider.dart        # Provider定义和依赖注入
│   └── viewmodels/
│       ├── states/
│       │   └── work_detail_state.dart       # 状态定义
│       └── work_detail_view_model.dart      # 业务逻辑
```

## 1. States (work_detail_state.dart)
```dart
@freezed
class WorkDetailState with _$WorkDetailState {
  const factory WorkDetailState({
    // 加载状态
    @Default(false) bool isLoading,
    @Default(false) bool isDeleting,
    @Default(false) bool isSaving,
    
    // 数据状态
    WorkEntity? work,
    WorkEntity? editingWork,
    
    // 编辑状态
    @Default(false) bool isEditing,
    @Default(false) bool hasChanges,
    @Default([]) List<WorkEditCommand> commandHistory,
    @Default(-1) int historyIndex,
    
    // 错误状态
    String? error,
  }) = _WorkDetailState;

  const WorkDetailState._();

  // 计算属性
  bool get canUndo => 
    isEditing && 
    commandHistory.isNotEmpty && 
    historyIndex >= 0;

  bool get canRedo =>
    isEditing && 
    commandHistory.isNotEmpty &&
    historyIndex < commandHistory.length - 1;
}
```

## 2. ViewModel (work_detail_view_model.dart)
```dart
class WorkDetailViewModel extends StateNotifier<WorkDetailState> {
  final WorkService _workService;
  final StateRestorationService _stateRestorationService;
  Timer? _autoSaveTimer;

  WorkDetailViewModel({
    required WorkService workService,
    required StateRestorationService stateRestorationService,
  }) : _workService = workService,
       _stateRestorationService = stateRestorationService,
       super(const WorkDetailState()) {
    _setupAutoSave();
  }

  // 生命周期方法
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  // 数据加载方法
  Future<void> loadWorkDetails(String workId);
  
  // 编辑操作方法
  Future<void> enterEditMode();
  Future<void> cancelEditing();
  Future<bool> saveChanges();
  Future<bool> deleteWork();
  
  // 命令操作方法
  Future<void> executeCommand(WorkEditCommand command);
  Future<void> undo();
  Future<void> redo();
  
  // 表单更新方法
  void updateWorkBasicInfo({...});
  void updateWorkTags(List<String> tags);
  void markAsChanged();
  
  // 状态恢复方法
  Future<bool> tryRestoreEditState(String workId);
  
  // 内部辅助方法
  void _setupAutoSave();
  Future<void> _saveEditState();
  Future<void> _clearEditState(String workId);
}
```

## 3. Provider (work_detail_provider.dart)
```dart
/// Tab索引Provider
final workDetailTabIndexProvider = StateProvider<int>((ref) => 0);

/// 图片索引Provider
final currentWorkImageIndexProvider = StateProvider<int>((ref) => 0);

/// 主要状态Provider
final workDetailProvider = StateNotifierProvider.autoDispose<WorkDetailViewModel, WorkDetailState>((ref) {
  // 注入依赖
  final workService = ref.watch(workServiceProvider);
  final stateRestoration = ref.watch(stateRestorationServiceProvider);
  
  // 创建ViewModel实例
  return WorkDetailViewModel(
    workService: workService,
    stateRestorationService: stateRestoration,
  );
});

/// 状态选择器
final workDetailLoadingProvider = Provider<bool>((ref) {
  return ref.watch(workDetailProvider.select((s) => s.isLoading));
});

final workDetailErrorProvider = Provider<String?>((ref) {
  return ref.watch(workDetailProvider.select((s) => s.error));
});

final workDetailEditingProvider = Provider<bool>((ref) {
  return ref.watch(workDetailProvider.select((s) => s.isEditing));
});
```

## 实施步骤

1. **创建目录结构**
   ```bash
   mkdir -p lib/presentation/viewmodels/states
   ```

2. **迁移状态类**
   - 创建 work_detail_state.dart
   - 添加 freezed 注解
   - 移动状态定义和计算属性

3. **迁移ViewModel**
   - 创建 work_detail_view_model.dart
   - 移动所有业务逻辑
   - 实现接口和方法

4. **精简Provider**
   - 保留 work_detail_provider.dart
   - 只保留Provider定义
   - 添加状态选择器

## 测试策略

1. **状态测试**
   - 状态初始化测试
   - 计算属性测试
   - 状态转换测试

2. **ViewModel测试**
   - 业务逻辑测试
   - 命令执行测试
   - 状态恢复测试

3. **Provider测试**
   - 依赖注入测试
   - 状态选择器测试
   - 生命周期测试
