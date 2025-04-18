import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'practice_element.dart';
import 'practice_layer.dart';

part 'practice_page.freezed.dart';
part 'practice_page.g.dart';

/// Converter for EdgeInsets to JSON and back
class EdgeInsetsConverter
    implements JsonConverter<EdgeInsets, Map<String, dynamic>> {
  const EdgeInsetsConverter();

  @override
  EdgeInsets fromJson(Map<String, dynamic> json) {
    return EdgeInsets.only(
      left: (json['left'] as num?)?.toDouble() ?? 0.0,
      top: (json['top'] as num?)?.toDouble() ?? 0.0,
      right: (json['right'] as num?)?.toDouble() ?? 0.0,
      bottom: (json['bottom'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Map<String, dynamic> toJson(EdgeInsets edgeInsets) {
    return {
      'left': edgeInsets.left,
      'top': edgeInsets.top,
      'right': edgeInsets.right,
      'bottom': edgeInsets.bottom,
    };
  }
}

@freezed
class PracticePage with _$PracticePage {
  const factory PracticePage({
    required String id,
    @Default('') String name,
    @Default(0) int index,
    @Default(210.0) double width,
    @Default(297.0) double height,
    @Default('color') String backgroundType,
    String? backgroundImage,
    @Default('#FFFFFF') String backgroundColor,
    String? backgroundTexture,
    @Default(1.0) double backgroundOpacity,
    @EdgeInsetsConverter() @Default(EdgeInsets.all(20.0)) EdgeInsets margin,
    @Default(<PracticeLayer>[]) List<PracticeLayer> layers,
  }) = _PracticePage;

  factory PracticePage.defaultPage() => const PracticePage(
        id: 'default',
        name: 'Default Page',
        index: 0,
        width: 210.0, // A4 width in mm
        height: 297.0, // A4 height in mm
        backgroundType: 'color',
        backgroundColor: '#FFFFFF',
        backgroundOpacity: 1.0,
        margin: EdgeInsets.all(20.0),
        layers: [],
      );

  factory PracticePage.fromJson(Map<String, dynamic> json) =>
      _$PracticePageFromJson(json);

  // Helper methods to make operations easier for the UI
  const PracticePage._();

  PracticePage addElement(String layerId, PracticeElement element) {
    final updatedLayers = layers.map((layer) {
      if (layer.id == layerId) {
        return layer.copyWith(elements: [...layer.elements, element]);
      }
      return layer;
    }).toList();

    return copyWith(layers: updatedLayers);
  }

  PracticePage addLayer(PracticeLayer layer) {
    return copyWith(layers: [...layers, layer]);
  }

  List<PracticeElement> getAllElements() {
    final allElements = <PracticeElement>[];
    for (final layer in layers) {
      allElements.addAll(layer.elements);
    }
    return allElements;
  }

  PracticeLayer? getLayer(String layerId) {
    try {
      return layers.firstWhere((layer) => layer.id == layerId);
    } catch (e) {
      return null;
    }
  }

  PracticePage moveLayer(String layerId, int newIndex) {
    final currentLayers = [...layers];
    final currentIndex =
        currentLayers.indexWhere((layer) => layer.id == layerId);
    if (currentIndex < 0) return this;

    final layer = currentLayers.removeAt(currentIndex);
    currentLayers.insert(newIndex, layer);
    return copyWith(layers: currentLayers);
  }

  PracticePage removeElement(String layerId, String elementId) {
    final updatedLayers = layers.map((layer) {
      if (layer.id == layerId) {
        final updatedElements =
            layer.elements.where((element) => element.id != elementId).toList();
        return layer.copyWith(elements: updatedElements);
      }
      return layer;
    }).toList();

    return copyWith(layers: updatedLayers);
  }

  PracticePage removeLayer(String layerId) {
    return copyWith(
      layers: layers.where((layer) => layer.id != layerId).toList(),
    );
  }

  PracticePage setSize(double width, double height) {
    return copyWith(width: width, height: height);
  }

  PracticePage updateElement(String layerId, PracticeElement updatedElement) {
    final updatedLayers = layers.map((layer) {
      if (layer.id == layerId) {
        final updatedElements = layer.elements.map((element) {
          return element.id == updatedElement.id ? updatedElement : element;
        }).toList();
        return layer.copyWith(elements: updatedElements);
      }
      return layer;
    }).toList();

    return copyWith(layers: updatedLayers);
  }

  PracticePage updateLayer(PracticeLayer updatedLayer) {
    return copyWith(
      layers: layers
          .map((layer) => layer.id == updatedLayer.id ? updatedLayer : layer)
          .toList(),
    );
  }
}
