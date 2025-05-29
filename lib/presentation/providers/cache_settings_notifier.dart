import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/cache/config/cache_config.dart';
import '../../infrastructure/providers/cache_providers.dart';
import '../../infrastructure/providers/shared_preferences_provider.dart';

/// Provider for cache settings
final cacheSettingsNotifierProvider =
    StateNotifierProvider<CacheSettingsNotifier, CacheConfig>((ref) {
  return CacheSettingsNotifier(ref);
});

/// Cache settings state notifier
class CacheSettingsNotifier extends StateNotifier<CacheConfig> {
  final Ref ref;

  CacheSettingsNotifier(this.ref) : super(const CacheConfig()) {
    // Initialize with current cache config
    state = ref.read(cacheConfigProvider);
  }

  /// Update memory image cache capacity
  Future<void> setMemoryImageCacheCapacity(int capacity) async {
    final newConfig = state.copyWith(memoryImageCacheCapacity: capacity);
    await _saveConfig(newConfig);
  }

  /// Update memory data cache capacity
  Future<void> setMemoryDataCacheCapacity(int capacity) async {
    final newConfig = state.copyWith(memoryDataCacheCapacity: capacity);
    await _saveConfig(newConfig);
  }

  /// Update max disk cache size
  Future<void> setMaxDiskCacheSize(int size) async {
    final newConfig = state.copyWith(maxDiskCacheSize: size);
    await _saveConfig(newConfig);
  }

  /// Update disk cache TTL
  Future<void> setDiskCacheTtl(Duration ttl) async {
    final newConfig = state.copyWith(diskCacheTtl: ttl);
    await _saveConfig(newConfig);
  }

  /// Update auto cleanup enabled
  Future<void> setAutoCleanupEnabled(bool enabled) async {
    final newConfig = state.copyWith(autoCleanupEnabled: enabled);
    await _saveConfig(newConfig);

    // Start or stop monitoring based on new setting
    final cacheManager = ref.read(cacheManagerProvider);
    if (enabled) {
      cacheManager.startMemoryMonitoring(
          interval: newConfig.autoCleanupInterval);
    } else {
      cacheManager.stopMemoryMonitoring();
    }
  }

  /// Update auto cleanup interval
  Future<void> setAutoCleanupInterval(Duration interval) async {
    final newConfig = state.copyWith(autoCleanupInterval: interval);
    await _saveConfig(newConfig);

    // Restart monitoring with new interval if enabled
    if (newConfig.autoCleanupEnabled) {
      final cacheManager = ref.read(cacheManagerProvider);
      cacheManager.stopMemoryMonitoring();
      cacheManager.startMemoryMonitoring(interval: interval);
    }
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await _saveConfig(const CacheConfig());

    // Update monitoring with default settings
    final cacheManager = ref.read(cacheManagerProvider);
    if (const CacheConfig().autoCleanupEnabled) {
      cacheManager.stopMemoryMonitoring();
      cacheManager.startMemoryMonitoring(
        interval: const CacheConfig().autoCleanupInterval,
      );
    } else {
      cacheManager.stopMemoryMonitoring();
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    final cacheManager = ref.read(cacheManagerProvider);
    await cacheManager.clearAll();
  }

  /// Save config to SharedPreferences
  Future<void> _saveConfig(CacheConfig newConfig) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonString = jsonEncode(newConfig.toJson());
    await prefs.setString('cache_config', jsonString);
    state = newConfig;
  }
}
