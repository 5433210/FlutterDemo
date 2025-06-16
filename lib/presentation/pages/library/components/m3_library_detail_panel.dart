import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/library_category.dart';
import '../../../../domain/entities/library_item.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../presentation/providers/library/library_management_provider.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../utils/file_size_formatter.dart';

/// 图库详情面板
class M3LibraryDetailPanel extends ConsumerStatefulWidget {
  final LibraryItem item;

  const M3LibraryDetailPanel({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<M3LibraryDetailPanel> createState() =>
      _M3LibraryDetailPanelState();
}

class _M3LibraryDetailPanelState extends ConsumerState<M3LibraryDetailPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _tagsController;
  late TextEditingController _remarksController;

  // State for editing
  late String _selectedType;
  late bool _isFavorite;
  List<String> _selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(libraryManagementProvider).categories;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FractionallySizedBox(
          widthFactor: 1.0,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: const RoundedRectangleBorder(),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 标题栏
                  Container(
                    padding: const EdgeInsets.all(AppSizes.spacing16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.detail,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (_isEditing) ...[
                          IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: _saveChanges,
                            tooltip: l10n.save,
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: _cancelEditing,
                            tooltip: l10n.cancel,
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _startEditing,
                            tooltip: l10n.edit,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 内容区域
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSizes.spacing16),
                      children: [
                        // 基本信息
                        _buildSection(
                          l10n.basicInfo,
                          [
                            if (_isEditing)
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: l10n.name,
                                  isDense: true,
                                ),
                              )
                            else
                              _buildInfoRow(
                                l10n.name,
                                widget.item.fileName,
                                selectable: true,
                              ),
                            const SizedBox(height: AppSizes.spacing8),
                            if (_isEditing) ...[
                              _buildEditTypeRow(theme, l10n),
                              _buildEditFavoriteRow(theme, l10n),
                            ] else ...[
                              _buildInfoRow(
                                l10n.type,
                                widget.item.type,
                              ),
                              _buildInfoRow(
                                l10n.favorite,
                                widget.item.isFavorite ? l10n.yes : l10n.no,
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: AppSizes.spacing16),

                        // 分类组
                        _buildSection(
                          l10n.categories,
                          [
                            if (_isEditing)
                              Wrap(
                                spacing: AppSizes.spacing8,
                                children: categories.map((category) {
                                  final isSelected =
                                      _selectedCategories.contains(category.id);
                                  return FilterChip(
                                    label: Text(category.name),
                                    selected: isSelected,
                                    showCheckmark: true,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedCategories.add(category.id);
                                        } else {
                                          _selectedCategories
                                              .remove(category.id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              )
                            else if (widget.item.categories.isNotEmpty)
                              Wrap(
                                spacing: AppSizes.spacing8,
                                children:
                                    widget.item.categories.map((categoryId) {
                                  final category = categories.firstWhere(
                                    (c) => c.id == categoryId,
                                    orElse: () => LibraryCategory(
                                      id: categoryId,
                                      name: l10n.unknownCategory,
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    ),
                                  );
                                  return InkWell(
                                    onTap: () {
                                      // Make empty since we don't want any action on tap
                                    },
                                    child: Chip(
                                      label: SelectableText(category.name),
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              Text(
                                l10n.noCategories,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.spacing16),

                        // 标签组
                        _buildSection(
                          l10n.tags,
                          [
                            if (_isEditing)
                              TextField(
                                controller: _tagsController,
                                decoration: InputDecoration(
                                  hintText: l10n.tagsHint,
                                  isDense: true,
                                ),
                              )
                            else if (widget.item.tags.isNotEmpty)
                              Wrap(
                                spacing: AppSizes.spacing8,
                                children: widget.item.tags.map((tag) {
                                  return InkWell(
                                    onTap: () {
                                      // Make empty since we don't want any action on tap
                                    },
                                    child: Chip(
                                      label: SelectableText(tag),
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              Text(
                                l10n.noTags,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.spacing16), // 文件信息组
                        _buildSection(
                          l10n.metadata,
                          [
                            _buildInfoRow(
                              l10n.format,
                              widget.item.format,
                            ),
                            _buildInfoRow(
                              l10n.resolution,
                              '${widget.item.width}x${widget.item.height}',
                            ),
                            _buildInfoRow(
                              l10n.fileSize,
                              FileSizeFormatter.format(widget.item.fileSize),
                            ),
                            _buildInfoRow(
                              l10n.path,
                              widget.item.path,
                              selectable: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.spacing16),

                        // 时间信息组
                        _buildSection(
                          l10n.timeInfo,
                          [
                            _buildInfoRow(
                              l10n.createdAt,
                              DateFormatter.formatWithTime(
                                  widget.item.fileCreatedAt),
                            ),
                            _buildInfoRow(
                              l10n.updatedAt,
                              DateFormatter.formatWithTime(
                                  widget.item.fileUpdatedAt),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.spacing16),

                        // 备注信息组
                        _buildSection(
                          l10n.remarks,
                          [
                            if (_isEditing)
                              TextField(
                                controller: _remarksController,
                                decoration: InputDecoration(
                                  hintText: l10n.remarksHint,
                                  isDense: true,
                                ),
                                maxLines: 3,
                              )
                            else
                              SelectableText(
                                widget.item.remarks.isEmpty
                                    ? l10n.noRemarks
                                    : widget.item.remarks,
                                style: theme.textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _tagsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _nameController = TextEditingController(text: widget.item.fileName);
    _tagsController = TextEditingController(text: widget.item.tags.join(', '));
    _remarksController = TextEditingController(text: widget.item.remarks);
    _selectedType = widget.item.type;
    _isFavorite = widget.item.isFavorite;
    _selectedCategories = List.from(widget.item.categories);
    _controller.forward();

    // Try to load file metadata if not present
    _loadFileMetadata();
  }

  // 收藏编辑行
  Widget _buildEditFavoriteRow(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              l10n.favorite,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Switch(
              value: _isFavorite,
              onChanged: (value) {
                setState(() => _isFavorite = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 类型编辑行
  Widget _buildEditTypeRow(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              l10n.type,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
              ),
              items: ['image', 'texture'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool selectable = false}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: selectable
                ? SelectableText(
                    value,
                    style: theme.textTheme.bodyMedium,
                  )
                : Text(
                    value,
                    style: theme.textTheme.bodyMedium,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing8),
        ...children,
      ],
    );
  }

  void _cancelEditing() {
    // Reset all values to their original state
    setState(() {
      _nameController.text = widget.item.fileName;
      _tagsController.text = widget.item.tags.join(', ');
      _remarksController.text = widget.item.remarks;
      _selectedType = widget.item.type;
      _isFavorite = widget.item.isFavorite;
      _selectedCategories = List.from(widget.item.categories);
      _isEditing = false;
    });
  }

  /// 加载文件元数据
  Future<void> _loadFileMetadata() async {
    // 如果元数据中已经包含文件创建和修改时间，就不需要再次加载
    final metadata = widget.item.metadata;
    if (metadata.containsKey('fileCreatedAt') &&
        metadata.containsKey('fileModifiedAt')) {
      return;
    }

    try {
      final file = File(widget.item.path);
      if (await file.exists()) {
        final fileStats = await file.stat();

        final updatedMetadata = Map<String, dynamic>.from(widget.item.metadata);

        // 更新元数据
        if (!metadata.containsKey('fileCreatedAt')) {
          updatedMetadata['fileCreatedAt'] =
              fileStats.changed.millisecondsSinceEpoch;
        }

        if (!metadata.containsKey('fileModifiedAt')) {
          updatedMetadata['fileModifiedAt'] =
              fileStats.modified.millisecondsSinceEpoch;
        }

        // 如果元数据有更新，更新库项
        if (updatedMetadata.length > metadata.length) {
          final updatedItem = widget.item.copyWith(
            metadata: updatedMetadata,
          );

          // 保存更新的元数据
          await ref
              .read(libraryManagementProvider.notifier)
              .updateItem(updatedItem);
        }
      }
    } catch (e) {
      AppLogger.warning('无法加载文件元数据',
          error: e, data: {'path': widget.item.path});
    }
  }

  void _saveChanges() async {
    if (_formKey.currentState?.validate() ?? true) {
      // Create an updated copy of the item
      final updatedItem = widget.item.copyWith(
        fileName: _nameController.text.trim(),
        type: _selectedType,
        tags: _tagsController.text.isEmpty
            ? []
            : _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
        categories: _selectedCategories,
        isFavorite: _isFavorite,
        remarks: _remarksController.text.trim(),
      ); // Save to database through provider
      try {
        await ref
            .read(libraryManagementProvider.notifier)
            .updateItem(updatedItem);

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.saveSuccess)),
          );
          setState(() {
            _isEditing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.saveFailedWithError(e.toString()))),
          );
        }
      }
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }
}
