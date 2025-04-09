# 集字功能重构方案文档

## 1. 方案概述

本方案旨在重构现有集字功能的状态管理方式，从集中存储ID集合（selectedIds和modifiedIds）转变为对象内部属性（isSelected和isModified）管理模式。同时，采用事件通知机制实现不同Provider间的数据同步，简化组件间通信逻辑，提高代码可维护性。

## 2. 核心变更

### 2.1 数据模型变更

- 在`CharacterRegion`类中添加`isSelected`和`isModified`属性
- 逐步移除`CharacterCollectionState`中的`selectedIds`和`modifiedIds`集合

### 2.2 状态管理变更

- 添加事件通知机制`characterRefreshNotifierProvider`用于跨组件通信
- 扩展`CharacterCollectionProvider`提供访问/修改CharacterRegion状态的方法
- 整合`characterSaveNotifierProvider`功能至`CharacterCollectionProvider`
- 移除`CharacterRegionSyncService`，由事件通知机制替代

### 2.3 UI逻辑变更

- 修改UI组件使用新的属性和方法访问状态
- 通过事件通知机制实现CharacterGrid与CharacterCollection之间的数据同步

## 3. 详细修改清单

### 3.1 添加事件通知机制

```dart
// 新建文件: lib/presentation/providers/character/character_refresh_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 字符数据刷新通知Provider
/// 用于不同组件间协调字符数据的刷新
final characterRefreshNotifierProvider = StateNotifierProvider<RefreshNotifier, int>((ref) {
  return RefreshNotifier();
});

/// 刷新通知状态管理
/// 通过简单的计数器增长来触发订阅者刷新
class RefreshNotifier extends StateNotifier<int> {
  RefreshNotifier() : super(0);
  
  /// 通知所有监听者刷新数据
  void notifyRefresh() => state = state + 1;
  
  /// 通知特定类型的刷新事件
  void notifyEvent(RefreshEventType eventType) => state = state + 1;
}

/// 刷新事件类型
enum RefreshEventType {
  /// 字符保存事件
  characterSaved,
  
  /// 字符删除事件
  characterDeleted,
  
  /// 字符修改事件
  characterModified,
  
  /// 字符区域更新事件
  regionUpdated,
}
```

### 3.2 CharacterRegion 模型修改

```dart
// 修改文件: lib/domain/models/character/character_region.dart
@freezed
class CharacterRegion with _$CharacterRegion {
  const factory CharacterRegion({
    required String id,
    required String pageId,
    @RectConverter() required Rect rect,
    @Default(0.0) double rotation,
    @Default('') String character,
    required DateTime createTime,
    required DateTime updateTime,
    @Default(ProcessingOptions()) ProcessingOptions options,
    @OffsetListConverter() List<Offset>? erasePoints,
    @Default(false) bool isSaved,
    String? characterId,
    @Default(false) bool isSelected,  // 新增属性
    @Default(false) bool isModified,  // 新增属性
  }) = _CharacterRegion;
  
  // ...existing code...
  
  factory CharacterRegion.create({
    required String pageId,
    required Rect rect,
    double rotation = 0.0,
    String character = '',
    ProcessingOptions? options,
    String? characterId,
    bool isSelected = false,  // 新增参数
    bool isModified = false,  // 新增参数
  }) {
    final now = DateTime.now();
    return CharacterRegion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pageId: pageId,
      rect: rect,
      rotation: rotation,
      character: character,
      createTime: now,
      updateTime: now,
      options: options ?? const ProcessingOptions(),
      isSaved: false,
      characterId: characterId,
      isSelected: isSelected,  // 新增赋值
      isModified: isModified,  // 新增赋值
    );
  }
}

// 更新序列化方法
extension CharacterRegionExt on CharacterRegion {
  Map<String, dynamic> toDbJson() {
    return {
      // ...existing fields...
      'isSelected': isSelected,
      'isModified': isModified,
    };
  }

  static CharacterRegion fromDbJson(Map<String, dynamic> json) {
    return CharacterRegion(
      // ...existing fields...
      isSelected: json['isSelected'] as bool? ?? false,
      isModified: json['isModified'] as bool? ?? false,
    );
  }
}
```

### 3.3 CharacterViewModel 模型修改

```dart
// 修改文件: lib/presentation/viewmodels/states/character_grid_state.dart
@freezed
class CharacterViewModel with _$CharacterViewModel {
  const factory CharacterViewModel({
    required String id,
    required String pageId,
    required String character,
    required String thumbnailPath,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isFavorite,
    @Default(false) bool isSelected,  // 新增
    @Default(false) bool isModified,  // 新增
  }) = _CharacterViewModel;

  factory CharacterViewModel.fromJson(Map<String, dynamic> json) =>
      _$CharacterViewModelFromJson(json);
}

// 修改CharacterGridState，移除selectedIds字段
@freezed
class CharacterGridState with _$CharacterGridState {
  const factory CharacterGridState({
    @Default([]) List<CharacterViewModel> characters,
    @Default([]) List<CharacterViewModel> filteredCharacters,
    @Default('') String searchTerm,
    @Default(FilterType.all) FilterType filterType,
    // 删除 selectedIds 字段，将使用 CharacterViewModel 的 isSelected 属性
    @Default(1) int currentPage,
    @Default(1) int totalPages,
    @Default(false) bool loading,
    String? error,
  }) = _CharacterGridState;
}
```

### 3.4 CharacterCollectionState 修改

```dart
// 修改文件: lib/presentation/viewmodels/states/character_collection_state.dart
class CharacterCollectionState extends Equatable {
  final String? workId;
  final String? pageId;
  final List<CharacterRegion> regions;
  // 移除下面两个字段
  // final Set<String> selectedIds;
  // final Set<String> modifiedIds;
  final String? currentId;
  final Tool currentTool;
  final ProcessingOptions defaultOptions;
  final List<UndoAction> undoStack;
  final List<UndoAction> redoStack;
  final bool loading;
  final bool processing;
  final String? error;
  final bool isAdjusting;

  const CharacterCollectionState({
    this.workId,
    this.pageId,
    required this.regions,
    // 移除下面两个参数
    // required this.selectedIds,
    // required this.modifiedIds,
    this.currentId,
    required this.currentTool,
    required this.defaultOptions,
    required this.undoStack,
    required this.redoStack,
    required this.loading,
    required this.processing,
    this.error,
    this.isAdjusting = false,
  });

  factory CharacterCollectionState.initial() {
    return const CharacterCollectionState(
      regions: [],
      // 移除下面两个参数
      // selectedIds: {},
      // modifiedIds: {},
      currentTool: Tool.pan,
      defaultOptions: ProcessingOptions(),
      undoStack: [],
      redoStack: [],
      loading: false,
      processing: false,
      isAdjusting: false,
    );
  }
  
  // 添加基于regions计算的getter
  bool get hasMultiSelection => regions.where((r) => r.isSelected).isNotEmpty;
  bool get hasUnsavedChanges => regions.where((r) => r.isModified).isNotEmpty;
  
  // 移除selectedIds和modifiedIds相关的props
  @override
  List<Object?> get props => [
    workId,
    pageId,
    regions,
    // 移除下面两项
    // selectedIds,
    // modifiedIds,
    currentId,
    currentTool,
    defaultOptions,
    undoStack,
    redoStack,
    loading,
    processing,
    error,
    isAdjusting,
  ];
  
  // 移除selectedIds和modifiedIds相关的参数
  CharacterCollectionState copyWith({
    String? workId,
    String? pageId,
    List<CharacterRegion>? regions,
    // 移除下面两个参数
    // Set<String>? selectedIds,
    // Set<String>? modifiedIds,
    String? currentId,
    Tool? currentTool,
    ProcessingOptions? defaultOptions,
    List<UndoAction>? undoStack,
    List<UndoAction>? redoStack,
    bool? loading,
    bool? processing,
    String? error,
    bool? isAdjusting,
  }) {
    return CharacterCollectionState(
      workId: workId ?? this.workId,
      pageId: pageId ?? this.pageId,
      regions: regions ?? this.regions,
      // 移除下面两个参数
      // selectedIds: selectedIds ?? this.selectedIds,
      // modifiedIds: modifiedIds ?? this.modifiedIds,
      currentId: currentId ?? this.currentId,
      currentTool: currentTool ?? this.currentTool,
      defaultOptions: defaultOptions ?? this.defaultOptions,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      loading: loading ?? this.loading,
      processing: processing ?? this.processing,
      error: error,
      isAdjusting: isAdjusting ?? this.isAdjusting,
    );
  }
}
```

### 3.5 CharacterCollectionProvider 修改

```dart
// 修改文件: lib/presentation/providers/character/character_collection_provider.dart

// 修改Provider定义，传入ref
final characterCollectionProvider = StateNotifierProvider<
    CharacterCollectionNotifier, CharacterCollectionState>((ref) {
  final characterService = ref.watch(characterServiceProvider);
  final toolModeNotifier = ref.watch(toolModeProvider.notifier);
  final selectedRegionNotifier = ref.watch(selectedRegionProvider.notifier);

  return CharacterCollectionNotifier(
    characterService: characterService,
    toolModeNotifier: toolModeNotifier,
    selectedRegionNotifier: selectedRegionNotifier,
    ref: ref, // 传入ref参数
  );
});

class CharacterCollectionNotifier extends StateNotifier<CharacterCollectionState> {
  final CharacterService _characterService;
  final ToolModeNotifier _toolModeNotifier;
  final SelectedRegionNotifier _selectedRegionNotifier;
  final Ref _ref;  // 新增Ref引用

  CharacterCollectionNotifier({
    required CharacterService characterService,
    required ToolModeNotifier toolModeNotifier,
    required SelectedRegionNotifier selectedRegionNotifier,
    required Ref ref,  // 新增参数
  })  : _characterService = characterService,
        _toolModeNotifier = toolModeNotifier,
        _selectedRegionNotifier = selectedRegionNotifier,
        _ref = ref,  // 初始化
        super(CharacterCollectionState.initial());
  
  // 新增方法 - 选择相关操作
  bool isCharacterSelected(String id) {
    final character = state.regions.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Region not found: $id'),
    );
    return character.isSelected;
  }
  
  void setCharacterSelected(String id, bool isSelected) {
    final updatedRegions = state.regions.map((c) {
      if (c.id == id) {
        return c.copyWith(isSelected: isSelected);
      }
      return c;
    }).toList();
    
    state = state.copyWith(regions: updatedRegions);
  }
  
  List<CharacterRegion> getSelectedCharacters() {
    return state.regions.where((c) => c.isSelected).toList();
  }
  
  // 修改相关操作
  bool isCharacterModified(String id) {
    final character = state.regions.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Region not found: $id'),
    );
    return character.isModified;
  }
  
  void setCharacterModified(String id, bool isModified) {
    final updatedRegions = state.regions.map((c) {
      if (c.id == id) {
        return c.copyWith(isModified: isModified);
      }
      return c;
    }).toList();
    
    state = state.copyWith(regions: updatedRegions);
  }
  
  List<CharacterRegion> getModifiedCharacters() {
    return state.regions.where((c) => c.isModified).toList();
  }
  
  // 多选相关操作
  void addToSelection(String id) {
    if (state.regions.any((r) => r.id == id)) {
      final updatedRegions = state.regions.map((r) {
        if (r.id == id) {
          return r.copyWith(isSelected: true);
        }
        return r;
      }).toList();
      
      state = state.copyWith(regions: updatedRegions);
    }
  }
  
  void clearSelections() {
    final updatedRegions = state.regions.map((r) {
      if (r.isSelected) {
        return r.copyWith(isSelected: false);
      }
      return r;
    }).toList();
    
    state = state.copyWith(regions: updatedRegions);
  }
  
  void toggleSelection(String id) {
    final updatedRegions = state.regions.map((r) {
      if (r.id == id) {
        return r.copyWith(isSelected: !r.isSelected);
      }
      return r;
    }).toList();
    
    state = state.copyWith(regions: updatedRegions);
  }
  
  void selectAll() {
    final updatedRegions = state.regions.map((r) => r.copyWith(isSelected: true)).toList();
    state = state.copyWith(regions: updatedRegions);
  }
  
  // 整合characterSaveNotifierProvider功能，加入保存功能
  Future<void> saveCharacters() async {
    final modifiedCharacters = getModifiedCharacters();
    
    try {
      state = state.copyWith(processing: true);
      
      // 保存逻辑
      for (final character in modifiedCharacters) {
        // 保存到数据库或API
        final result = await _saveCharacter(character);
        
        if (result.isSuccess) {
          // 更新为已保存状态
          setCharacterModified(character.id, false);
          
          // 如果返回了characterId，更新区域关联
          if (result.data != null) {
            updateRegionAfterSave(character.id, result.data!);
          }
        } else {
          state = state.copyWith(
            error: result.error?.toString() ?? '保存失败',
            processing: false,
          );
          return;
        }
      }
      
      state = state.copyWith(
        processing: false,
        error: null,
      );
      
      // 保存成功后触发刷新通知
      _ref.read(characterRefreshNotifierProvider.notifier).notifyEvent(RefreshEventType.characterSaved);
      
    } catch (e) {
      state = state.copyWith(
        processing: false,
        error: e.toString(),
      );
    }
  }
  
  Future<Result<String>> _saveCharacter(CharacterRegion character) async {
    try {
      // 原来在characterSaveNotifierProvider中的保存逻辑
      final processingResult = ProcessingResult(
        originalCrop: await _getOriginalCrop(character),
        binaryImage: await _getBinaryImage(character),
        thumbnail: await _getThumbnail(character),
        boundingBox: character.rect,
      );
      
      final savedEntity = await _characterService.saveCharacter(
        character,
        processingResult,
        character.characterId,
      );
      
      return Result.success(savedEntity.id);
    } catch (e) {
      return Result.failure(e);
    }
  }

  // 移植的其他重要方法...
  void updateRegionAfterSave(String regionId, String characterId) {
    final updatedRegions = state.regions.map((r) {
      if (r.id == regionId) {
        return r.copyWith(
          characterId: characterId,
          isSaved: true,
          isModified: false,
        );
      }
      return r;
    }).toList();
    
    state = state.copyWith(regions: updatedRegions);
  }
  
  // 移植 CharacterRegionSyncService 功能
  Future<void> updateRegionGrid() async {
    if (state.workId == null || state.pageId == null) return;
    
    try {
      // 重新加载最新的区域数据
      final regions = await _characterService.getPageRegions(state.pageId!);
      
      // 保持当前选择状态
      final updatedRegions = regions.map((newRegion) {
        // 查找对应的本地区域以保留其选择状态
        final existingRegion = state.regions.firstWhere(
          (r) => r.id == newRegion.id,
          orElse: () => newRegion,
        );
        
        return newRegion.copyWith(
          isSelected: existingRegion.isSelected,
          isModified: existingRegion.isModified,
        );
      }).toList();
      
      state = state.copyWith(regions: updatedRegions);
    } catch (e) {
      AppLogger.error('更新区域网格失败', error: e);
    }
  }
  
  // 修改选区创建方法
  CharacterRegion? createRegion(Rect rect) {
    try {
      // ...existing validation code...
      
      // 创建新区域
      final region = CharacterRegion.create(
        pageId: _currentPageId!,
        rect: rect,
        options: const ProcessingOptions(),
        isModified: true,  // 新建即为已修改
      );
      
      // 更新区域列表和状态
      final updatedRegions = [...state.regions, region];
      
      state = state.copyWith(
        regions: updatedRegions,
        currentId: region.id,
        isAdjusting: true, // 立即进入可调节状态
      );
      
      // 选中新创建的区域
      selectRegion(region.id);
      
      return region;
    } catch (e, stack) {
      // ...error handling...
      return null;
    }
  }
}
```

### 3.6 CharacterGridProvider 修改

```dart
// 修改文件: lib/presentation/providers/character/character_grid_provider.dart
final characterGridProvider =
    StateNotifierProvider<CharacterGridNotifier, CharacterGridState>((ref) {
  final repository = ref.watch(characterRepositoryProvider);
  final workId = ref.watch(workDetailProvider).work?.id;
  final persistenceService = ref.watch(characterPersistenceServiceProvider);
  
  // 监听刷新通知
  ref.listen(characterRefreshNotifierProvider, (previous, current) {
    if (previous != current) {
      // 当通知变化时，刷新数据
      ref.read(characterGridProvider.notifier).loadCharacters();
    }
  });
  
  return CharacterGridNotifier(repository, workId!, persistenceService);
});

class CharacterGridNotifier extends StateNotifier<CharacterGridState> {
  // ...existing code...
  
  void clearSelection() {
    final updatedCharacters = state.characters.map((c) => 
      c.isSelected ? c.copyWith(isSelected: false) : c).toList();
      
    state = state.copyWith(
      characters: updatedCharacters,
      filteredCharacters: _filterAndSortCharacters(updatedCharacters),
    );
  }
  
  void toggleSelection(String id) {
    final updatedCharacters = state.characters.map((c) {
      if (c.id == id) {
        return c.copyWith(isSelected: !c.isSelected);
      }
      return c;
    }).toList();
    
    state = state.copyWith(
      characters: updatedCharacters,
      filteredCharacters: _filterAndSortCharacters(updatedCharacters),
    );
  }
  
  // 获取选中的字符ID列表
  List<String> getSelectedCharacterIds() {
    return state.characters.where((c) => c.isSelected).map((c) => c.id).toList();
  }
  
  Future<void> deleteSelected() async {
    final selectedIds = getSelectedCharacterIds();
    if (selectedIds.isEmpty) return;
    
    try {
      state = state.copyWith(loading: true, error: null);

      // 删除所选字符
      await _repository.deleteBatch(selectedIds);

      // 重新加载数据
      await loadCharacters();

      // 清除选择
      clearSelection();
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }
  
  // 更新loadCharacters方法，将字符转换为视图模型时包含isSelected和isModified属性
  Future<void> loadCharacters() async {
    try {
      state = state.copyWith(loading: true, error: null);
      
      // 从仓库加载作品相关的字符
      final characters = await _repository.findByWorkId(workId);
      
      // 转换为视图模型，并包含isSelected和isModified属性
      final viewModels = await Future.wait(characters.map((char) async {
        // 获取缩略图路径  
        final path = await _persistenceService.getThumbnailPath(char.id);
        
        return CharacterViewModel(
          id: char.id,
          pageId: char.pageId,
          character: char.character,
          thumbnailPath: path,
          createdAt: char.createTime,
          updatedAt: char.updateTime,
          isFavorite: char.isFavorite,
          isSelected: false,   // 默认未选中
          isModified: false,   // 默认未修改
        );
      }).toList());
      
      // 更新状态
      const itemsPerPage = 16;
      final totalPages = (viewModels.length / itemsPerPage).ceil();
      
      state = state.copyWith(
        characters: viewModels,
        filteredCharacters: viewModels,
        totalPages: totalPages > 0 ? totalPages : 1,
        currentPage: 1,
        loading: false,
      );
      
      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }
  
  // 添加帮助方法更新筛选结果
  List<CharacterViewModel> _filterAndSortCharacters(List<CharacterViewModel> characters) {
    var filtered = List<CharacterViewModel>.from(characters);
    
    // 应用当前过滤条件
    if (state.searchTerm.isNotEmpty) {
      filtered = filtered
          .where((char) => char.character.contains(state.searchTerm))
          .toList();
    }
    
    // 应用当前排序
    switch (state.filterType) {
      // ...existing filter implementation...
    }
    
    return filtered;
  }
}
```

### 3.7 RegionsPainter 更新

```dart
// 修改文件: lib/presentation/widgets/character_collection/regions_painter.dart
class RegionsPainter extends CustomPainter {
  final List<CharacterRegion> regions;
  final CoordinateTransformer transformer;
  final String? hoveredId;
  final String? adjustingRegionId;
  final Tool currentTool;
  final bool isAdjusting;

  const RegionsPainter({
    required this.regions,
    required this.transformer,
    this.hoveredId,
    this.adjustingRegionId,
    required this.currentTool,
    this.isAdjusting = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ...existing code...

    for (final region in regions) {
      // ...existing canvas preparation...

      // 确定区域状态
      final isSelected = region.isSelected;
      final isHovered = region.id == hoveredId;
      final isRegionAdjusting = isAdjusting && region.id == adjustingRegionId;
      final isSaved = !region.isModified;

      // 获取区域状态
      final regionState = RegionStateUtils.getRegionState(
        currentTool: currentTool,
        isSelected: isSelected,
        isAdjusting: isRegionAdjusting,
      );

      // 绘制选区
      _drawRegion(
        canvas,
        viewportRect,
        region,
        regions.indexOf(region) + 1,
        regionState,
        isSelected,
        isHovered,
        isSaved,
      );
    }
  }

  // ...existing methods...
}
```

### 3.8 ImageView 更新

```dart
// 修改文件: lib/presentation/widgets/character_collection/image_view.dart
Widget _buildImageLayer(
  WorkImageState imageState,
  List<CharacterRegion> regions,
  Size viewportSize,
) {
  final toolMode = ref.watch(toolModeProvider);
  final characterCollection = ref.watch(characterCollectionProvider);
  
  // 不再需要获取 selectedIds 和 modifiedIds
  
  return MouseRegion(
    // ...existing code...
  );
}
```

### 3.9 CharacterGridView 更新

```dart
// 修改文件: lib/presentation/widgets/character_collection/character_grid_view.dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final gridState = ref.watch(characterGridProvider);
  
  // ...existing code...
  
  return Column(
    children: [
      // ...existing code...
      
      // 更新批量操作栏条件和计数方式
      if (gridState.filteredCharacters.any((c) => c.isSelected))
        BatchActionBar(
          selectedCount: gridState.filteredCharacters.where((c) => c.isSelected).length,
          onExport: () => ref.read(characterGridProvider.notifier).exportSelected(),
          onDelete: () => ref.read(characterGridProvider.notifier).deleteSelected(),
          onCancel: () => ref.read(characterGridProvider.notifier).clearSelection(),
        ),
      
      // 更新字符网格
      Expanded(
        child: GridView.builder(
          // ...existing code...
          itemBuilder: (context, index) {
            final character = gridState.filteredCharacters[index];
            return CharacterTile(
              character: character,
              isSelected: character.isSelected, // 使用对象属性
              onTap: () => onCharacterSelected(character.id),
              onLongPress: () => ref
                  .read(characterGridProvider.notifier)
                  .toggleSelection(character.id),
            );
          },
        ),
      ),
    ],
  );
}
```

### 3.10 CharacterEditPanel 更新

```dart
// 修改文件: lib/widgets/character_edit/character_edit_panel.dart
Future<void> _handleSave() async {
  // ...existing validation code...
  
  try {
    // ...existing code...
    
    // 从selectedRegionProvider获取当前选区
    final selectedRegion = ref.read(selectedRegionProvider);
    if (selectedRegion == null) {
      throw _SaveError('未选择任何区域');
    }
    
    // ...existing code...
    
    // 更新选区信息
    final updatedRegion = selectedRegion.copyWith(
      pageId: widget.pageId,
      character: _characterController.text,
      options: processingOptions,
      isModified: true, // 标记为已修改
    );
    
    // 使用整合后的 CharacterCollectionProvider 进行保存
    final collectionNotifier = ref.read(characterCollectionProvider.notifier);
    
    // 更新选区
    collectionNotifier.updateRegion(selectedRegion.id, updatedRegion);
    
    // 保存字符
    await collectionNotifier.saveCharacters();
    
    if (mounted) {
      // ...existing code...
    }
  } catch (e) {
    // ...existing error handling...
  }
}
```

### 3.11 删除不再需要的文件

- 删除 character_save_notifier.dart
- 删除 character_region_sync_service.dart

## 4. 迁移策略

为确保平稳迁移，我们将采用以下分阶段实施方案：

### 阶段1：添加新属性和通知机制（准备阶段）

1. 在 CharacterRegion 类中添加 isSelected 和 isModified 属性
2. 创建 characterRefreshNotifierProvider 事件通知机制
3. 扩展 CharacterCollectionProvider，添加访问和修改新属性的方法
4. 保留 selectedIds 和 modifiedIds，实现双写操作保证兼容性

### 阶段2：UI组件更新（过渡阶段）

1. 更新 CharacterViewModel 添加 isSelected 和 isModified 属性
2. 修改 RegionsPainter 直接使用 CharacterRegion 的属性
3. 更新 CharacterGridView 使用新属性显示选中状态
4. 配置 CharacterGridProvider 监听刷新通知
5. 整合 characterSaveNotifierProvider 功能到 CharacterCollectionProvider 中

### 阶段3：移除旧代码（完成阶段）

1. 从 CharacterCollectionState 中移除 selectedIds 和 modifiedIds 字段
2. 从所有组件中移除对 selectedIds 和 modifiedIds 的引用
3. 删除 characterSaveNotifierProvider
4. 删除 CharacterRegionSyncService

### 阶段4：测试与优化

1. 全面测试创建、选择和修改区域功能
2. 测试保存功能和集字网格刷新
3. 测试批量操作功能
4. 性能优化和内存使用分析

## 5. 潜在风险与对策

### 5.1 状态不一致风险

**风险**：由于状态从集中管理转向分散在各对象中，可能导致不同组件间状态不一致。

**对策**：

- 实施严格的数据流，所有状态变更通过Provider方法完成
- 添加事件通知机制确保相关组件同步更新
- 保留关键节点的日志记录，便于调试潜在问题

### 5.2 性能影响

**风险**：每次更新单个对象属性可能导致整个列表重建，影响性能。

**对策**：

- 使用不可变数据结构和精确的列表更新策略
- 实现UI组件的shouldRepaint和shouldRebuild优化
- 进行性能基准测试，针对性能瓶颈进行优化

### 5.3 迁移遗漏

**风险**：可能遗漏某些代码路径中对旧字段的引用。

**对策**：

- 使用静态分析工具查找所有引用
- 增加单元测试覆盖率
- 在过渡期保留双重数据写入，确保功能正常

### 5.4 依赖组件兼容性

**风险**：其他组件可能直接依赖于selectedIds和modifiedIds。

**对策**：

- 在过渡期提供兼容性API
- 创建迁移指南帮助相关组件适配新接口
- 在完全移除前进行全面的系统测试

## 6. 总结

本重构方案通过将状态从集中式ID列表转变为对象内部属性，结合事件通知机制实现组件间通信，将大幅提高代码的可维护性和可扩展性。分阶段实施策略确保迁移过程平稳可控，同时保障用户体验不受影响。

此外，新的状态管理模式更符合面向对象设计原则，使得代码更具有自解释性，有助于后续功能开发和团队协作。

# 关于selectedRegionProvider的补充说明

在重构方案中，我们需要更详细地说明`selectedRegionProvider`的角色及其与新设计的集成。这是一个重要的遗漏点，应当在方案中具体说明。

## selectedRegionProvider的定位和作用

`selectedRegionProvider`是一个现有的Provider，用于跨组件共享当前选中的字符区域。在重构后的架构中，它将与新的状态管理方式协同工作：

1. **定位**：`selectedRegionProvider`负责存储和提供对当前选中区域的直接引用，便于编辑面板等组件直接访问完整的区域对象
2. **与CharacterRegion.isSelected的区别**：
   - `CharacterRegion.isSelected`标记区域在集合中的选择状态，用于多选、批量操作等场景
   - `selectedRegionProvider`存储当前焦点选中的单个区域，用于详细编辑操作

## 重构方案中的selectedRegionProvider修改

### 1. 状态同步机制

添加`selectedRegionProvider`和`CharacterRegion.isSelected`之间的同步机制：

```dart
void selectRegion(String? id) {
  if (id == null) {
    // 清除选择
    _selectedRegionNotifier.clearRegion();
    
    // 更新所有区域的isSelected状态
    final updatedRegions = state.regions.map((r) => 
      r.isSelected ? r.copyWith(isSelected: false) : r
    ).toList();
    
    state = state.copyWith(
      regions: updatedRegions,
      currentId: null,
    );
    return;
  }

  // 查找目标区域
  final region = state.regions.firstWhere(
    (r) => r.id == id,
    orElse: () => throw Exception('Region not found: $id'),
  );

  // 更新selectedRegionProvider
  _selectedRegionNotifier.setRegion(region);
  
  // 更新isSelected状态 - 只选中当前区域
  final updatedRegions = state.regions.map((r) => 
    r.copyWith(isSelected: r.id == id)
  ).toList();
  
  state = state.copyWith(
    regions: updatedRegions,
    currentId: id,
  );
}
```

### 2. 多选模式处理

在多选模式下，需要处理`selectedRegionProvider`和多个`isSelected=true`的区域之间的关系：

```dart
// 多选时添加到选择集合，但不改变selectedRegionProvider
void toggleSelection(String id) {
  // 查找区域
  final region = state.regions.firstWhere(
    (r) => r.id == id,
    orElse: () => throw Exception('Region not found: $id'),
  );
  
  // 反转选择状态
  final newIsSelected = !region.isSelected;
  
  // 更新区域状态
  final updatedRegions = state.regions.map((r) {
    if (r.id == id) {
      return r.copyWith(isSelected: newIsSelected);
    }
    return r;
  }).toList();
  
  // 如果是选中操作且当前没有currentId，设置为currentId
  final newCurrentId = newIsSelected && state.currentId == null ? id : state.currentId;
  
  // 如果是取消选择且当前currentId是此id，则清除currentId和selectedRegion
  if (!newIsSelected && state.currentId == id) {
    _selectedRegionNotifier.clearRegion();
    state = state.copyWith(
      regions: updatedRegions,
      currentId: null,
    );
  } else {
    // 其他情况下只更新regions和currentId
    state = state.copyWith(
      regions: updatedRegions,
      currentId: newCurrentId,
    );
    
    // 如果是选中操作且当前没有selectedRegion，设置selectedRegion
    if (newIsSelected && _selectedRegionNotifier.getCurrentRegion() == null) {
      _selectedRegionNotifier.setRegion(region.copyWith(isSelected: true));
    }
  }
}
```

### 3. 修改CharacterEditPanel的使用方式

`CharacterEditPanel`需要同时支持`selectedRegionProvider`和`isSelected`的协调工作：

```dart
Future<void> _handleSave() async {
  // ...existing validation code...
  
  try {
    // 从selectedRegionProvider获取当前选区
    final selectedRegion = ref.read(selectedRegionProvider);
    if (selectedRegion == null) {
      throw _SaveError('未选择任何区域');
    }
    
    // 更新选区信息，保留isSelected状态
    final updatedRegion = selectedRegion.copyWith(
      pageId: widget.pageId,
      character: _characterController.text,
      options: processingOptions,
      isModified: true, // 标记为已修改
      isSelected: selectedRegion.isSelected, // 保留选中状态
    );
    
    // 使用整合后的CharacterCollectionProvider进行保存
    final collectionNotifier = ref.read(characterCollectionProvider.notifier);
    
    // 更新选区并保存
    collectionNotifier.updateRegion(selectedRegion.id, updatedRegion);
    await collectionNotifier.saveCharacters();
    
    // 更新selectedRegionProvider中的对象
    ref.read(selectedRegionProvider.notifier).setRegion(updatedRegion);
    
    // ...existing code...
  } catch (e) {
    // ...error handling...
  }
}
```

## 重构方案更新

在重构方案文档的第3.5节"CharacterCollectionProvider修改"后，添加新的3.6节：

### 3.6 selectedRegionProvider与isSelected的协调

```dart
// 在CharacterCollectionProvider中添加协调逻辑
// 确保selectedRegionProvider和isSelected属性保持一致

// 1. 更新selectRegion方法，同步更新两种状态
void selectRegion(String? id) {
  // 同时更新selectedRegionProvider和CharacterRegion.isSelected
  // ...代码如上文所示
}

// 2. 添加更新selectedRegionProvider的辅助方法
void syncSelectedRegionWithState() {
  // 如果有currentId，确保selectedRegionProvider有对应的区域
  if (state.currentId != null) {
    final region = state.regions.firstWhere(
      (r) => r.id == state.currentId,
      orElse: () => null,
    );
    
    if (region != null) {
      _selectedRegionNotifier.setRegion(region);
    }
  } else {
    // 如果没有currentId，清除selectedRegion
    _selectedRegionNotifier.clearRegion();
  }
}

// 3. 在所有可能影响选择状态的方法中添加同步
@override
void didUpdateState(CharacterCollectionState previous, CharacterCollectionState current) {
  // 当regions或currentId改变时，同步selectedRegionProvider
  if (previous.regions != current.regions || previous.currentId != current.currentId) {
    syncSelectedRegionWithState();
  }
}
```

并在文档的实施策略部分强调：

> 在迁移过程中，需要特别注意`selectedRegionProvider`和`CharacterRegion.isSelected`状态的一致性。`selectedRegionProvider`作为当前编辑焦点的区域引用，将持续在系统中发挥重要作用，仅在多选和批量操作场景下会与`isSelected`属性有所区别。当使用单选模式时，当前选中区域会同时反映在两个状态中；在多选模式下，`selectedRegionProvider`存储最后选中或当前编辑的区域，而`isSelected=true`的区域可能有多个。
