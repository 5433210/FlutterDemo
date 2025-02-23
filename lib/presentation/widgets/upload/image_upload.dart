import 'package:flutter/material.dart';
import 'dart:io';
import '../../../theme/app_sizes.dart';
import '../preview/image_preview.dart';

class ImageUpload extends StatelessWidget {
  final File? file;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;
  final double? width;
  final double? height;
  final String? uploadHint;
  final bool showPreview;

  const ImageUpload({
    super.key,
    this.file,
    required this.onUpload,
    this.onRemove,
    this.width,
    this.height,
    this.uploadHint,
    this.showPreview = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: file != null && showPreview
          ? _buildPreview(context)
          : _buildUploadButton(context),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Stack(
      children: [
        ImagePreview(file: file),
        if (onRemove != null)
          Positioned(
            top: AppSizes.spacingSmall,
            right: AppSizes.spacingSmall,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onUpload,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            Text(
              uploadHint ?? '点击上传图片',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
