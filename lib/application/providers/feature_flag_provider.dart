import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infrastructure/providers/shared_preferences_provider.dart';

/// 功能标志提供者
final featureFlagsProvider =
    StateNotifierProvider<FeatureFlagsNotifier, FeatureFlags>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return FeatureFlagsNotifier(prefs);
});

/// 功能标志状态
class FeatureFlags {
  final bool useMaterial3UI;

  const FeatureFlags({
    this.useMaterial3UI = false,
  });

  FeatureFlags copyWith({
    bool? useMaterial3UI,
  }) {
    return FeatureFlags(
      useMaterial3UI: useMaterial3UI ?? this.useMaterial3UI,
    );
  }
}

/// 功能标志状态管理器
class FeatureFlagsNotifier extends StateNotifier<FeatureFlags> {
  final SharedPreferences _prefs;

  FeatureFlagsNotifier(this._prefs) : super(const FeatureFlags()) {
    _loadFlags();
  }

  /// 设置Material 3 UI标志
  Future<void> setUseMaterial3UI(bool value) async {
    await _prefs.setBool('use_material3_ui', value);
    state = state.copyWith(useMaterial3UI: value);
  }

  /// 加载功能标志
  void _loadFlags() {
    final useMaterial3UI = _prefs.getBool('use_material3_ui') ?? false;
    state = FeatureFlags(useMaterial3UI: useMaterial3UI);
  }
}
