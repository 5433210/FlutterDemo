import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/character/character_collection_provider.dart';
import '../common/m3_page_navigation_bar.dart';

class M3NavigationBar extends ConsumerWidget implements PreferredSizeWidget {
  final String workId;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  const M3NavigationBar({
    super.key,
    required this.workId,
    required this.onBack,
    this.onHelp,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final collectionState = ref.watch(characterCollectionProvider);

    // Calculate status text
    String statusText = '';
    if (collectionState.processing) {
      statusText = l10n.characterCollectionProcessing;
    } else if (collectionState.error != null) {
      statusText = l10n.characterCollectionError(collectionState.error!);
    }

    return M3PageNavigationBar(
      title: l10n.characterCollectionTitle,
      onBackPressed: onBack,
      titleActions: statusText.isNotEmpty
          ? [
              const SizedBox(width: AppSizes.m),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s, vertical: AppSizes.xs),
                decoration: BoxDecoration(
                  color: collectionState.error != null
                      ? colorScheme.error.withOpacity(0.1)
                      : colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.m),
                ),
                child: Text(
                  statusText,
                  style: textTheme.bodyMedium?.copyWith(
                    color: collectionState.error != null
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                ),
              ),
            ]
          : null,
      actions: [
        // Help button
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: l10n.characterCollectionHelp,
          onPressed: onHelp ?? () => _showHelpDialog(context),
        ),
      ],
    );
  }

  Widget _buildHelpSection(
      BuildContext context, String title, List<String> items) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: textTheme.titleMedium,
            ),
          ),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  item,
                  style: textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              )),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.characterCollectionHelpTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.characterCollectionHelpGuide,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.characterCollectionHelpIntro,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _buildHelpSection(
                context,
                l10n.characterCollectionHelpSection1,
                [
                  '• 框选工具（S键）：创建新字符区域',
                  '• 多选工具（M键）：选择多个已有区域',
                  '• 拖拽工具（V键）：移动和缩放图片',
                  '• 单击区域选中，再次点击可取消选择',
                  '• 按住Shift键可进行多选操作',
                  '• 使用鼠标滚轮或触控板进行缩放',
                  '• 按住空格键并拖动可平移图片',
                ],
              ),
              _buildHelpSection(
                context,
                l10n.characterCollectionHelpSection2,
                [
                  '• 选中区域后可拖动边框调整大小',
                  '• 拖动角部控制点可等比例缩放',
                  '• 拖动边部控制点可单向调整尺寸',
                  '• 拖动区域内部可移动整个区域',
                  '• 方向键可微调位置（Shift+方向键调整幅度更大）',
                  '• ESC键可取消当前操作',
                ],
              ),
              _buildHelpSection(
                context,
                l10n.characterCollectionHelpSection3,
                [
                  '• E键激活擦除工具',
                  '• 拖动鼠标擦除字符内不需要的部分',
                  '• 擦除后字符区域会标记为已修改',
                  '• 使用Ctrl+Z撤销擦除操作',
                  '• 使用Ctrl+Shift+Z重做擦除操作',
                ],
              ),
              _buildHelpSection(
                context,
                l10n.characterCollectionHelpSection4,
                [
                  '• 修改后的字符会自动标记为未保存状态',
                  '• 按Ctrl+S手动保存所有修改',
                  '• 编辑区域顶部会显示当前工作状态',
                  '• 离开页面前会提示保存未保存的修改',
                ],
              ),
              _buildHelpSection(
                context,
                l10n.characterCollectionHelpSection5,
                [
                  '• V：切换到拖拽工具（默认）',
                  '• S：切换到框选工具',
                  '• M：切换到多选工具',
                  '• E：切换到擦除工具',
                  '• Delete：删除选中区域',
                  '• Ctrl+Z：撤销操作',
                  '• Ctrl+Y/Ctrl+Shift+Z：重做操作',
                  '• 方向键：微调选区位置',
                  '• Shift+方向键：大幅度调整位置',
                  '• Space+拖动：平移图片',
                  '• Ctrl+S：保存修改',
                  '• Esc：取消当前操作',
                ],
              ),
              _buildHelpSection(
                context,
                l10n.characterCollectionHelpNotes,
                [
                  '• 选中区域会显示蓝色边框和控制点',
                  '• 未保存的修改会在状态栏显示',
                  '• 多选模式下可以进行批量删除',
                  '• 图片处理可能需要一定时间，请耐心等待',
                  '• 操作结束后建议及时保存更改',
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.characterCollectionHelpClose),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement help document export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.characterCollectionHelpExportSoon),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(l10n.characterCollectionHelpExport),
          ),
        ],
      ),
    );
  }
}
