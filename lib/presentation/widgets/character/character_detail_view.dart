import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class CharacterDetailView extends StatelessWidget {
  final String charId;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const CharacterDetailView({
    super.key,
    required this.charId,
    this.showCloseButton = false,
    this.onClose,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!showCloseButton) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.characterDetailTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.edit),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.basicInfo,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        _buildInfoRow('Unicode', 'U+4E00', theme),
                        _buildInfoRow(l10n.pinyin, 'yī', theme),
                        _buildInfoRow(l10n.strokeCount, '1', theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.sourceInfo,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        _buildInfoRow(l10n.work, '兰亭集序', theme),
                        _buildInfoRow(l10n.author, '王羲之', theme),
                        _buildInfoRow(l10n.dynasty, '晋', theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
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
}
