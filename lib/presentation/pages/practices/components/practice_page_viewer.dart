import 'dart:io';

import 'package:demo/domain/value_objects/practice/element_content.dart';
import 'package:demo/domain/value_objects/practice/page_info.dart';
import 'package:flutter/material.dart';

class PracticePageViewer extends StatelessWidget {
  final PracticePageInfo page;
  final bool readOnly;
  final Function(PracticeElementContent)? onItemTap;

  const PracticePageViewer({
    super.key,
    required this.page,
    this.readOnly = true,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (page.items.isEmpty) {
      return const Center(
        child: Text('此页面没有内容'),
      );
    }

    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [],
        ),
      ),
    );
  }

  Widget _buildCharacterItem(BuildContext context, PracticeCharsContent item) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Character image
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
        ),

        const SizedBox(width: 16),

        // Character info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('汉字：${item.chars}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imagePath) {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        return const Center(
          child: Icon(Icons.broken_image, size: 32),
        );
      }

      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 32),
          );
        },
      );
    } catch (e) {
      return const Center(
        child: Icon(Icons.error, size: 32),
      );
    }
  }

  Widget _buildImageItem(BuildContext context, PracticeImageContent item) {
    final theme = Theme.of(context);
    final imagePath = item.path as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        Container(
          constraints: const BoxConstraints(
            maxHeight: 300,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildImage(imagePath),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, PracticeElementContent item) {
    final Widget itemWidget = switch (item.type) {
      'character' => _buildCharacterItem(context, item as PracticeCharsContent),
      'image' => _buildImageItem(context, item as PracticeImageContent),
      'text' => _buildTextItem(context, item as PracticeTextContent),
      _ => const SizedBox.shrink()
    };

    if (readOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: itemWidget,
      );
    }

    return InkWell(
      onTap: () => onItemTap?.call(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: itemWidget,
      ),
    );
  }

  Widget _buildTextItem(BuildContext context, PracticeTextContent item) {
    final theme = Theme.of(context);
    final text = item.content;

    return Text(text);
  }
}
