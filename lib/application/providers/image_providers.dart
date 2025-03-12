import 'package:demo/application/providers/storage_providers.dart';
import 'package:demo/infrastructure/image/image_processor_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/image/image_processor.dart';

final imageProcessorProvider = Provider<ImageProcessor>((ref) {
  return ImageProcessorImpl(cachePath: ref.watch(cachePathProvider));
});
