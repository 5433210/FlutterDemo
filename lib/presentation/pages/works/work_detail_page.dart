import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/work.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../providers/work_detail_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/page_layout.dart';
import 'components/error_view.dart';
import 'components/work_detail_info_panel.dart';
import 'components/work_detail_providers.dart';
import 'components/work_toolbar.dart';

class WorkDetailPage extends ConsumerStatefulWidget {
  final String workId;

  const WorkDetailPage({super.key, required this.workId});

  @override
  ConsumerState<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends ConsumerState<WorkDetailPage> {
  bool _isLoading = false;
  Work? _work;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      navigationInfo: _buildNavigationInfo(),
      actions: _buildActions(),
      body: _buildBody(),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadWork();
  }

  List<Widget> _buildActions() {
    if (_work == null) return [];

    return [
      WorkToolbar(work: _work!),
    ];
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingIndicator(message: '加载作品中...'),
      );
    }

    if (_error != null) {
      return ErrorView(
        error: _error!,
        onRetry: _loadWork,
      );
    }

    if (_work == null) {
      return const Center(
        child: Text('作品不存在或已被删除'),
      );
    }

    return _buildWorkContent(_work!);
  }

  Widget _buildNavigationInfo() {
    return Row(
      children: [
        Text(_work?.name ?? '作品详情'),
        if (_work != null) ...[
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18),
          const SizedBox(width: 8),
          Text('${_work!.style ?? ""} ${_work!.author ?? ""}',
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ],
    );
  }

  Widget _buildWorkContent(Work work) {
    return ProviderScope(
      overrides: [
        currentWorkProvider.overrideWithValue(work),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧图片预览区域 (70%)
          const Expanded(
            flex: 7,
            child: Text('TODO: 图片预览区域'),
          ),

          // 右侧信息面板 (30%)
          Expanded(
            flex: 3,
            child: WorkDetailInfoPanel(work: work),
          ),
        ],
      ),
    );
  }

  Future<void> _loadWork() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final work =
          await ref.read(workDetailProvider.notifier).getWork(widget.workId);
      if (mounted) {
        setState(() {
          _work = work;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('加载作品详情失败',
          tag: 'WorkDetailPage',
          error: e,
          stackTrace: stack,
          data: {'workId': widget.workId});

      if (mounted) {
        setState(() {
          _error = '无法加载作品: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
}
