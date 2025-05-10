import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/library_category.dart';
import '../../../../domain/entities/library_item.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../presentation/providers/library/library_management_provider.dart';
import '../../../../theme/app_sizes.dart';
import 'library_image_preview_dialog.dart';

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
                            l10n.libraryManagementDetail,
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
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: _showPreview,
                            tooltip: l10n.preview,
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
                          l10n.libraryManagementBasicInfo,
                          [
                            if (_isEditing)
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: l10n.libraryManagementName,
                                  isDense: true,
                                ),
                              )
                            else
                              _buildInfoRow(
                                l10n.libraryManagementName,
                                widget.item.fileName,
                              ),
                            const SizedBox(height: AppSizes.spacing8),
                            if (_isEditing) ...[
                              _buildEditTypeRow(theme, l10n),
                              _buildEditFavoriteRow(theme, l10n),
                            ] else ...[
                              _buildInfoRow(
                                l10n.libraryManagementType,
                                widget.item.type,
                              ),
                              _buildInfoRow(
                                l10n.libraryManagementFavorite,
                                widget.item.isFavorite ? l10n.yes : l10n.no,
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: AppSizes.spacing16),

                        // 分类组
                        _buildSection(
                          l10n.libraryManagementCategories,
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
                                  return Chip(
                                    label: Text(category.name),
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
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
                          l10n.libraryManagementTags,
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
                                  return Chip(
                                    label: Text(tag),
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
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

                        const SizedBox(height: AppSizes.spacing16),

                        // 文件信息组
                        _buildSection(
                          l10n.libraryManagementMetadata,
                          [
                            _buildInfoRow(
                              l10n.libraryManagementFormat,
                              widget.item.format,
                            ),
                            _buildInfoRow(
                              l10n.libraryManagementSize,
                              '${widget.item.width}x${widget.item.height}',
                            ),
                            _buildInfoRow(
                              l10n.libraryManagementFileSize,
                              _formatFileSize(widget.item.fileSize),
                            ),
                            _buildInfoRow(
                              l10n.libraryManagementPath,
                              widget.item.path,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.spacing16),

                        // 时间信息组
                        _buildSection(
                          l10n.libraryManagementTimeInfo,
                          [
                            _buildInfoRow(
                              l10n.libraryManagementCreatedAt,
                              _formatDateTime(widget.item.fileCreatedAt),
                            ),
                            _buildInfoRow(
                              l10n.libraryManagementUpdatedAt,
                              _formatDateTime(widget.item.fileUpdatedAt),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.spacing16),

                        // 备注信息组
                        _buildSection(
                          l10n.libraryManagementRemarks,
                          [
                            if (_isEditing)
                              TextField(
                                controller: _remarksController,
                                decoration: InputDecoration(
                                  hintText: l10n.libraryManagementRemarksHint,
                                  isDense: true,
                                ),
                                maxLines: 3,
                              )
                            else
                              Text(
                                widget.item.remarks.isEmpty
                                    ? l10n.libraryManagementNoRemarks
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
              l10n.libraryManagementFavorite,
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
              l10n.libraryManagementType,
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

  Widget _buildInfoRow(String label, String value) {
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
            child: Text(
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

  String _formatDateTime(DateTime dateTime) {
    return DateFormat.yMd().add_Hms().format(dateTime);
  }

  String _formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// 安全地将动态值转换为整数
  int _getInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    } else {
      return 0;
    }
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
      );

      // Save to database through provider
      try {
        await ref
            .read(libraryManagementProvider.notifier)
            .updateItem(updatedItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存成功')),
          );
          setState(() {
            _isEditing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showPreview() {
    if (widget.item.thumbnail == null) {
      AppLogger.warning('缩略图不存在', data: {'itemId': widget.item.id});
      return;
    }

    showDialog(
      context: context,
      builder: (context) => LibraryImagePreviewDialog(item: widget.item),
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }
}
