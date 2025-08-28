import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:charasgem/presentation/widgets/practice/property_panels/image/image_data_save_strategy.dart';
import 'package:charasgem/presentation/widgets/practice/property_panels/image/image_data_load_strategy.dart';

void main() {
  group('ImageDataSaveStrategy', () {
    test('should save binarized data when binarization enabled', () {
      // Arrange
      final testImageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final content = {
        'imageUrl': 'file://path/to/test.png',
        'rawImageData': Uint8List.fromList([10, 20, 30, 40, 50]),
        'transformedImageData': Uint8List.fromList([6, 7, 8, 9, 10]),
        'binarizedImageData': testImageData,
        'isBinarizationEnabled': true,
        'isTransformApplied': true,
        'binaryThreshold': 150,
        'isNoiseReductionEnabled': true,
        'noiseReductionLevel': 2,
        'cropX': 10.0,
        'cropY': 20.0,
        'cropWidth': 800.0,
        'cropHeight': 600.0,
        'rotation': 15.0,
        'fitMode': 'contain',
        'opacity': 0.8,
      };

      // Act
      final result = ImageDataSaveStrategy.prepareImageDataForSave(content);

      // Assert
      expect(result['finalImageData'], equals(testImageData));
      expect(result['finalImageDataSource'], equals('binarizedImageData'));
      expect(result['processingMetadata']['hasBinarizationApplied'], isTrue);
      expect(result['processingMetadata']['hasTransformApplied'], isTrue);
      expect(result['processingMetadata']['binaryThreshold'], equals(150));
      expect(result['processingMetadata']['cropX'], equals(10.0));
      expect(result['processingMetadata']['rotation'], equals(15.0));

      // 中间数据应该被清理
      expect(result['rawImageData'], isNull);
      expect(result['transformedImageData'], isNull);
      expect(result['binarizedImageData'], isNull);

      // UI属性应该保留
      expect(result['fitMode'], equals('contain'));
      expect(result['opacity'], equals(0.8));
    });

    test('should save transformed data when only transform applied', () {
      // Arrange
      final testImageData = Uint8List.fromList([6, 7, 8, 9, 10]);
      final content = {
        'imageUrl': 'file://path/to/test.png',
        'rawImageData': Uint8List.fromList([10, 20, 30, 40, 50]),
        'transformedImageData': testImageData,
        'isTransformApplied': true,
        'isBinarizationEnabled': false,
        'cropX': 50.0,
        'cropY': 100.0,
        'cropWidth': 600.0,
        'cropHeight': 400.0,
        'rotation': 30.0,
      };

      // Act
      final result = ImageDataSaveStrategy.prepareImageDataForSave(content);

      // Assert
      expect(result['finalImageData'], equals(testImageData));
      expect(result['finalImageDataSource'], equals('transformedImageData'));
      expect(result['processingMetadata']['hasTransformApplied'], isTrue);
      expect(result['processingMetadata']['hasBinarizationApplied'], isFalse);
      expect(result['processingMetadata']['cropX'], equals(50.0));
      expect(result['processingMetadata']['cropY'], equals(100.0));
      expect(result['processingMetadata']['rotation'], equals(30.0));

      // 中间数据应该被清理
      expect(result['rawImageData'], isNull);
      expect(result['transformedImageData'], isNull);
    });

    test('should save raw data when no processing applied', () {
      // Arrange
      final testImageData = Uint8List.fromList([10, 20, 30, 40, 50]);
      final content = {
        'imageUrl': 'file://path/to/test.png',
        'rawImageData': testImageData,
        'isTransformApplied': false,
        'isBinarizationEnabled': false,
      };

      // Act
      final result = ImageDataSaveStrategy.prepareImageDataForSave(content);

      // Assert
      expect(result['finalImageData'], equals(testImageData));
      expect(result['finalImageDataSource'], equals('rawImageData'));
      expect(result['processingMetadata']['hasTransformApplied'], isFalse);
      expect(result['processingMetadata']['hasBinarizationApplied'], isFalse);

      // 中间数据应该被清理
      expect(result['rawImageData'], isNull);
    });

    test('should save base64 data when only base64 available', () {
      // Arrange
      const testBase64Data = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
      final content = {
        'imageUrl': 'file://path/to/test.png',
        'base64ImageData': testBase64Data,
        'isTransformApplied': false,
        'isBinarizationEnabled': false,
      };

      // Act
      final result = ImageDataSaveStrategy.prepareImageDataForSave(content);

      // Assert
      expect(result['finalImageData'], equals(testBase64Data));
      expect(result['finalImageDataSource'], equals('base64ImageData'));
      expect(result['processingMetadata']['hasTransformApplied'], isFalse);
      expect(result['processingMetadata']['hasBinarizationApplied'], isFalse);

      // 中间数据应该被清理
      expect(result['base64ImageData'], isNull);
    });

    test('should return original content when no valid image data', () {
      // Arrange
      final content = {
        'imageUrl': 'file://path/to/test.png',
        'fitMode': 'contain',
        'opacity': 0.5,
      };

      // Act
      final result = ImageDataSaveStrategy.prepareImageDataForSave(content);

      // Assert - 应该返回原始内容，不做修改
      expect(result, equals(content));
      expect(result['finalImageData'], isNull);
      expect(result['finalImageDataSource'], isNull);
    });

    test('should validate save data correctly', () {
      // Arrange - 有效数据
      final validContent = {
        'finalImageData': Uint8List.fromList([1, 2, 3]),
        'finalImageDataSource': 'binarizedImageData',
        'processingMetadata': {
          'hasTransformApplied': true,
          'hasBinarizationApplied': true,
        },
      };

      // Act & Assert
      expect(ImageDataSaveStrategy.validateSaveData(validContent), isTrue);

      // Arrange - 无效数据（缺少图像数据）
      final invalidContent1 = {
        'finalImageDataSource': 'binarizedImageData',
        'processingMetadata': {},
      };
      expect(ImageDataSaveStrategy.validateSaveData(invalidContent1), isFalse);

      // Arrange - 无效数据（缺少数据源）
      final invalidContent2 = {
        'finalImageData': Uint8List.fromList([1, 2, 3]),
        'processingMetadata': {},
      };
      expect(ImageDataSaveStrategy.validateSaveData(invalidContent2), isFalse);

      // Arrange - 无效数据（空图像数据）
      final invalidContent3 = {
        'finalImageData': Uint8List.fromList([]),
        'finalImageDataSource': 'binarizedImageData',
        'processingMetadata': {},
      };
      expect(ImageDataSaveStrategy.validateSaveData(invalidContent3), isFalse);
    });
  });

  group('ImageDataLoadStrategy', () {
    test('should restore binarized state correctly', () {
      // Arrange
      final testImageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final savedContent = {
        'finalImageData': testImageData,
        'finalImageDataSource': 'binarizedImageData',
        'processingMetadata': {
          'hasBinarizationApplied': true,
          'hasTransformApplied': true,
          'binaryThreshold': 150,
          'isNoiseReductionEnabled': true,
          'noiseReductionLevel': 2,
          'cropX': 10.0,
          'cropY': 20.0,
          'cropWidth': 800.0,
          'cropHeight': 600.0,
          'rotation': 15.0,
          'originalImageUrl': 'file://path/to/original.png',
        },
        'fitMode': 'contain',
        'opacity': 0.8,
      };

      // Act
      final result = ImageDataLoadStrategy.restoreImageDataFromSave(savedContent);

      // Assert
      expect(result['binarizedImageData'], equals(testImageData));
      expect(result['isBinarizationEnabled'], isTrue);
      expect(result['isTransformApplied'], isTrue);
      expect(result['binaryThreshold'], equals(150));
      expect(result['isNoiseReductionEnabled'], isTrue);
      expect(result['noiseReductionLevel'], equals(2));
      expect(result['cropX'], equals(10.0));
      expect(result['cropY'], equals(20.0));
      expect(result['rotation'], equals(15.0));

      // 编辑能力
      expect(result['canAdjustBinarization'], isTrue);
      expect(result['canRevertToTransform'], isTrue);
      expect(result['canRevertToOriginal'], isTrue);
      expect(result['isEditingMode'], isTrue);

      // UI属性应该保留
      expect(result['fitMode'], equals('contain'));
      expect(result['opacity'], equals(0.8));

      // 临时数据应该被清理
      expect(result['finalImageData'], isNull);
      expect(result['finalImageDataSource'], isNull);
      expect(result['processingMetadata'], isNull);
    });

    test('should restore transform state correctly', () {
      // Arrange
      final testImageData = Uint8List.fromList([6, 7, 8, 9, 10]);
      final savedContent = {
        'finalImageData': testImageData,
        'finalImageDataSource': 'transformedImageData',
        'processingMetadata': {
          'hasTransformApplied': true,
          'hasBinarizationApplied': false,
          'cropX': 50.0,
          'cropY': 100.0,
          'cropWidth': 600.0,
          'cropHeight': 400.0,
          'rotation': 30.0,
        },
      };

      // Act
      final result = ImageDataLoadStrategy.restoreImageDataFromSave(savedContent);

      // Assert
      expect(result['transformedImageData'], equals(testImageData));
      expect(result['isTransformApplied'], isTrue);
      expect(result['cropX'], equals(50.0));
      expect(result['cropY'], equals(100.0));
      expect(result['cropWidth'], equals(600.0));
      expect(result['cropHeight'], equals(400.0));
      expect(result['rotation'], equals(30.0));

      // 编辑能力
      expect(result['canAdjustTransform'], isTrue);
      expect(result['canApplyBinarization'], isTrue);
      expect(result['canRevertToOriginal'], isTrue);
    });

    test('should restore raw state correctly', () {
      // Arrange
      final testImageData = Uint8List.fromList([10, 20, 30, 40, 50]);
      final savedContent = {
        'finalImageData': testImageData,
        'finalImageDataSource': 'rawImageData',
        'processingMetadata': {
          'hasTransformApplied': false,
          'hasBinarizationApplied': false,
        },
      };

      // Act
      final result = ImageDataLoadStrategy.restoreImageDataFromSave(savedContent);

      // Assert
      expect(result['rawImageData'], equals(testImageData));

      // 编辑能力（完全可编辑）
      expect(result['canAdjustTransform'], isTrue);
      expect(result['canApplyBinarization'], isTrue);
      expect(result['canRevertToOriginal'], isTrue);
    });

    test('should restore base64 state correctly', () {
      // Arrange
      const testBase64Data = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
      final savedContent = {
        'finalImageData': testBase64Data,
        'finalImageDataSource': 'base64ImageData',
        'processingMetadata': {
          'hasTransformApplied': false,
          'hasBinarizationApplied': false,
        },
      };

      // Act
      final result = ImageDataLoadStrategy.restoreImageDataFromSave(savedContent);

      // Assert
      expect(result['base64ImageData'], equals(testBase64Data));

      // 编辑能力（完全可编辑）
      expect(result['canAdjustTransform'], isTrue);
      expect(result['canApplyBinarization'], isTrue);
      expect(result['canRevertToOriginal'], isTrue);
    });

    test('should throw exception when image data missing', () {
      // Arrange
      final savedContent = {
        'finalImageDataSource': 'binarizedImageData',
        'processingMetadata': {},
      };

      // Act & Assert
      expect(
        () => ImageDataLoadStrategy.restoreImageDataFromSave(savedContent),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when data source missing', () {
      // Arrange
      final savedContent = {
        'finalImageData': Uint8List.fromList([1, 2, 3]),
        'processingMetadata': {},
      };

      // Act & Assert
      expect(
        () => ImageDataLoadStrategy.restoreImageDataFromSave(savedContent),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for unknown data source', () {
      // Arrange
      final savedContent = {
        'finalImageData': Uint8List.fromList([1, 2, 3]),
        'finalImageDataSource': 'unknownDataSource',
        'processingMetadata': {},
      };

      // Act & Assert
      expect(
        () => ImageDataLoadStrategy.restoreImageDataFromSave(savedContent),
        throwsA(isA<Exception>()),
      );
    });

    test('should validate restored data correctly', () {
      // Arrange - 有效数据
      final validContent = {
        'binarizedImageData': Uint8List.fromList([1, 2, 3]),
        'isEditingMode': true,
      };

      // Act & Assert
      expect(ImageDataLoadStrategy.validateRestoredData(validContent), isTrue);

      // Arrange - 无效数据（无图像数据）
      final invalidContent1 = {
        'isEditingMode': true,
      };
      expect(ImageDataLoadStrategy.validateRestoredData(invalidContent1), isFalse);

      // Arrange - 无效数据（编辑模式未设置）
      final invalidContent2 = {
        'binarizedImageData': Uint8List.fromList([1, 2, 3]),
      };
      expect(ImageDataLoadStrategy.validateRestoredData(invalidContent2), isFalse);
    });
  });

  group('Integration Tests', () {
    test('complete save and load cycle should preserve data integrity', () {
      // Arrange - 创建完整的图像元素内容
      final originalContent = {
        'imageUrl': 'file://path/to/test.png',
        'rawImageData': Uint8List.fromList([10, 20, 30, 40, 50]),
        'transformedImageData': Uint8List.fromList([6, 7, 8, 9, 10]),
        'binarizedImageData': Uint8List.fromList([1, 2, 3, 4, 5]),
        'isBinarizationEnabled': true,
        'isTransformApplied': true,
        'binaryThreshold': 120,
        'isNoiseReductionEnabled': false,
        'noiseReductionLevel': 3,
        'cropX': 25.0,
        'cropY': 50.0,
        'cropWidth': 700.0,
        'cropHeight': 500.0,
        'rotation': 45.0,
        'fitMode': 'cover',
        'opacity': 0.9,
        'backgroundColor': '#FF0000',
      };

      // Act - 保存和加载循环
      final savedContent = ImageDataSaveStrategy.prepareImageDataForSave(originalContent);
      final restoredContent = ImageDataLoadStrategy.restoreImageDataFromSave(savedContent);

      // Assert - 验证关键数据完整性
      expect(restoredContent['binarizedImageData'], equals(originalContent['binarizedImageData']));
      expect(restoredContent['isBinarizationEnabled'], equals(originalContent['isBinarizationEnabled']));
      expect(restoredContent['isTransformApplied'], equals(originalContent['isTransformApplied']));
      expect(restoredContent['binaryThreshold'], equals(originalContent['binaryThreshold']));
      expect(restoredContent['isNoiseReductionEnabled'], equals(originalContent['isNoiseReductionEnabled']));
      expect(restoredContent['noiseReductionLevel'], equals(originalContent['noiseReductionLevel']));
      expect(restoredContent['cropX'], equals(originalContent['cropX']));
      expect(restoredContent['cropY'], equals(originalContent['cropY']));
      expect(restoredContent['cropWidth'], equals(originalContent['cropWidth']));
      expect(restoredContent['cropHeight'], equals(originalContent['cropHeight']));
      expect(restoredContent['rotation'], equals(originalContent['rotation']));

      // UI属性应该保留
      expect(restoredContent['fitMode'], equals(originalContent['fitMode']));
      expect(restoredContent['opacity'], equals(originalContent['opacity']));
      expect(restoredContent['backgroundColor'], equals(originalContent['backgroundColor']));

      // 编辑能力应该正确设置
      expect(restoredContent['canAdjustBinarization'], isTrue);
      expect(restoredContent['canRevertToTransform'], isTrue);
      expect(restoredContent['canRevertToOriginal'], isTrue);
      expect(restoredContent['isEditingMode'], isTrue);
    });

    test('should handle different processing states correctly', () {
      // 测试场景1：仅原始数据
      final rawOnlyContent = {
        'rawImageData': Uint8List.fromList([1, 2, 3]),
        'isTransformApplied': false,
        'isBinarizationEnabled': false,
      };
      
      final savedRaw = ImageDataSaveStrategy.prepareImageDataForSave(rawOnlyContent);
      final restoredRaw = ImageDataLoadStrategy.restoreImageDataFromSave(savedRaw);
      
      expect(restoredRaw['rawImageData'], equals(rawOnlyContent['rawImageData']));
      expect(restoredRaw['canAdjustTransform'], isTrue);
      expect(restoredRaw['canApplyBinarization'], isTrue);

      // 测试场景2：仅变换数据
      final transformOnlyContent = {
        'transformedImageData': Uint8List.fromList([4, 5, 6]),
        'isTransformApplied': true,
        'isBinarizationEnabled': false,
        'cropX': 10.0,
        'cropY': 20.0,
        'cropWidth': 100.0,
        'cropHeight': 200.0,
      };
      
      final savedTransform = ImageDataSaveStrategy.prepareImageDataForSave(transformOnlyContent);
      final restoredTransform = ImageDataLoadStrategy.restoreImageDataFromSave(savedTransform);
      
      expect(restoredTransform['transformedImageData'], equals(transformOnlyContent['transformedImageData']));
      expect(restoredTransform['isTransformApplied'], isTrue);
      expect(restoredTransform['canAdjustTransform'], isTrue);
      expect(restoredTransform['canApplyBinarization'], isTrue);
    });
  });
}