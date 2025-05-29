import 'dart:async';

/// 通用缓存接口
///
/// 定义了所有缓存实现必须遵循的基本操作
abstract class ICache<K, V> {
  /// 获取缓存项
  ///
  /// [key] 缓存键
  /// 返回缓存值，如果不存在则返回null
  Future<V?> get(K key);

  /// 存储缓存项
  ///
  /// [key] 缓存键
  /// [value] 要缓存的值
  Future<void> put(K key, V value);

  /// 移除缓存项
  ///
  /// [key] 要移除的缓存键
  Future<void> invalidate(K key);

  /// 清空缓存
  Future<void> clear();

  /// 获取缓存大小
  ///
  /// 返回缓存中的项目数量或字节大小，取决于实现
  Future<int> size();

  /// 检查缓存中是否包含指定键
  ///
  /// [key] 要检查的缓存键
  /// 返回是否存在该键
  Future<bool> containsKey(K key);

  /// 移除缓存项
  ///
  /// [key] 要移除的缓存键
  Future<void> remove(K key);
}
