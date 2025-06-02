// filepath: lib/canvas/ui/toolbar/modern_tool_state_manager.dart

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'tool_state_manager.dart';

/// 现代化工具状态管理器
///
/// 职责:
/// 1. 以类型安全的方式管理工具状态
/// 2. 提供细粒度的变更通知
/// 3. 支持工具配置和预设
/// 4. 提供持久化支持
class ModernToolStateManager extends ChangeNotifier {
  /// 当前选中的工具
  ToolType _currentTool = ToolType.select;

  /// 工具历史记录
  final List<ToolType> _toolHistory = [];

  /// 最大历史记录数量
  final int _maxHistorySize = 10;

  /// 工具配置映射
  final Map<ToolType, ToolConfiguration> _configurations = {};

  /// 工具预设映射
  final Map<String, Map<ToolType, ToolConfiguration>> _presets = {};

  /// 变更监听器
  final List<void Function(ToolChangeNotification)> _changeListeners = [];

  /// 创建现代化工具状态管理器
  ModernToolStateManager() {
    _initializeDefaultConfigurations();
  }

  /// 获取可用工具预设列表
  List<String> get availablePresets => _presets.keys.toList();

  /// 是否可以返回到上一个工具
  bool get canGoBack => _toolHistory.isNotEmpty;

  /// 获取已配置的工具列表
  Set<ToolType> get configuredTools =>
      UnmodifiableSetView(_configurations.keys.toSet());

  /// 当前选中的工具
  ToolType get currentTool => _currentTool;

  /// 获取工具历史记录
  List<ToolType> get toolHistory => UnmodifiableListView(_toolHistory);

  /// 添加工具变更监听器
  void addToolChangeListener(void Function(ToolChangeNotification) listener) {
    _changeListeners.add(listener);
  }

  /// 应用工具预设
  void applyPreset(String presetName) {
    final preset = _presets[presetName];
    if (preset == null) return;

    // 应用预设中的所有工具配置
    preset.forEach((toolType, configuration) {
      _configurations[toolType] = configuration;
    });

    // 通知变更
    _notifyToolChange(
      ToolChangeNotification(
        type: ToolChangeNotificationType.reset,
        details: {'presetName': presetName},
      ),
    );

    notifyListeners();
  }

  /// 创建工具预设
  void createPreset(String presetName) {
    // 创建当前配置的快照
    final presetConfigurations = <ToolType, ToolConfiguration>{};
    _configurations.forEach((toolType, configuration) {
      presetConfigurations[toolType] = configuration;
    });

    _presets[presetName] = presetConfigurations;
  }

  /// 删除工具预设
  void deletePreset(String presetName) {
    _presets.remove(presetName);
  }

  @override
  void dispose() {
    _changeListeners.clear();
    super.dispose();
  }

  /// 导出工具状态
  Map<String, dynamic> exportState() {
    final configurationsMap = <String, dynamic>{};
    _configurations.forEach((toolType, configuration) {
      configurationsMap[toolType.name] = configuration.toMap();
    });

    final presetsMap = <String, dynamic>{};
    _presets.forEach((presetName, presetConfigs) {
      final presetConfigMap = <String, dynamic>{};
      presetConfigs.forEach((toolType, configuration) {
        presetConfigMap[toolType.name] = configuration.toMap();
      });
      presetsMap[presetName] = presetConfigMap;
    });

    return {
      'currentTool': _currentTool.name,
      'configurations': configurationsMap,
      'presets': presetsMap,
    };
  }

  /// 获取指定工具的配置
  T? getToolConfiguration<T extends ToolConfiguration>(ToolType toolType) {
    final config = _configurations[toolType];
    return (config is T) ? config : null;
  }

  /// 返回上一个工具
  bool goBack() {
    if (_toolHistory.isEmpty) return false;

    final previousTool = _toolHistory.removeLast();
    _setCurrentTool(previousTool, addToHistory: false);
    return true;
  }

  /// 导入工具状态
  void importState(Map<String, dynamic> state) {
    // 清空当前状态
    _configurations.clear();
    _presets.clear();
    _toolHistory.clear();

    // 导入配置
    final configurationsMap = state['configurations'] as Map<String, dynamic>?;
    if (configurationsMap != null) {
      configurationsMap.forEach((toolName, configMap) {
        final toolType = ToolType.values.firstWhere(
          (t) => t.name == toolName,
          orElse: () => ToolType.select,
        );
        final config = ToolConfiguration.fromMap(
          toolType,
          configMap as Map<String, dynamic>,
        );
        _configurations[toolType] = config;
      });
    }

    // 导入预设
    final presetsMap = state['presets'] as Map<String, dynamic>?;
    if (presetsMap != null) {
      presetsMap.forEach((presetName, presetConfigsMap) {
        final presetConfigs = <ToolType, ToolConfiguration>{};
        (presetConfigsMap as Map<String, dynamic>)
            .forEach((toolName, configMap) {
          final toolType = ToolType.values.firstWhere(
            (t) => t.name == toolName,
            orElse: () => ToolType.select,
          );
          final config = ToolConfiguration.fromMap(
            toolType,
            configMap as Map<String, dynamic>,
          );
          presetConfigs[toolType] = config;
        });
        _presets[presetName] = presetConfigs;
      });
    }

    // 设置当前工具
    final currentToolName = state['currentTool'] as String?;
    if (currentToolName != null) {
      final toolType = ToolType.values.firstWhere(
        (t) => t.name == currentToolName,
        orElse: () => ToolType.select,
      );
      _setCurrentTool(toolType, addToHistory: false);
    }

    // 通知变更
    _notifyToolChange(
      const ToolChangeNotification(
        type: ToolChangeNotificationType.reset,
      ),
    );

    notifyListeners();
  }

  /// 移除工具变更监听器
  void removeToolChangeListener(
      void Function(ToolChangeNotification) listener) {
    _changeListeners.remove(listener);
  }

  /// 重置所有工具配置
  void resetAllConfigurations() {
    _configurations.clear();
    _initializeDefaultConfigurations();

    // 通知变更
    _notifyToolChange(
      const ToolChangeNotification(
        type: ToolChangeNotificationType.reset,
      ),
    );

    notifyListeners();
  }

  /// 重置工具配置
  void resetToolConfiguration(ToolType toolType) {
    final defaultConfig = _createDefaultConfiguration(toolType);
    if (defaultConfig != null) {
      _configurations[toolType] = defaultConfig;

      // 通知变更
      _notifyToolChange(
        ToolChangeNotification(
          type: ToolChangeNotificationType.configuration,
          toolType: toolType,
        ),
      );

      notifyListeners();
    }
  }

  /// 设置当前工具
  void setTool(ToolType toolType) {
    _setCurrentTool(toolType);
  }

  /// 更新工具配置
  void updateToolConfiguration<T extends ToolConfiguration>(
    ToolType toolType,
    T configuration,
  ) {
    _configurations[toolType] = configuration;

    // 通知变更
    _notifyToolChange(
      ToolChangeNotification(
        type: ToolChangeNotificationType.configuration,
        toolType: toolType,
        details: configuration.toMap(),
      ),
    );

    notifyListeners();
  }

  /// 创建默认配置
  ToolConfiguration? _createDefaultConfiguration(ToolType toolType) {
    switch (toolType) {
      case ToolType.text:
        return const TextToolConfiguration(
          fontSize: 16.0,
          fontFamily: 'System',
          color: '#000000',
        );
      case ToolType.image:
        return const ImageToolConfiguration(
          opacity: 1.0,
          maintainAspectRatio: true,
        );
      case ToolType.collection:
        return const CollectionToolConfiguration(
          columns: 3,
          spacing: 8.0,
          sortOrder: 'newest',
        );
      default:
        return const DefaultToolConfiguration();
    }
  }

  /// 初始化默认配置
  void _initializeDefaultConfigurations() {
    for (final toolType in ToolType.values) {
      final defaultConfig = _createDefaultConfiguration(toolType);
      if (defaultConfig != null) {
        _configurations[toolType] = defaultConfig;
      }
    }
  }

  /// 通知工具变更
  void _notifyToolChange(ToolChangeNotification notification) {
    for (final listener in _changeListeners) {
      listener(notification);
    }
  }

  /// 设置当前工具并管理历史记录
  void _setCurrentTool(ToolType toolType, {bool addToHistory = true}) {
    if (_currentTool == toolType) return;

    if (addToHistory) {
      _toolHistory.add(_currentTool);
      // 限制历史记录大小
      while (_toolHistory.length > _maxHistorySize) {
        _toolHistory.removeAt(0);
      }
    }

    final previousTool = _currentTool;
    _currentTool = toolType;

    // 通知变更
    _notifyToolChange(
      ToolChangeNotification(
        type: ToolChangeNotificationType.selection,
        toolType: toolType,
        details: {'previousTool': previousTool.name},
      ),
    );

    notifyListeners();
  }
}

/// 工具变更通知数据
class ToolChangeNotification {
  /// 变更类型
  final ToolChangeNotificationType type;

  /// 受影响的工具类型
  final ToolType? toolType;

  /// 变更详情
  final Map<String, dynamic>? details;

  /// 创建工具变更通知
  const ToolChangeNotification({
    required this.type,
    this.toolType,
    this.details,
  });
}

/// 工具变更通知类型
enum ToolChangeNotificationType {
  /// 工具选择变更
  selection,

  /// 工具配置变更
  configuration,

  /// 工具状态重置
  reset,
}
