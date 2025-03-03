import 'package:flutter/material.dart';

class CollectionTools extends StatefulWidget {
  final Function(dynamic) onToolSelected;

  const CollectionTools({
    super.key,
    required this.onToolSelected,
  });

  @override
  State<CollectionTools> createState() => _CollectionToolsState();
}

enum SelectionTool {
  click,
  rectangle,
  lasso,
}

enum ViewTool {
  zoom,
  pan,
}

class _CollectionToolsState extends State<CollectionTools> {
  SelectionTool _currentSelectionTool = SelectionTool.click;
  ViewTool _currentViewTool = ViewTool.pan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('选择工具'),
          ),
          // Selection tools
          _buildToolButton(
            icon: Icons.touch_app,
            tooltip: '点击选择',
            isSelected: _currentSelectionTool == SelectionTool.click,
            onPressed: () {
              setState(() {
                _currentSelectionTool = SelectionTool.click;
              });
              widget.onToolSelected(SelectionTool.click);
            },
          ),
          _buildToolButton(
            icon: Icons.crop_square,
            tooltip: '矩形框选',
            isSelected: _currentSelectionTool == SelectionTool.rectangle,
            onPressed: () {
              setState(() {
                _currentSelectionTool = SelectionTool.rectangle;
              });
              widget.onToolSelected(SelectionTool.rectangle);
            },
          ),
          _buildToolButton(
            icon: Icons.gesture,
            tooltip: '套索选择',
            isSelected: _currentSelectionTool == SelectionTool.lasso,
            onPressed: () {
              setState(() {
                _currentSelectionTool = SelectionTool.lasso;
              });
              widget.onToolSelected(SelectionTool.lasso);
            },
          ),
          const Divider(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('视图工具'),
          ),
          // View tools
          _buildToolButton(
            icon: Icons.zoom_in,
            tooltip: '缩放',
            isSelected: _currentViewTool == ViewTool.zoom,
            onPressed: () {
              setState(() {
                _currentViewTool = ViewTool.zoom;
              });
              widget.onToolSelected(ViewTool.zoom);
            },
          ),
          _buildToolButton(
            icon: Icons.pan_tool,
            tooltip: '平移',
            isSelected: _currentViewTool == ViewTool.pan,
            onPressed: () {
              setState(() {
                _currentViewTool = ViewTool.pan;
              });
              widget.onToolSelected(ViewTool.pan);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
        ),
      ),
    );
  }
}
