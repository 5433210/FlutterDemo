import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';
import './character_extraction_preview.dart';

class CharacterCollectionPanel extends StatefulWidget {
  final String imageId;
  final String workTitle;
  final List<String> images;

  const CharacterCollectionPanel({
    super.key,
    required this.imageId,
    required this.workTitle,
    required this.images,
  });

  @override
  State<CharacterCollectionPanel> createState() =>
      _CharacterCollectionPanelState();
}

class _CharacterCollectionPanelState extends State<CharacterCollectionPanel> {
  final List<CharacterRegion> _collectedRegions = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 工具栏
        Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const BackButton(),
              Text(
                widget.workTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '已提取: ${_collectedRegions.length}个字符',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // 主要内容区域
        Expanded(
          child: CharacterExtractionPreview(
            imagePaths: widget.images,
            collectedRegions: _collectedRegions,
            onRegionCreated: (region) {
              setState(() {
                _collectedRegions.add(region);
              });
            },
            onRegionSelected: (region) {
              // 可以在这里处理区域选中事件
            },
            onRegionsDeleted: (regions) {
              setState(() {
                _collectedRegions.removeWhere((r) => regions.contains(r));
              });
            },
            workId: widget.imageId,
          ),
        ),
      ],
    );
  }
}
