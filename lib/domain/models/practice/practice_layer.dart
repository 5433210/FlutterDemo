import 'package:demo/domain/models/practice/practice_element.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'practice_layer.freezed.dart';
part 'practice_layer.g.dart';

/// 字帖练习图层
@freezed
class PracticeLayer with _$PracticeLayer {
  const factory PracticeLayer({
    /// 图层ID
    required String id,

    /// 图层类型
    required PracticeLayerType type,

    /// 图片路径
    required String imagePath,

    /// 图层名称
    String? name,

    /// 图层描述
    String? description,

    /// 图层可见性
    @Default(true) bool visible,

    /// 图层锁定状态
    @Default(false) bool locked,

    /// 图层不透明度
    @Default(1.0) double opacity,

    /// 图层顺序
    @Default(0) int order,

    /// 图层元素列表
    @Default([]) List<PracticeElement> elements,

    /// 图层创建时间
    required DateTime createTime,

    /// 图层更新时间
    required DateTime updateTime,
  }) = _PracticeLayer;

  /// 新建图层
  factory PracticeLayer.create({
    required PracticeLayerType type,
    required String imagePath,
    String? name,
    String? description,
  }) {
    final now = DateTime.now();
    return PracticeLayer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      imagePath: imagePath,
      name: name,
      description: description,
      createTime: now,
      updateTime: now,
    );
  }

  /// 从JSON创建实例
  factory PracticeLayer.fromJson(Map<String, dynamic> json) =>
      _$PracticeLayerFromJson(json);

  /// 私有构造函数
  const PracticeLayer._();

  /// 切换锁定状态
  PracticeLayer toggleLock() {
    return copyWith(locked: !locked);
  }

  /// 切换可见性
  PracticeLayer toggleVisibility() {
    return copyWith(visible: !visible);
  }
}

/// 字帖练习图层类型
enum PracticeLayerType {
  /// 原稿图层
  source,

  /// 练习图层
  practice,

  /// 参考图层
  reference,
}
