import 'package:flutter/material.dart';

class ErrorText extends StatelessWidget {
  final String text;
  final int? maxLines;
  final TextStyle? style;

  const ErrorText({
    super.key,
    required this.text,
    this.maxLines = 2,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.error,
    );

    return Tooltip(
      message: text,
      waitDuration: const Duration(milliseconds: 500),
      child: Text(
        text,
        style: style ?? defaultStyle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}