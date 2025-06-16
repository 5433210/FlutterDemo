import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// 通用的收藏筛选部分组件
class M3FilterFavoriteSection extends StatelessWidget {
  /// 是否只显示收藏项
  final bool isFavoriteOnly;

  /// 收藏状态变化时的回调
  final ValueChanged<bool> onFavoriteChanged;

  /// 构造函数
  const M3FilterFavoriteSection({
    super.key,
    required this.isFavoriteOnly,
    required this.onFavoriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: isFavoriteOnly,
          onChanged: (value) => onFavoriteChanged(value ?? false),
        ),
        Flexible(
          child: Text(
            l10n.favoritesOnly,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
