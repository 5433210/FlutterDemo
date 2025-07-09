import 'package:flutter_test/flutter_test.dart';

/// 测试拖拽索引调整逻辑
void main() {
  group('拖拽索引调整测试', () {
    test('向后拖拽的索引调整', () {
      // 模拟 Flutter ReorderableListView 的调整逻辑
      int adjustIndex(int oldIndex, int newIndex) {
        if (oldIndex < newIndex) {
          return newIndex - 1;
        }
        return newIndex;
      }
      
      // 测试场景1：从位置0拖拽到位置3
      expect(adjustIndex(0, 3), equals(2));
      
      // 测试场景2：从位置1拖拽到位置4
      expect(adjustIndex(1, 4), equals(3));
      
      // 测试场景3：从位置2拖拽到位置0（向前拖拽）
      expect(adjustIndex(2, 0), equals(0));
      
      // 测试场景4：从位置3拖拽到位置1（向前拖拽）
      expect(adjustIndex(3, 1), equals(1));
    });
    
    test('列表重排序模拟', () {
      // 模拟图片列表
      List<String> images = ['A', 'B', 'C', 'D', 'E'];
      
      // 模拟重排序函数
      List<String> reorderList(List<String> items, int oldIndex, int newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        
        final result = List<String>.from(items);
        final item = result.removeAt(oldIndex);
        result.insert(newIndex, item);
        return result;
      }
      
      // 测试场景1：从位置0拖拽到位置3
      final result1 = reorderList(images, 0, 3);
      expect(result1, equals(['B', 'C', 'A', 'D', 'E']));
      
      // 测试场景2：从位置2拖拽到位置0
      final result2 = reorderList(images, 2, 0);
      expect(result2, equals(['C', 'A', 'B', 'D', 'E']));
      
      // 测试场景3：从位置1拖拽到位置4
      final result3 = reorderList(images, 1, 4);
      expect(result3, equals(['A', 'C', 'D', 'B', 'E']));
    });
  });
}
