import 'package:flutter/material.dart';

import '../pages/works/character_collection_page.dart';

// Dialog version deprecated in favor of page-based approach
@Deprecated('Use Navigator to push CharacterCollectionPage directly')
void showCharacterCollectionDialog(
  BuildContext context, {
  required String imageId,
  required String workTitle,
}) {
  // Use navigation to CharacterCollectionPage instead
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => CharacterCollectionPage(
        imageId: imageId,
        workTitle: workTitle,
        images: const [], // Default to empty list since this dialog is deprecated
      ),
    ),
  );
}
