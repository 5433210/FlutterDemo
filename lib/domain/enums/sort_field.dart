enum SortField {
  name('名称', 'name'),
  author('作者', 'author'),
  creationDate('创作日期', 'creation_date'),
  importDate('导入日期', 'create_time'),
  updateDate('更新日期', 'update_time');

  final String label;
  final String field;

  const SortField(this.label, this.field);
}
