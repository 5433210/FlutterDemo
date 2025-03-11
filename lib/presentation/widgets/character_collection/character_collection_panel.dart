import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class CharacterCollectionPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: const Center(
        child: Text('字符提取面板'),
      ),
    );
  }
}
