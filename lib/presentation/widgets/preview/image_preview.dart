import 'dart:io';

import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

class ImagePreview extends StatelessWidget {
  final File? file;
  final String? networkUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ImagePreview({
    super.key,
    this.file,
    this.networkUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : assert(file != null || networkUrl != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: _buildImage(theme),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return errorWidget ??
        Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.error,
          ),
        );
  }

  Widget _buildImage(ThemeData theme) {
    if (file != null) {
      return Image.file(
        file!,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildError(theme),
      );
    }

    if (networkUrl != null) {
      return Image.network(
        networkUrl!,
        fit: fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _buildPlaceholder(theme);
        },
        errorBuilder: (_, __, ___) => _buildError(theme),
      );
    }

    return _buildError(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return placeholder ??
        Center(
          child: CircularProgressIndicator(
            color: theme.primaryColor,
          ),
        );
  }
}
