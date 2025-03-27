import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/work_image_provider.dart';
import '../../widgets/character_collection/image_preview_panel.dart';
import '../../widgets/character_collection/navigation_bar.dart';
import '../../widgets/character_collection/right_panel.dart';

class CharacterCollectionPage extends ConsumerStatefulWidget {
  final String workId;
  final String initialPageId;

  const CharacterCollectionPage({
    Key? key,
    required this.workId,
    required this.initialPageId,
  }) : super(key: key);

  @override
  ConsumerState<CharacterCollectionPage> createState() =>
      _CharacterCollectionPageState();
}

// 加载覆盖层组件 (已存在但为完整性添加)
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('处理中...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterCollectionPageState
    extends ConsumerState<CharacterCollectionPage> {
  @override
  Widget build(BuildContext context) {
    final collectionState = ref.watch(characterCollectionProvider);
    final imageState = ref.watch(workImageProvider);

    return Scaffold(
      body: Column(
        children: [
          // 导航栏
          CharacterNavigationBar(
            workId: widget.workId,
            onBack: () => Navigator.of(context).pop(),
          ),

          // 主体内容
          Expanded(
            child: Row(
              children: [
                // 左侧图片预览区
                const Expanded(
                  flex: 6,
                  child: ImagePreviewPanel(),
                ),

                // 右侧面板
                Expanded(
                  flex: 4,
                  child: RightPanel(workId: widget.workId),
                ),
              ],
            ),
          ),

          // 使用Stack显示加载覆盖层和错误消息
          if (collectionState.loading ||
              collectionState.processing ||
              imageState.loading)
            const LoadingOverlay(),

          // 错误提示
          if (collectionState.error != null)
            _buildErrorMessage(collectionState.error!),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // 加载初始数据当页面首次创建时
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkImage();
      _loadCharacterData();
    });
  }

  // 构建错误消息显示
  Widget _buildErrorMessage(String error) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.red.shade800,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '错误: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  // 加载字符数据
  Future<void> _loadCharacterData() async {
    await ref.read(characterCollectionProvider.notifier).loadWorkData(
          widget.workId,
          pageId: widget.initialPageId,
        );
  }

  // 加载作品图像
  Future<void> _loadWorkImage() async {
    await ref.read(workImageProvider.notifier).loadWorkImage(
          widget.workId,
          widget.initialPageId,
        );
  }
}
