import 'package:flutter/material.dart';

import '../../widgets/character_collection/character_collection_panel.dart';

class CharacterCollectionPage extends StatelessWidget {
  final String imageId;
  final String workTitle;
  final List<String> images;

  const CharacterCollectionPage({
    super.key,
    required this.imageId,
    required this.workTitle,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CharacterCollectionPanel(
        imageId: imageId,
        workTitle: workTitle,
        images: images,
      ),
    );
  }
}
