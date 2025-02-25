import 'package:flutter/material.dart';
import '../../../../viewmodels/states/work_browse_state.dart';

class ViewModeToggle extends StatelessWidget {
  final ViewMode viewMode;
  final VoidCallback onToggle;

  const ViewModeToggle({
    super.key,
    required this.viewMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        viewMode == ViewMode.grid ? Icons.grid_view : Icons.view_list,
      ),
      tooltip: viewMode == ViewMode.grid ? '切换到列表视图' : '切换到网格视图',
      onPressed: onToggle,
    );
  }
}
