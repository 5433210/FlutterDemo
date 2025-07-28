import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:charasgem/domain/services/compression_service.dart';
import 'package:charasgem/infrastructure/compression/seven_zip_service.dart';
import 'package:charasgem/infrastructure/integrity/file_integrity_service.dart';

void main() {
  group('SevenZipService Tests', () {
    late SevenZipService sevenZipService;
    late Directory tempDir;

    setUpAll(() async {
      sevenZipService = SevenZipService();
      tempDir = await Directory.systemTemp.createTemp('seven_zip_test_');
    });

    tearDownAll(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('应该能够压缩和解压缩文件', () async {
      // 创建测试文件
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('Hello, 7zip test!');

      final compressedFile = File(path.join(tempDir.path, 'test.cgw'));
      final extractDir = Directory(path.join(tempDir.path, 'extracted'));

      // 压缩文件
      final compressResult = await sevenZipService.compress(
        sourcePath: testFile.path,
        targetPath: compressedFile.path,
      );

      expect(compressResult.success, isTrue);
      expect(await compressedFile.exists(), isTrue);
      expect(compressResult.compressedSize, greaterThan(0));

      // 解压缩文件
      final decompressResult = await sevenZipService.decompress(
        sourcePath: compressedFile.path,
        targetPath: extractDir.path,
      );

      expect(decompressResult.success, isTrue);
      expect(decompressResult.extractedFiles, equals(1));

      // 验证解压缩的文件内容
      final extractedFile = File(path.join(extractDir.path, 'test.txt'));
      expect(await extractedFile.exists(), isTrue);
      final content = await extractedFile.readAsString();
      expect(content, equals('Hello, 7zip test!'));
    });

    test('应该能够验证文件完整性', () async {
      // 创建测试文件
      final testFile = File(path.join(tempDir.path, 'integrity_test.txt'));
      await testFile.writeAsString('Integrity test content');

      final compressedFile = File(path.join(tempDir.path, 'integrity_test.cgc'));

      // 压缩文件
      await sevenZipService.compress(
        sourcePath: testFile.path,
        targetPath: compressedFile.path,
      );

      // 验证压缩文件的完整性
      final integrityResult = await FileIntegrityService.verifyFileIntegrity(
        compressedFile.path,
      );

      expect(integrityResult.isValid, isTrue);
      expect(integrityResult.errors, isEmpty);
      expect(integrityResult.details['fileSize'], greaterThan(0));
      expect(integrityResult.details['sha256'], isNotNull);
      expect(integrityResult.details['md5'], isNotNull);
    });

    test('应该支持不同的文件扩展名', () async {
      final testFile = File(path.join(tempDir.path, 'extension_test.txt'));
      await testFile.writeAsString('Extension test');

      // 测试 .cgw 扩展名
      final cgwFile = File(path.join(tempDir.path, 'test.cgw'));
      final cgwResult = await sevenZipService.compress(
        sourcePath: testFile.path,
        targetPath: cgwFile.path,
      );
      expect(cgwResult.success, isTrue);

      // 测试 .cgc 扩展名
      final cgcFile = File(path.join(tempDir.path, 'test.cgc'));
      final cgcResult = await sevenZipService.compress(
        sourcePath: testFile.path,
        targetPath: cgcFile.path,
      );
      expect(cgcResult.success, isTrue);

      // 测试 .cgb 扩展名
      final cgbFile = File(path.join(tempDir.path, 'test.cgb'));
      final cgbResult = await sevenZipService.compress(
        sourcePath: testFile.path,
        targetPath: cgbFile.path,
      );
      expect(cgbResult.success, isTrue);
    });

    test('应该能够处理目录压缩', () async {
      // 创建测试目录结构
      final testDir = Directory(path.join(tempDir.path, 'test_directory'));
      await testDir.create();

      final subDir = Directory(path.join(testDir.path, 'subdir'));
      await subDir.create();

      final file1 = File(path.join(testDir.path, 'file1.txt'));
      await file1.writeAsString('File 1 content');

      final file2 = File(path.join(subDir.path, 'file2.txt'));
      await file2.writeAsString('File 2 content');

      final compressedFile = File(path.join(tempDir.path, 'directory_test.cgw'));
      final extractDir = Directory(path.join(tempDir.path, 'extracted_dir'));

      // 压缩目录
      final compressResult = await sevenZipService.compress(
        sourcePath: testDir.path,
        targetPath: compressedFile.path,
      );

      expect(compressResult.success, isTrue);

      // 解压缩目录
      final decompressResult = await sevenZipService.decompress(
        sourcePath: compressedFile.path,
        targetPath: extractDir.path,
      );

      expect(decompressResult.success, isTrue);
      expect(decompressResult.extractedFiles, equals(2));

      // 验证解压缩的文件
      final extractedFile1 = File(path.join(extractDir.path, 'file1.txt'));
      final extractedFile2 = File(path.join(extractDir.path, 'subdir', 'file2.txt'));

      expect(await extractedFile1.exists(), isTrue);
      expect(await extractedFile2.exists(), isTrue);

      expect(await extractedFile1.readAsString(), equals('File 1 content'));
      expect(await extractedFile2.readAsString(), equals('File 2 content'));
    });

    test('应该返回支持的压缩格式', () {
      final supportedFormats = sevenZipService.getSupportedFormats();
      expect(supportedFormats, contains(CompressionFormat.sevenZip));
    });

    test('应该能够验证压缩文件完整性', () async {
      final testFile = File(path.join(tempDir.path, 'verify_test.txt'));
      await testFile.writeAsString('Verification test');

      final compressedFile = File(path.join(tempDir.path, 'verify_test.cgw'));

      // 压缩文件
      await sevenZipService.compress(
        sourcePath: testFile.path,
        targetPath: compressedFile.path,
      );

      // 验证完整性
      final isValid = await sevenZipService.verifyIntegrity(compressedFile.path);
      expect(isValid, isTrue);

      // 损坏文件并重新验证
      await compressedFile.writeAsBytes([0, 1, 2, 3, 4]);
      final isValidAfterCorruption = await sevenZipService.verifyIntegrity(compressedFile.path);
      expect(isValidAfterCorruption, isFalse);
    });
  });
}
