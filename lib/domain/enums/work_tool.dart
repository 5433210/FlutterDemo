enum WorkTool {
  brush('毛笔', 'brush'),
  hardPen('硬笔', 'hard_pen'),
  other('其他', 'other');

  final String label;
  final String value;

  const WorkTool(this.label, this.value);

  static WorkTool? fromValue(String? value) {
    if (value == null) return null;
    return WorkTool.values.firstWhere(
      (tool) => tool.value == value,
      orElse: () => WorkTool.brush,
    );
  }
}