/// 排序字段类型
enum SortField {
  title('title', '标题'),
  author('author', '作者'),
  creationDate('creation_date', '创作日期'),
  createTime('create_time', '创建时间'),
  updateTime('update_time', '更新时间'),
  tool('tool', '工具'),
  style('style', '风格'),
  none('none', '无');

  final String value;
  final String label;

  const SortField(this.value, this.label);
}

extension SortFieldParsing on SortField {
  static SortField fromString(String value) {
    return SortField.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SortField.createTime,
    );
  }
}
