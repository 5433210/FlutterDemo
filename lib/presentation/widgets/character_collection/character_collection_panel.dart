import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import './collection_preview.dart';
import './collection_toolbar.dart';
import './collection_tools.dart';

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
  bool _autoDetectStrokes = true;
  double _noiseReduction = 0.5;
  double _binarization = 0.5;
  double _grayscaleRange = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          // Top toolbar with preprocessing tools and operation tools
          CollectionToolbar(
            title: widget.workTitle,
            autoDetectStrokes: _autoDetectStrokes,
            noiseReduction: _noiseReduction,
            binarization: _binarization,
            grayscaleRange: _grayscaleRange,
            onAutoDetectStrokesChanged: (value) {
              setState(() {
                _autoDetectStrokes = value;
              });
            },
            onNoiseReductionChanged: (value) {
              setState(() {
                _noiseReduction = value;
              });
            },
            onBinarizationChanged: (value) {
              setState(() {
                _binarization = value;
              });
            },
            onGrayscaleRangeChanged: (value) {
              setState(() {
                _grayscaleRange = value;
              });
            },
            onReset: () {
              setState(() {
                _autoDetectStrokes = true;
                _noiseReduction = 0.5;
                _binarization = 0.5;
                _grayscaleRange = 0.5;
              });
            },
            onClose: () {
              Navigator.of(context).pop();
            },
          ),
          // Main content area
          Expanded(
            child: Row(
              children: [
                // Left tools panel
                CollectionTools(
                  onToolSelected: (tool) {
                    // Handle tool selection
                  },
                ),
                // Preview area with built-in result panel
                Expanded(
                  flex: 3,
                  child: CollectionPreview(
                    workId: widget.imageId,
                    images: widget.images,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
