import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/domain/models/practice/practice_element.dart';

void main() {
  group('PracticeElement', () {
    test('TextElement creation and serialization', () {
      final textElement = PracticeElement.text(
        id: 'text1',
        x: 10.0,
        y: 20.0,
        width: 100.0,
        height: 50.0,
        layerId: 'layer1',
        text: 'Hello World',
        fontSize: 16.0,
      );

      expect(textElement.id, 'text1');
      expect(textElement.x, 10.0);
      expect(textElement.y, 20.0);
      expect(textElement.width, 100.0);
      expect(textElement.height, 50.0);
      expect(textElement.layerId, 'layer1');
      
      // Test type property
      expect(textElement.type, 'text');

      // Test serialization
      final map = textElement.toMap();
      expect(map['id'], 'text1');
      expect(map['type'], 'text');
      expect(map['x'], 10.0);
      expect(map['text'], 'Hello World');
      expect(map['fontSize'], 16.0);
      
      // Test deserialization
      final deserializedElement = PracticeElement.fromJson(map);
      expect(deserializedElement, isA<TextElement>());
      expect(deserializedElement.id, 'text1');
      expect(deserializedElement.x, 10.0);
      expect(deserializedElement.y, 20.0);
      
      // Test when method
      final typeString = deserializedElement.when(
        text: (id, x, y, width, height, rotation, layerId, isLocked, opacity,
            text, fontSize, fontFamily, fontColor, backgroundColor, textAlign,
            lineSpacing, letterSpacing, padding) => 'text',
        image: (id, x, y, width, height, rotation, layerId, isLocked, opacity,
            imageUrl, crop, flipHorizontal, flipVertical, fit) => 'image',
        collection: (id, x, y, width, height, rotation, layerId, isLocked, opacity,
            characters, direction, flowDirection, characterSpacing, lineSpacing,
            padding, fontColor, backgroundColor, characterSize, defaultImageType,
            characterImages, alignment) => 'collection',
        group: (id, x, y, width, height, rotation, layerId, isLocked, opacity,
            children) => 'group',
      );
      expect(typeString, 'text');
    });

    test('ImageElement creation and serialization', () {
      final imageElement = PracticeElement.image(
        id: 'image1',
        x: 30.0,
        y: 40.0,
        width: 200.0,
        height: 150.0,
        layerId: 'layer1',
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(imageElement.id, 'image1');
      expect(imageElement.x, 30.0);
      expect(imageElement.y, 40.0);
      expect(imageElement.width, 200.0);
      expect(imageElement.height, 150.0);
      expect(imageElement.layerId, 'layer1');
      
      // Test type property
      expect(imageElement.type, 'image');

      // Test serialization
      final map = imageElement.toMap();
      expect(map['id'], 'image1');
      expect(map['type'], 'image');
      expect(map['x'], 30.0);
      expect(map['imageUrl'], 'https://example.com/image.jpg');
      
      // Test deserialization
      final deserializedElement = PracticeElement.fromJson(map);
      expect(deserializedElement, isA<ImageElement>());
      expect(deserializedElement.id, 'image1');
      expect(deserializedElement.x, 30.0);
      expect(deserializedElement.y, 40.0);
    });

    test('CollectionElement creation and serialization', () {
      final collectionElement = PracticeElement.collection(
        id: 'collection1',
        x: 50.0,
        y: 60.0,
        width: 300.0,
        height: 200.0,
        layerId: 'layer1',
        characters: '你好世界',
        direction: CollectionDirection.horizontal,
      );

      expect(collectionElement.id, 'collection1');
      expect(collectionElement.x, 50.0);
      expect(collectionElement.y, 60.0);
      expect(collectionElement.width, 300.0);
      expect(collectionElement.height, 200.0);
      expect(collectionElement.layerId, 'layer1');
      
      // Test type property
      expect(collectionElement.type, 'collection');

      // Test serialization
      final map = collectionElement.toMap();
      expect(map['id'], 'collection1');
      expect(map['type'], 'collection');
      expect(map['x'], 50.0);
      expect(map['characters'], '你好世界');
      expect(map['direction'], 'horizontal');
      
      // Test deserialization
      final deserializedElement = PracticeElement.fromJson(map);
      expect(deserializedElement, isA<CollectionElement>());
      expect(deserializedElement.id, 'collection1');
      expect(deserializedElement.x, 50.0);
      expect(deserializedElement.y, 60.0);
    });

    test('GroupElement creation and serialization', () {
      final textElement = PracticeElement.text(
        id: 'text1',
        x: 10.0,
        y: 20.0,
        width: 100.0,
        height: 50.0,
        layerId: 'layer1',
        text: 'Hello World',
      );
      
      final imageElement = PracticeElement.image(
        id: 'image1',
        x: 30.0,
        y: 40.0,
        width: 200.0,
        height: 150.0,
        layerId: 'layer1',
        imageUrl: 'https://example.com/image.jpg',
      );
      
      final groupElement = PracticeElement.group(
        id: 'group1',
        x: 5.0,
        y: 5.0,
        width: 400.0,
        height: 300.0,
        layerId: 'layer1',
        children: [textElement, imageElement],
      );

      expect(groupElement.id, 'group1');
      expect(groupElement.x, 5.0);
      expect(groupElement.y, 5.0);
      expect(groupElement.width, 400.0);
      expect(groupElement.height, 300.0);
      expect(groupElement.layerId, 'layer1');
      
      // Test type property
      expect(groupElement.type, 'group');

      // Test serialization
      final map = groupElement.toMap();
      expect(map['id'], 'group1');
      expect(map['type'], 'group');
      expect(map['x'], 5.0);
      expect(map['children'], isA<List>());
      expect(map['children'].length, 2);
      
      // Test deserialization
      final deserializedElement = PracticeElement.fromJson(map);
      expect(deserializedElement, isA<GroupElement>());
      expect(deserializedElement.id, 'group1');
      expect(deserializedElement.x, 5.0);
      expect(deserializedElement.y, 5.0);
      
      // Test children
      final groupElementCast = deserializedElement as GroupElement;
      expect(groupElementCast.children.length, 2);
      expect(groupElementCast.children[0], isA<TextElement>());
      expect(groupElementCast.children[1], isA<ImageElement>());
    });
  });
}
