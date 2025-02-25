import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../../domain/entities/work.dart';
import '../../../../../theme/app_sizes.dart';
import '../../../../../../utils/date_formatter.dart';
import '../../../../../../utils/path_helper.dart';

class WorkListItem extends StatelessWidget {
  final Work work;
  final bool isSelected;
  final bool isSelectionMode;
  final ValueChanged<bool>? onSelectionChanged;

  const WorkListItem({
    super.key,
    required this.work,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: isSelectionMode 
            ? () => onSelectionChanged?.call(!isSelected)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.m),
          child: SizedBox(
            height: AppSizes.listItemHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSizes.m),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => 
                          onSelectionChanged?.call(value ?? false),
                    ),
                  ),
                _buildThumbnail(context),
                const SizedBox(width: AppSizes.m),
                Expanded(child: _buildContent(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) => // ...existing thumbnail code...
  Widget _buildContent(BuildContext context) => // ...existing content code...
  Widget _buildTag(BuildContext context, String label) => // ...existing tag code...
  Widget _buildPlaceholder(BuildContext context) => // ...existing placeholder code...
}
