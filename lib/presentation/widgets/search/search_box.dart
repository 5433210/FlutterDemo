import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';

class SearchBox extends StatelessWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final TextEditingController? controller;
  final double? width;

  const SearchBox({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 240,
      child: SearchBar(
        controller: controller,
        hintText: hintText,
        leading: const Icon(Icons.search),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSizes.spacingMedium,
          ),
        ),
        onChanged: onChanged,
        onSubmitted: (value) => onSubmitted?.call(),
      ),
    );
  }
}
