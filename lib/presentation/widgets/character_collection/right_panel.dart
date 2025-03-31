import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:demo/domain/models/character/character_region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../application/services/image/character_image_processor.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../widgets/character_edit/character_edit_panel.dart';
import '../../providers/character/selected_region_provider.dart';
import '../../providers/character/work_image_provider.dart';
import 'character_grid_view.dart';

class RightPanel extends ConsumerStatefulWidget {
  final String workId;

  const RightPanel({
    Key? key,
    required this.workId,
  }) : super(key: key);

  @override
  ConsumerState<RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends ConsumerState<RightPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  ui.Image? _characterImage;

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(workImageProvider);
    final selectedRegion = ref.watch(selectedRegionProvider);

    return Column(
      children: [
        // 标签栏
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '集字效果预览'),
              Tab(text: '作品集字结果'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        ),

        // 标签内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 标签1: 集字效果预览
              Builder(
                builder: (context) {
                  // 如果没有选择区域或图像未加载，显示提示
                  if (selectedRegion == null) {
                    return const Center(
                      child: Text(
                        '请在左侧预览区选择字符区域',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // 获取选定区域的图像部分
                  return FutureBuilder<ui.Image>(
                    future: _getSelectedRegionImage(
                        selectedRegion, imageState.imageData),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(
                          child: Text(
                            '处理选中区域失败: ${snapshot.error ?? "未知错误"}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else {
                        // 处理选中区域成功，显示编辑面板
                        return Center(
                          // 将裁剪后的图像传递给 CharacterEditPanel
                          child: _buildCharacterEditor(snapshot.data!),
                        );
                      }
                    },
                  );
                },
              ),

              // 标签2: 作品集字结果
              CharacterGridView(
                workId: widget.workId,
                onCharacterSelected: (id) async {
                  _tabController.animateTo(0);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _characterImage?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget _buildCharacterEditor(ui.Image image) {
    return CharacterEditPanel(
      image: image,
      onEditComplete: (p0) {
        // 处理编辑完成的回调
        // 例如：保存编辑结果、更新UI等
      },
    );
  }

  // 裁剪选定区域的图像

  Future<ui.Image> _getSelectedRegionImage(
      CharacterRegion region, Uint8List? imageData) async {
    if (imageData == null) {
      throw Exception('No image data available');
    }

    const processingOptions = ProcessingOptions(
      inverted: false,
      threshold: 128.0,
      noiseReduction: 0.5,
      showContour: false,
    );
    final preview = await ref
        .read(characterImageProcessorProvider)
        .previewProcessing(imageData, region.rect, processingOptions, null);

    // 将 img.Image 转换为字节数据，然后创建 Flutter Image
    final bytes = Uint8List.fromList(img.encodePng(preview.processedImage));

    // 创建一个 Completer 来处理异步图像解码
    final completer = Completer<ui.Image>();

    // 解码图像数据
    ui.decodeImageFromList(bytes, (result) {
      completer.complete(result);
    });

    return completer.future;
  }
}
