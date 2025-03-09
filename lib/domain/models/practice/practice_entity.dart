import 'package:freezed_annotation/freezed_annotation.dart';

import 'practice_page.dart';

part 'practice_entity.freezed.dart';
part 'practice_entity.g.dart';

/// 字帖练习实体
@freezed
class PracticeEntity with _$PracticeEntity {
  /// 创建实例
  const factory PracticeEntity({
    /// ID
    required String id,

    /// 标题
    required String title,

    /// 页面列表
    @Default([]) List<PracticePage> pages,

    /// 标签列表
    @Default([]) List<String> tags,

    /// 状态
    @Default('active') String status,

    /// 创建时间
    @JsonKey(name: 'create_time') required DateTime createTime,

    /// 更新时间
    @JsonKey(name: 'update_time') required DateTime updateTime,
  }) = _PracticeEntity;

  /// 新建练习，自动生成ID和时间戳
  factory PracticeEntity.create({
    required String title,
    List<String> tags = const [],
    String status = 'active',
  }) {
    final now = DateTime.now();
    return PracticeEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      tags: tags,
      status: status,
      createTime: now,
      updateTime: now,
    );
  }

  /// 从JSON创建实例
  factory PracticeEntity.fromJson(Map<String, dynamic> json) =>
      _$PracticeEntityFromJson(json);

  /// 私有构造函数
  const PracticeEntity._();

  /// 获取下一个可用的页面索引
  int get nextPageIndex => pages.isEmpty ? 0 : pages.last.index + 1;

  /// 获取页面数量
  int get pageCount => pages.length;

  /// 添加页面
  PracticeEntity addPage(PracticePage page) {
    return copyWith(
      pages: [...pages, page],
      updateTime: DateTime.now(),
    );
  }

  /// 删除页面
  PracticeEntity removePage(int index) {
    return copyWith(
      pages: pages.where((p) => p.index != index).toList(),
      updateTime: DateTime.now(),
    );
  }

  /// 用于显示的文本描述
  @override
  String toString() => 'PracticeEntity(id: $id, title: $title)';

  /// 更新页面
  PracticeEntity updatePage(PracticePage page) {
    return copyWith(
      pages: pages.map((p) => p.index == page.index ? page : p).toList(),
      updateTime: DateTime.now(),
    );
  }
}
