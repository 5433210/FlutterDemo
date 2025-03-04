import 'package:flutter/material.dart';

import '../common/image_preview.dart';
import '../common/sidebar_toggle.dart';
import './collection_result.dart';

class CollectionPreview extends StatefulWidget {
  final String workId;
  final List<String> images;

  const CollectionPreview({
    super.key,
    required this.workId,
    required this.images,
  });

  @override
  State<CollectionPreview> createState() => _CollectionPreviewState();
}

class _CollectionPreviewState extends State<CollectionPreview> {
  bool _isPanelOpen = true;
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Main content area with image preview
          Expanded(
            child: ImagePreview(
              imagePaths: widget.images,
              initialIndex: _currentImageIndex,
              onIndexChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              padding: const EdgeInsets.all(16),
            ),
          ),

          // Sidebar toggle button
          Material(
            elevation: 1,
            child: Container(
              width: 32,
              color: Theme.of(context).colorScheme.surface,
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.center,
              child: SidebarToggle(
                isOpen: _isPanelOpen,
                onToggle: () {
                  setState(() {
                    _isPanelOpen = !_isPanelOpen;
                  });
                },
                alignRight: true,
              ),
            ),
          ),

          // Right panel - Results
          if (_isPanelOpen)
            Container(
              width: 350,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  left: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: const CollectionResult(),
            ),
        ],
      ),
    );
  }
}
