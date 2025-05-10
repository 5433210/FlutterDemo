/// 排序字段类型
enum SortField {
  fileName('fileName', '文件名称'),
  fileUpdatedAt('fileUpdatedAt', '文件修改时间'),
  fileSize('fileSize', '文件大小'),
  title('title', '标题'),
  author('author', '作者'),
  creationDate('creationDate', '创作日期'),
  createTime('createTime', '创建时间'),
  updateTime('updateTime', '更新时间'),
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
      orElse: () => SortField.fileName,
    );
  }
}
