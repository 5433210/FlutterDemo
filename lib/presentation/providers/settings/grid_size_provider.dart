import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider for grid item size preference
final gridSizeProvider = StateProvider<GridSizeOption>((ref) {
  // Default to medium size
  return GridSizeOption.medium;
});

/// Grid size option enum
enum GridSizeOption {
  small(150.0),
  medium(200.0),
  large(250.0),
  extraLarge(300.0);

  final double minItemWidth;

  const GridSizeOption(this.minItemWidth);
}
