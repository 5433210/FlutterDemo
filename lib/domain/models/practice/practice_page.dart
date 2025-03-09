import 'package:freezed_annotation/freezed_annotation.dart';

import 'practice_layer.dart';

part 'practice_page.freezed.dart';
part 'practice_page.g.dart';

/// 页面尺寸
@freezed
class PageSize with _$PageSize {
  const factory PageSize({
    /// 尺寸单位 (例如: 'mm')
    @Default('mm') String unit,

    /// 分辨率单位 (例如: 'dpi')
    @Default('dpi') String resUnit,

    /// 分辨率单位值
    @Default(300) int resUnitValue,

    /// 宽度 (默认A4宽度210mm)
    @Default(210.0) double width,

    /// 高度 (默认A4高度297mm)
    @Default(297.0) double height,
  }) = _PageSize;

  /// 从JSON创建实例
  factory PageSize.fromJson(Map<String, dynamic> json) =>
      _$PageSizeFromJson(json);

  const PageSize._();
}

/// 字帖页面信息
@freezed
class PracticePage with _$PracticePage {
  const factory PracticePage({
    /// 页面序号
    required int index,

    /// 页面尺寸
    @Default(PageSize()) PageSize size,

    /// 页面图层列表
    @Default([]) List<PracticeLayer> layers,

    /// 创建时间
    @JsonKey(name: 'create_time') required DateTime createTime,

    /// 更新时间
    @JsonKey(name: 'update_time') required DateTime updateTime,
  }) = _PracticePage;

  /// 创建新页面
  factory PracticePage.create(int index, {PageSize? size}) {
    final now = DateTime.now();
    return PracticePage(
      index: index,
      size: size ?? const PageSize(),
      createTime: now,
      updateTime: now,
    );
  }

  /// 从JSON创建实例
  factory PracticePage.fromJson(Map<String, dynamic> json) =>
      _$PracticePageFromJson(json);

  const PracticePage._();

  /// 获取图层数量
  int get layerCount => layers.length;

  /// 添加图层
  PracticePage addLayer(PracticeLayer layer) {
    return copyWith(
      layers: [...layers, layer],
      updateTime: DateTime.now(),
    );
  }

  /// 删除图层
  PracticePage removeLayer(String layerId) {
    return copyWith(
      layers: layers.where((l) => l.id != layerId).toList(),
      updateTime: DateTime.now(),
    );
  }

  /// 更新图层
  PracticePage updateLayer(PracticeLayer layer) {
    return copyWith(
      layers: layers.map((l) => l.id == layer.id ? layer : l).toList(),
      updateTime: DateTime.now(),
    );
  }
}
