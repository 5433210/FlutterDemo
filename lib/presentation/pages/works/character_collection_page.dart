import 'dart:math' as Math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../infrastructure/logging/logger.dart';
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
  bool _isImageValid = false;
  String? _imageError;

  @override
  Widget build(BuildContext context) {
    final collectionState = ref.watch(characterCollectionProvider);
    final imageState = ref.watch(workImageProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // 导航栏
            CharacterNavigationBar(
              workId: widget.workId,
              onBack: () => _onBackPressed(),
            ),

            // 主体内容
            Expanded(
              child: Stack(
                children: [
                  if (_isImageValid)
                    Row(
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
                    )
                  else
                    _buildImageErrorState(),

                  // 使用Stack显示加载覆盖层和错误消息
                  if (collectionState.loading ||
                      collectionState.processing ||
                      imageState.loading)
                    const Positioned.fill(child: LoadingOverlay()),

                  // 错误提示
                  if (collectionState.error != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 20,
                      child: _buildErrorMessage(collectionState.error!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // 加载初始数据当页面首次创建时
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  // 构建错误消息显示
  Widget _buildErrorMessage(String error) {
    return Center(
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
    );
  }

  // 显示图像加载错误状态
  Widget _buildImageErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              '无法加载图像',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _imageError ?? '图像数据无效或已损坏',
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              onPressed: _loadInitialData,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回作品详情'),
            ),
          ],
        ),
      ),
    );
  }

  // 检查是否有未保存的修改，显示确认对话框
  Future<bool> _checkUnsavedChanges() async {
    final state = ref.read(characterCollectionProvider);
    final notifier = ref.read(characterCollectionProvider.notifier);

    AppLogger.debug('检查未保存修改状态', data: {
      'hasUnsavedChanges': state.hasUnsavedChanges,
      'modifiedIds': state.modifiedIds.toList(),
      'regionCount': state.regions.length,
      'savedRegionCount': state.regions.where((r) => r.isSaved).length,
      'currentId': state.currentId,
      'isAdjusting': state.isAdjusting,
    });

    // // 如果当前正在调整或者有选中的区域，需要先完成调整
    // if (state.isAdjusting || state.currentId != null) {
    //   notifier.finishCurrentAdjustment();
    //   // 读取更新后的状态
    //   final updatedState = ref.read(characterCollectionProvider);

    //   AppLogger.debug('完成调整后的状态', data: {
    //     'hasUnsavedChanges': updatedState.hasUnsavedChanges,
    //     'modifiedIds': updatedState.modifiedIds.toList(),
    //     'isAdjusting': updatedState.isAdjusting,
    //     'currentId': updatedState.currentId,
    //   });
    // }

    // // 获取最新状态
    // final finalState = ref.read(characterCollectionProvider);

    // // 只有当modifiedIds不为空时才认为有未保存的修改
    // final bool reallyHasUnsavedChanges = finalState.modifiedIds.isNotEmpty;

    // // 检查是否有未保存的修改
    // if (reallyHasUnsavedChanges) {
    if (state.hasUnsavedChanges) {
      // 显示确认对话框
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('未保存的修改'),
          content: const Text('您有未保存的区域修改，离开将丢失这些修改。\n\n是否确定离开？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // 取消
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                // 用户确认离开，清除所有修改标记
                if (state.modifiedIds.isNotEmpty) {
                  final notifier =
                      ref.read(characterCollectionProvider.notifier);
                  for (final id in List.from(state.modifiedIds)) {
                    notifier.markAsSaved(id);
                    AppLogger.debug('强制标记区域为已保存', data: {'regionId': id});
                  }
                }
                Navigator.of(context).pop(true); // 确认离开
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('离开'),
            ),
          ],
        ),
      );

      return result ?? false;
    }

    // 没有未保存的修改，可以直接离开
    return true;
  }

  // 加载字符数据
  Future<void> _loadCharacterData() async {
    try {
      await ref.read(characterCollectionProvider.notifier).loadWorkData(
            widget.workId,
            pageId: widget.initialPageId,
          );
    } catch (e) {
      AppLogger.error('加载字符数据失败',
          tag: 'CharacterCollectionPage',
          error: e,
          data: {'workId': widget.workId, 'pageId': widget.initialPageId});
    }
  }

  // 加载初始数据
  Future<void> _loadInitialData() async {
    setState(() {
      _isImageValid = false;
      _imageError = null;
    });

    try {
      await _loadWorkImage();

      if (_isImageValid) {
        await _loadCharacterData();
      }
    } catch (e) {
      AppLogger.error('加载初始数据失败',
          tag: 'CharacterCollectionPage',
          error: e,
          data: {'workId': widget.workId, 'pageId': widget.initialPageId});
    }
  }

  // 加载作品图像
  Future<void> _loadWorkImage() async {
    try {
      final imageProvider = ref.read(workImageProvider.notifier);
      final imageService = ref.read(workImageServiceProvider);

      // 先尝试获取图像数据
      final imageBytes = await imageService.getWorkPageImage(
          widget.workId, widget.initialPageId);

      if (imageBytes == null || imageBytes.isEmpty) {
        setState(() {
          _isImageValid = false;
          _imageError = '找不到图像数据';
        });
        return;
      }

      // 验证图像数据是否有效
      try {
        // 加载图像前进行验证
        bool isValid = await _validateImageData(imageBytes);

        if (!isValid) {
          setState(() {
            _isImageValid = false;
            _imageError = '图像数据无效或已损坏';
          });
          return;
        }

        // 如果图像有效，加载到状态中
        await imageProvider.loadWorkImage(
          widget.workId,
          widget.initialPageId,
        );

        // 更新字符提取状态
        ref
            .read(characterCollectionProvider.notifier)
            .setCurrentPageImage(imageBytes);

        setState(() {
          _isImageValid = true;
          _imageError = null;
        });
      } catch (e) {
        AppLogger.error('图像验证失败',
            tag: 'CharacterCollectionPage',
            error: e,
            data: {
              'workId': widget.workId,
              'pageId': widget.initialPageId,
              'imageLength': imageBytes.length
            });

        setState(() {
          _isImageValid = false;
          _imageError = '图像数据验证失败: ${e.toString()}';
        });
      }
    } catch (e) {
      AppLogger.error('加载作品图像失败',
          tag: 'CharacterCollectionPage',
          error: e,
          data: {'workId': widget.workId, 'pageId': widget.initialPageId});

      setState(() {
        _isImageValid = false;
        _imageError = '加载图像失败: ${e.toString()}';
      });
    }
  }

  // 处理返回按钮点击
  void _onBackPressed() {
    _checkUnsavedChanges().then((canPop) {
      if (canPop) {
        Navigator.of(context).pop();
      }
    });
  }

  // 检查未保存的修改
  Future<bool> _onWillPop() async {
    return await _checkUnsavedChanges();
  }

  // 验证图像数据是否有效
  Future<bool> _validateImageData(Uint8List imageData) async {
    if (imageData.length < 100) {
      // 图像太小，可能是无效数据
      return false;
    }

    try {
      // 检查图像头信息是否符合常见图像格式
      final header = imageData.sublist(0, Math.min(12, imageData.length));

      // 检查PNG头信息
      if (header.length >= 8 &&
          header[0] == 0x89 &&
          header[1] == 0x50 &&
          header[2] == 0x4E &&
          header[3] == 0x47) {
        return true;
      }

      // 检查JPEG头信息
      if (header.length >= 3 &&
          header[0] == 0xFF &&
          header[1] == 0xD8 &&
          header[2] == 0xFF) {
        return true;
      }

      // 这里可以添加其他图像格式检查

      // 如果没有符合任何已知格式，尝试使用图像服务验证
      final imageProcessor = ref.read(imageProcessorProvider);
      return imageProcessor.validateImageData(imageData);
    } catch (e) {
      AppLogger.error('验证图像数据时出错', tag: 'CharacterCollectionPage', error: e);
      return false;
    }
  }
}
