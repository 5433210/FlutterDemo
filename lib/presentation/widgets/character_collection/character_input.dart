import 'package:flutter/material.dart';

class CharacterInput extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const CharacterInput({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CharacterInput> createState() => _CharacterInputState();
}

class _CharacterInputState extends State<CharacterInput> {
  late TextEditingController _controller;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '字符',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: '输入对应的汉字',
            helperText: '请输入一个汉字',
            errorText: _hasError ? '请输入有效的汉字' : null,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
          maxLength: 1,
          onChanged: _validateAndUpdate,
          buildCounter: (context,
              {required currentLength, required isFocused, maxLength}) {
            return null; // 隐藏字符计数器
          },
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(CharacterInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  bool _isChineseCharacter(String char) {
    // 检查是否为单个汉字
    // 汉字的Unicode范围大致为：\u4e00-\u9fff
    if (char.length != 1) return false;

    final codeUnit = char.codeUnitAt(0);
    return codeUnit >= 0x4e00 && codeUnit <= 0x9fff;
  }

  void _validateAndUpdate(String value) {
    // 校验是否为单个汉字
    final isValid = value.isEmpty || _isChineseCharacter(value);

    setState(() {
      _hasError = value.isNotEmpty && !isValid;
    });

    if (isValid) {
      widget.onChanged(value);
    }
  }
}
