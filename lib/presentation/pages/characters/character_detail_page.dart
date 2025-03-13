import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../domain/models/character/character_entity.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../providers/character_detail_provider.dart';
import '../../widgets/common/detail_toolbar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/page_layout.dart';

class CharacterDetailPage extends ConsumerStatefulWidget {
  final String charId;
  final VoidCallback? onBack;

  const CharacterDetailPage({
    super.key,
    required this.charId,
    this.onBack,
  });

  @override
  ConsumerState<CharacterDetailPage> createState() =>
      _CharacterDetailPageState();
}

class _CharacterDetailPageState extends ConsumerState<CharacterDetailPage> {
  var _isLoading = false;
  CharacterEntity? _character;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      toolbar: _buildToolbar(),
      body: _buildBody(),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCharacter();
    });
  }

  List<DetailToolbarAction> _buildActions() {
    if (_character == null) return [];

    return [
      DetailToolbarAction(
        icon: Icons.edit,
        tooltip: '编辑字形',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('编辑功能尚未实现')),
          );
        },
      ),
      DetailToolbarAction(
        icon: Icons.image,
        tooltip: '查看原图',
        onPressed: () {
          // Todo: 实现查看原图功能
        },
      ),
      DetailToolbarAction(
        icon: Icons.delete,
        tooltip: '删除字形',
        onPressed: _confirmDelete,
      ),
    ];
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingIndicator(message: '加载字形中...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCharacter,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_character == null) {
      return const Center(
        child: Text('字形不存在或已被删除'),
      );
    }

    return _buildCharacterInfo(_character!);
  }

  Widget _buildCharacterInfo(CharacterEntity character) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio: 1.0,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: Icon(Icons.image_not_supported, size: 64),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('基本信息', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  _buildInfoRow('汉字', character.char),
                  _buildInfoRow('创建时间', _formatDateTime(character.createTime)),
                ],
              ),
            ),
          ),
          if (character.region != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.crop, size: 20),
                        const SizedBox(width: 8),
                        Text('原图区域',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const Divider(),
                    Text(
                      '左: ${character.region?.rect.left}, '
                      '上: ${character.region?.rect.top}, '
                      '宽: ${character.region?.rect.width}, '
                      '高: ${character.region?.rect.height}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return DetailToolbar(
      title: '字形详情',
      leadingIcon: Icons.text_fields,
      badge: _character != null ? DetailBadge(text: _character!.char) : null,
      actions: _buildActions(),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除字形'),
        content: Text('确定要删除字形"${_character!.char}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteCharacter();
    }
  }

  Future<void> _deleteCharacter() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final repository = ref.read(characterRepositoryProvider);
      await repository.delete(widget.charId);
      ref.invalidate(characterDetailProvider);

      if (mounted) {
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to delete character',
        tag: 'CharacterDetailPage',
        error: e,
        stackTrace: stack,
        data: {'id': widget.charId},
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '删除失败: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未知';

    return '${dateTime.year}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadCharacter() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final character =
          await ref.read(characterDetailProvider(widget.charId).future);

      if (mounted) {
        setState(() {
          _character = character;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load character',
        tag: 'CharacterDetailPage',
        error: e,
        stackTrace: stack,
        data: {'id': widget.charId},
      );

      if (mounted) {
        setState(() {
          _errorMessage = '无法加载字形信息: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
}
