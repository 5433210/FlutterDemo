import 'package:demo/application/repositories/work_image_repository_impl.dart';
import 'package:demo/domain/models/work/work_image.dart';
import 'package:demo/infrastructure/persistence/sqlite/sqlite_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('图片顺序调整测试', () {
    late WorkImageRepositoryImpl repository;
    late SQLiteDatabase database;
    const testWorkId = 'test-work-id';

    setUp(() async {
      // 这里需要初始化数据库
      // database = await SQLiteDatabase.initialize(':memory:');
      // repository = WorkImageRepositoryImpl(database);
    });

    test('调整图片顺序后应该正确保存到数据库', () async {
      // 创建测试数据
      final images = [
        WorkImage(
          id: 'image-1',
          workId: testWorkId,
          path: '/path/to/image1.jpg',
          originalPath: '/path/to/image1.jpg',
          thumbnailPath: '/path/to/thumb1.jpg',
          format: 'jpg',
          size: 1024,
          width: 800,
          height: 600,
          index: 0,
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
        WorkImage(
          id: 'image-2',
          workId: testWorkId,
          path: '/path/to/image2.jpg',
          originalPath: '/path/to/image2.jpg',
          thumbnailPath: '/path/to/thumb2.jpg',
          format: 'jpg',
          size: 2048,
          width: 1200,
          height: 800,
          index: 1,
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
      ];

      // 先保存原始顺序
      await repository.saveMany(images);

      // 验证原始顺序
      final originalImages = await repository.getAllByWorkId(testWorkId);
      expect(originalImages.length, 2);
      expect(originalImages[0].id, 'image-1');
      expect(originalImages[1].id, 'image-2');

      // 调整顺序
      final reorderedImages = [
        images[1].copyWith(index: 0, updateTime: DateTime.now()),
        images[0].copyWith(index: 1, updateTime: DateTime.now()),
      ];

      // 保存调整后的顺序
      await repository.saveMany(reorderedImages);

      // 验证调整后的顺序
      final reorderedResult = await repository.getAllByWorkId(testWorkId);
      expect(reorderedResult.length, 2);
      expect(reorderedResult[0].id, 'image-2');
      expect(reorderedResult[0].index, 0);
      expect(reorderedResult[1].id, 'image-1');
      expect(reorderedResult[1].index, 1);
    });
  });
}
