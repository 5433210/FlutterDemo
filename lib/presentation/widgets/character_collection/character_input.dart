import 'package:flutter/material.dart';

class CharacterInput extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const CharacterInput({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection = TextSelection.collapsed(offset: value.length),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '请输入字符',
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        onChanged: onChanged,
      ),
    );
  }
}
