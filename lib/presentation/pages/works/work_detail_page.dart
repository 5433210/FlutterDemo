import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../domain/entities/work.dart';
import '../../../domain/enums/work_style.dart';
import '../../../domain/enums/work_tool.dart';
import '../../../theme/app_sizes.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/path_helper.dart';
import '../../dialogs/delete_confirmation_dialog.dart';

class CharacterDetailPage extends StatelessWidget {
  final String charId;
  final VoidCallback onBack;

  const CharacterDetailPage(
      {super.key, required this.charId, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text('字帖详情', style: TextStyle(fontSize: 20)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('字帖 $charId'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkDetailPage extends ConsumerStatefulWidget {
  final String workId;

  const WorkDetailPage({
    super.key,
    required this.workId,
  });

  @override
  ConsumerState<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends ConsumerState<WorkDetailPage> {
  int _currentImageIndex = 0;
  late final PageController _pageController;
  bool _isImageLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ErrorBoundary(
          onError: (error, stack) {
            AppLogger.error(
              'Error in WorkDetailPage',
              error: error,
              stackTrace: stack,
              tag: 'UI',
            );
            return const Center(
              child: Text('抱歉，页面加载出错'),
            );
          },
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final workService = ref.watch(workServiceProvider);

    // 不要创建新的Scaffold，而是直接返回内容部分
    return FutureBuilder<Work?>(
      future: workService.getWork(widget.workId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('加载出错: ${snapshot.error}'));
        }

        final work = snapshot.data;
        if (work == null) {
          return const Center(child: Text('找不到指定作品'));
        }

        return _buildWorkDetail(context, work);
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  // 修改工具栏为详情特定的工具栏，保留操作按钮
  Widget _buildDetailToolbar(BuildContext context, Work work) {
    final theme = Theme.of(context);

    return Container(
      height: AppSizes.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回作品列表',
            onPressed: () => Navigator.of(context).pop(),
          ),

          const SizedBox(width: AppSizes.m),

          // 作品标题
          Expanded(
            child: Text(
              work.name ?? '未命名作品',
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 操作按钮
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '编辑作品',
            onPressed: () => _editWork(context),
          ),
          IconButton(
            icon: const Icon(Icons.content_cut),
            tooltip: '集字',
            onPressed: () => _extractCharacters(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '删除作品',
            onPressed: () => _confirmDelete(context),
          ),

          const SizedBox(width: AppSizes.xs),

          // 图像操作按钮
          const VerticalDivider(width: 1, indent: 8, endIndent: 8),

          const SizedBox(width: AppSizes.xs),

          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: '放大',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: '缩小',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: '适应屏幕',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(String workId, int index) {
    return FutureBuilder<String?>(
      future: PathHelper.getWorkImagePath(workId, index),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          setState(() => _isImageLoading = true);
          return const SizedBox.shrink();
        }

        setState(() => _isImageLoading = false);

        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('图片加载失败'));
        }

        final imagePath = snapshot.data!;
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview(Work work) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 图片翻页视图
        PageView.builder(
          controller: _pageController,
          itemCount: work.imageCount ?? 0,
          onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
          itemBuilder: (context, index) {
            return _buildImageItem(work.id!, index);
          },
        ),

        // 加载指示器
        if (_isImageLoading) const Center(child: CircularProgressIndicator()),

        // 左右翻页按钮
        if ((work.imageCount ?? 0) > 1) ...[
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _buildPageButton(Icons.chevron_left, () {
              if (_currentImageIndex > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _buildPageButton(Icons.chevron_right, () {
              if (_currentImageIndex < (work.imageCount ?? 0) - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<Widget> content, {
    bool showActions = false,
    List<Widget>? actions,
  }) {
    return Card(
      elevation: AppSizes.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (showActions && actions != null) ...actions,
              ],
            ),
            const Divider(height: AppSizes.l),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: AppSizes.s),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSidebar(BuildContext context, Work work) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本信息卡片
          _buildInfoCard(
            context,
            '基本信息',
            [
              _buildInfoItem(context, '名称', work.name ?? '未命名作品'),
              _buildInfoItem(context, '作者', work.author ?? '未知'),
              _buildInfoItem(context, '风格',
                  WorkStyle.fromValue(work.style)?.label ?? work.style ?? '未知'),
              _buildInfoItem(context, '工具',
                  WorkTool.fromValue(work.tool)?.label ?? work.tool ?? '未知'),
              _buildInfoItem(
                  context,
                  '创作日期',
                  work.creationDate != null
                      ? DateFormatter.formatFull(work.creationDate!)
                      : '未知'),
            ],
          ),

          const SizedBox(height: AppSizes.m),

          // 采集信息卡片
          _buildInfoCard(
            context,
            '采集信息',
            [
              _buildInfoItem(context, '已采集字数', '0'),
              // 这里可以添加更多采集信息
            ],
            showActions: true,
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.content_cut),
                label: const Text('进入集字'),
                onPressed: () => _extractCharacters(context),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.m),

          // 系统信息卡片
          _buildInfoCard(
            context,
            '系统信息',
            [
              _buildInfoItem(context, '图片数量', '${work.imageCount ?? 0} 张'),
              _buildInfoItem(
                  context,
                  '导入时间',
                  work.createTime != null
                      ? DateFormatter.formatWithTime(work.createTime!)
                      : '未知'),
              _buildInfoItem(
                  context,
                  '最后修改',
                  work.updateTime != null
                      ? DateFormatter.formatWithTime(work.updateTime!)
                      : '未知'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, Work work, int imageCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 图片预览区域
        Expanded(
          child: imageCount > 0
              ? _buildImagePreview(work)
              : const Center(child: Text('没有图片')),
        ),

        // 缩略图栏
        if (imageCount > 1)
          SizedBox(
            height: 100,
            child: _buildThumbnailStrip(work, imageCount),
          ),
      ],
    );
  }

  Widget _buildPageButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailItem(Work work, int index) {
    final isSelected = index == _currentImageIndex;

    return GestureDetector(
      onTap: () {
        setState(() => _currentImageIndex = index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 120,
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: FutureBuilder<String?>(
          // 此处使用更具体的命名
          future: PathHelper.getWorkImageThumbnailPath(work.id!, index),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              // 如果没有专用缩略图，尝试使用原图（这会很慢，但至少可以显示）
              return FutureBuilder<String?>(
                future: PathHelper.getWorkImagePath(work.id!, index),
                builder: (context, imgSnapshot) {
                  if (imgSnapshot.hasData) {
                    return Image.file(File(imgSnapshot.data!),
                        fit: BoxFit.cover);
                  }
                  return Container(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.broken_image)),
                  );
                },
              );
            }

            final thumbnailPath = snapshot.data!;
            return Image.file(
              File(thumbnailPath),
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip(Work work, int imageCount) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.s,
        horizontal: AppSizes.m,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageCount,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.s),
        itemBuilder: (context, index) {
          return _buildThumbnailItem(work, index);
        },
      ),
    );
  }

  Widget _buildWorkDetail(BuildContext context, Work work) {
    final imageCount = work.imageCount ?? 0;

    return Column(
      children: [
        // 详情页工具栏
        _buildDetailToolbar(context, work),

        // 主要内容区域
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 主要内容区域 (70%)
              Expanded(
                flex: 7,
                child: _buildMainContent(context, work, imageCount),
              ),

              // 分隔线
              const VerticalDivider(width: 1),

              // 信息侧边栏 (30%)
              Expanded(
                flex: 3,
                child: _buildInfoSidebar(context, work),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );

    if (confirmed == true) {
      _deleteWork(context);
    }
  }

  void _deleteWork(BuildContext context) async {
    try {
      final workService = ref.read(workServiceProvider);
      await workService.deleteWork(widget.workId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('作品已删除')),
      );

      // 删除后直接返回列表页
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  // 操作方法
  void _editWork(BuildContext context) {
    // 实现编辑功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能待实现')),
    );
  }

  void _extractCharacters(BuildContext context) {
    // 实现集字功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('集字功能待实现')),
    );
  }
}

// Error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace) onError;

  const ErrorBoundary({
    super.key, 
    required this.child,
    required this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.onError(_error!, _stackTrace!);
    }

    return ErrorWidget.builder = (details) {
      _error = details.exception;
      _stackTrace = details.stack;
      return widget.onError(details.exception, details.stack);
    }
    
    return widget.child;
  }
}
