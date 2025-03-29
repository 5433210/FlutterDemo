import 'package:flutter/material.dart';

class CharacterInput extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String? thumbnailPath;

  const CharacterInput({
    Key? key,
    required this.value,
    required this.onChanged,
    this.thumbnailPath,
  }) : super(key: key);

  @override
  State<CharacterInput> createState() => _CharacterInputState();
}

class _CharacterInputState extends State<CharacterInput> {
  late TextEditingController _controller;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 字符输入区
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '字符输入',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '输入对应的汉字',
                      errorText: _hasError ? '请输入有效的汉字' : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24),
                    maxLength: 1,
                    onChanged: _validateAndUpdate,
                    buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) {
                      return null; // 隐藏字符计数器
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 缩略图预览
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      '缩略图',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: widget.thumbnailPath != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            child: Image.asset(
                              widget.thumbnailPath!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 24,
                              color: Colors.black26,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    if (char.length != 1) return false;
    final codeUnit = char.codeUnitAt(0);
    return codeUnit >= 0x4e00 && codeUnit <= 0x9fff;
  }

  void _validateAndUpdate(String value) {
    final isValid = value.isEmpty || _isChineseCharacter(value);
    setState(() {
      _hasError = value.isNotEmpty && !isValid;
    });
    if (isValid) {
      widget.onChanged(value);
    }
  }
}
