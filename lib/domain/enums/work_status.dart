/// 作品状态
enum WorkStatus {
  draft('draft', '草稿'),
  published('published', '已发布'),
  archived('archived', '已归档');

  final String value;
  final String label;

  const WorkStatus(this.value, this.label);

  /// 是否已归档
  bool get isArchived => this == WorkStatus.archived;

  /// 是否为草稿
  bool get isDraft => this == WorkStatus.draft;

  /// 是否为非草稿状态
  bool get isNotDraft => !isDraft;

  /// 是否已发布
  bool get isPublished => this == WorkStatus.published;

  /// 从字符串解析状态
  static WorkStatus fromString(String value) {
    return WorkStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkStatus.draft,
    );
  }
}
