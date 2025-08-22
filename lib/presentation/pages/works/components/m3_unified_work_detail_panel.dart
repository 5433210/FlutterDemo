import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/repository_providers.dart';
import '../../../../domain/models/character/character_view.dart';
import '../../../../domain/models/work/work_entity.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../utils/date_formatter.dart';
import '../../../pages/characters/components/m3_character_detail_panel.dart';
import '../../../pages/characters/components/m3_character_grid_view.dart';
import '../../../providers/work_detail_provider.dart';
import '../../../widgets/common/tab_bar_theme_wrapper.dart';
import '../../../widgets/forms/m3_work_form.dart';
import '../../../widgets/tag_editor.dart';

/// Material 3 version of the unified work detail panel
class M3UnifiedWorkDetailPanel extends ConsumerStatefulWidget {
  /// The work entity to display
  final WorkEntity work;

  /// Whether the panel is in editing mode
  final bool isEditing;

  /// Function to toggle favorite status
  final VoidCallback? onToggleFavorite;

  const M3UnifiedWorkDetailPanel({
    super.key,
    required this.work,
    required this.isEditing,
    this.onToggleFavorite,
  });

  @override
  ConsumerState<M3UnifiedWorkDetailPanel> createState() =>
      _M3UnifiedWorkDetailPanelState();
}

class _M3UnifiedWorkDetailPanelState
    extends ConsumerState<M3UnifiedWorkDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final tags = widget.work.tags;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(128),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          TabBarThemeWrapper(
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.basicInfo),
                Tab(text: l10n.tags),
                Tab(text: l10n.workDetailCharacters),
              ],
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(context),
                _buildTagsTab(context, tags),
                _buildCharactersTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(M3UnifiedWorkDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.work != widget.work ||
        oldWidget.isEditing != widget.isEditing) {
      // Log state changes
      AppLogger.debug('M3UnifiedWorkDetailPanel updated',
          tag: 'WorkDetailPanel',
          data: {
            'oldTitle': oldWidget.work.title,
            'newTitle': widget.work.title,
            'oldTagCount': oldWidget.work.tags.length,
            'newTagCount': widget.work.tags.length,
            'isEditingChanged': oldWidget.isEditing != widget.isEditing,
          });

      setState(() {
        // Force update state to reflect new data
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // Additional metadata not included in the form
  Widget _buildAdditionalMetadata(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          l10n.workDetailOtherInfo,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        _buildInfoRow(
            l10n.imageCount, (widget.work.imageCount ?? 0).toString()),
        _buildInfoRow(l10n.createTime, _formatDateTime(widget.work.createTime)),
        _buildInfoRow(l10n.updateTime, _formatDateTime(widget.work.updateTime)),
      ],
    );
  }

  Widget _buildBasicInfoTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      children: [
        // 收藏状态行
        if (!widget.isEditing)
          Row(
            children: [
              const Spacer(),
              IconButton(
                icon: Icon(
                  widget.work.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: widget.work.isFavorite
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
                onPressed: widget.onToggleFavorite,
              ),
            ],
          ), // Use M3WorkForm for both view and edit modes
        M3WorkForm(
          title: AppLocalizations.of(context).basicInfo,
          initialTitle: widget.work.title,
          initialAuthor: widget.work.author,
          initialStyle: widget.work.style,
          initialTool: widget.work.tool,
          initialRemark: widget.work.remark,
          isProcessing: false,
          // Only enable editing in edit mode
          onTitleChanged: widget.isEditing
              ? (value) => _updateWorkField('title', value)
              : null,
          onAuthorChanged: widget.isEditing
              ? (value) => _updateWorkField('author', value)
              : null,
          onStyleChanged: widget.isEditing
              ? (value) => _updateWorkField('style', value)
              : null,
          onToolChanged: widget.isEditing
              ? (value) => _updateWorkField('tool', value)
              : null,
          onRemarkChanged: widget.isEditing
              ? (value) => _updateWorkField('remark', value)
              : null,
          // Configure form appearance
          visibleFields: WorkFormPresets.editFields,
          requiredFields: const {WorkFormField.title},
          showHelp: false,
          showKeyboardShortcuts: false,
        ),

        // Display additional metadata in view mode
        if (!widget.isEditing) ...[
          const SizedBox(height: AppSizes.spacingMedium),
          _buildAdditionalMetadata(context),
        ],
      ],
    );
  }

  Widget _buildCharactersTab(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 添加日志检查集字数量
    AppLogger.debug(
      'Building characters tab',
      tag: 'WorkDetail',
      data: {
        'workId': widget.work.id,
        'collectedCharsCount': widget.work.collectedChars.length,
        'collectedCharIds':
            widget.work.collectedChars.map((c) => c.id).toList(),
      },
    );

    if (widget.work.collectedChars.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingMedium),
          child: Text(l10n.noCharacters),
        ),
      );
    }

    return FutureBuilder<List<CharacterView>>(
      future: () async {
        final repo = ref.read(characterViewRepositoryProvider);
        final charIds = widget.work.collectedChars.map((c) => c.id).toList();

        AppLogger.debug('Loading characters', tag: 'WorkDetail', data: {
          'workId': widget.work.id,
          'charCount': charIds.length,
        });

        final characters = await repo.getCharactersByIds(charIds);

        AppLogger.debug('Character loading complete', tag: 'WorkDetail', data: {
          'workId': widget.work.id,
          'requestedCount': charIds.length,
          'loadedCount': characters.length,
        });

        return characters;
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppSizes.spacingSmall),
                Text(
                  '${l10n.loadFailed}: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final characters = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacingMedium),
              child: Text(
                '${characters.length} ${l10n.characterCollection}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: M3CharacterGridView(
                characters: characters,
                onCharacterTap: (characterId) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 800,
                          maxHeight: 600,
                        ),
                        child: M3CharacterDetailPanel(
                          characterId: characterId,
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  );
                },
                onToggleFavorite: (characterId) async {
                  await ref
                      .read(characterViewRepositoryProvider)
                      .toggleFavorite(characterId);
                  setState(() {}); // 刷新字符列表
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsTab(BuildContext context, List<String> tags) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      child: widget.isEditing
          ? TagEditor(
              tags: tags,
              onTagsChanged: (newTags) => _updateWorkField('tags', newTags),
              readOnly: false,
            )
          : TagEditor(
              tags: tags,
              onTagsChanged:
                  (_) {}, // Dummy function, never called in readOnly mode
              readOnly: true,
            ),
    );
  }

  // Format DateTime for display using localized formatter
  String _formatDateTime(DateTime dateTime) {
    return DateFormatter.formatWithTime(dateTime);
  }

  // Get the current value of a field
  dynamic _getCurrentFieldValue(String field) {
    switch (field) {
      case 'title':
        return widget.work.title;
      case 'author':
        return widget.work.author;
      case 'style':
        return widget.work.style;
      case 'tool':
        return widget.work.tool;
      // TODO: Restore creationDate handling after removing from model
      // case 'creationDate':
      //   return widget.work.creationDate;
      case 'remark':
        return widget.work.remark;
      case 'tags':
        return widget.work.tags;
      default:
        return null;
    }
  }

  void _updateWorkField(String field, dynamic value) {
    final notifier = ref.read(workDetailProvider.notifier);
    final currentValue = _getCurrentFieldValue(field);

    // Log detailed field modification information
    AppLogger.debug('Field modified', tag: 'WorkDetailPanel', data: {
      'field': field,
      'oldValue': field == 'tags'
          ? '${widget.work.tags.length} tags: ${widget.work.tags}'
          : currentValue.toString(),
      'newValue': field == 'tags'
          ? '${(value as List<String>).length} tags: $value'
          : value.toString(),
      'workId': widget.work.id,
      'isChanged': currentValue != value,
    });

    // Update the field in the provider
    if (field == 'tags') {
      notifier.updateWorkTags(value);
    } else {
      // For other fields, use the updateWorkBasicInfo method
      switch (field) {
        case 'title':
          notifier.updateWorkBasicInfo(title: value);
          break;
        case 'author':
          notifier.updateWorkBasicInfo(author: value);
          break;
        case 'style':
          notifier.updateWorkBasicInfo(style: value);
          break;
        case 'tool':
          notifier.updateWorkBasicInfo(tool: value);
          break;
        // TODO: Restore creationDate handling after removing from model
        // case 'creationDate':
        //   notifier.updateWorkBasicInfo(creationDate: value);
        //   break;
        case 'remark':
          notifier.updateWorkBasicInfo(remark: value);
          break;
      }
    }

    // Ensure state is marked as changed
    notifier.markAsChanged();

    // Log the updated state
    Future.microtask(() {
      final updatedState = ref.read(workDetailProvider);
      AppLogger.debug('Field modification complete',
          tag: 'WorkDetailPanel',
          data: {
            'editingWorkTitle': updatedState.editingWork?.title,
            'editingWorkAuthor': updatedState.editingWork?.author,
            'editingWorkStyle': updatedState.editingWork?.style,
            'editingWorkTool': updatedState.editingWork?.tool,
            'editingWorkTagCount': updatedState.editingWork?.tags.length,
            'editingWorkTags': updatedState.editingWork?.tags,
            'hasChanges': updatedState.hasChanges,
          });

      if (mounted) {
        setState(() {});
      }
    });
  }
}
