import '../entities/practice.dart';
import '../value_objects/practice/practice_entity.dart';
import '../value_objects/practice/practice_page.dart';

/// 负责在 Practice 实体和 PracticeEntity 值对象之间进行映射
class PracticeMapper {
  /// 将 PracticeEntity 值对象转换为 Practice 实体
  static Practice fromValueObject(PracticeEntity valueObject) {
    return Practice(
      id: valueObject.id,
      createTime: valueObject.createTime,
      updateTime: valueObject.updateTime,
      title: valueObject.title,
      status: valueObject.status,
      pages: valueObject.pages.map((page) => page.toString()).toList(),
      metadata: valueObject.metadata?.tags ?? [],
    );
  }

  /// 将 Practice 实体转换为 PracticeEntity 值对象
  static PracticeEntity toValueObject(Practice entity) {
    // 这里我们需要将简单的页面字符串转换为完整的 PracticePage 对象
    // 实际实现可能需要更复杂的逻辑来处理页面数据
    final List<PracticePage> pages = entity.pages.map((pageData) {
      try {
        // 假设能够从页面数据中解析出页面信息
        // 这里简化处理，实际应用中可能需要更复杂的逻辑
        return PracticePage.fromJson(
          {
            'index': 0,
            'size': {
              'unit': 'mm',
              'resUnit': 'dpi',
              'resUnitValue': 300,
              'width': 210.0,
              'height': 297.0,
            },
            'layers': [],
          },
        );
      } catch (e) {
        // 解析失败时创建默认页面
        return PracticePage(
          index: 0,
          size: PageSize.a4(),
          layers: [],
        );
      }
    }).toList();

    return PracticeEntity(
      id: entity.id,
      createTime: entity.createTime,
      updateTime: entity.updateTime,
      title: entity.title,
      status: entity.status,
      pages: pages,
      metadata: PracticeMetadata(tags: entity.metadata),
    );
  }
}
