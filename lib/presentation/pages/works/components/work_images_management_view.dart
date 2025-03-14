import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../../presentation/providers/work_image_editor_provider.dart';
import '../../../../theme/app_sizes.dart';
import 'work_image_editor.dart';

class WorkImagesManagementView extends ConsumerWidget {
  final WorkEntity work;

  const WorkImagesManagementView({
    super.key,
    required this.work,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(workImageEditorProvider(work)); // 监听图片变化

    return Container(
      padding: const EdgeInsets.all(AppSizes.m),
      child: WorkImageEditor(work: work),
    );
  }
}
