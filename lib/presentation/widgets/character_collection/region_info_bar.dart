import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegionInfoBar extends StatefulWidget {
  final Rect rect;
  final double rotation;
  final Function(Size) onSizeChanged;
  final Function(double) onRotationChanged;

  const RegionInfoBar({
    Key? key,
    required this.rect,
    required this.rotation,
    required this.onSizeChanged,
    required this.onRotationChanged,
  }) : super(key: key);

  @override
  State<RegionInfoBar> createState() => _RegionInfoBarState();
}

class _RegionInfoBarState extends State<RegionInfoBar> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _rotationController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '区域信息',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // 宽度输入
              Expanded(
                child: _buildNumberField(
                  label: '宽度',
                  controller: _widthController,
                  suffix: 'px',
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final width =
                          int.tryParse(value) ?? widget.rect.width.toInt();
                      widget.onSizeChanged(
                          Size(width.toDouble(), widget.rect.height));
                    }
                  },
                ),
              ),

              const SizedBox(width: 16),

              // 高度输入
              Expanded(
                child: _buildNumberField(
                  label: '高度',
                  controller: _heightController,
                  suffix: 'px',
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final height =
                          int.tryParse(value) ?? widget.rect.height.toInt();
                      widget.onSizeChanged(
                          Size(widget.rect.width, height.toDouble()));
                    }
                  },
                ),
              ),

              const SizedBox(width: 16),

              // 旋转输入
              Expanded(
                child: _buildNumberField(
                  label: '旋转',
                  controller: _rotationController,
                  suffix: '°',
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final rotation =
                          int.tryParse(value) ?? widget.rotation.toInt();
                      widget.onRotationChanged(rotation.toDouble());
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(RegionInfoBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 只有当值变化时才更新控制器
    if (widget.rect.width.toInt() != oldWidget.rect.width.toInt()) {
      _widthController.text = widget.rect.width.toInt().toString();
    }

    if (widget.rect.height.toInt() != oldWidget.rect.height.toInt()) {
      _heightController.text = widget.rect.height.toInt().toString();
    }

    if (widget.rotation.toInt() != oldWidget.rotation.toInt()) {
      _rotationController.text = widget.rotation.toInt().toString();
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _widthController =
        TextEditingController(text: widget.rect.width.toInt().toString());
    _heightController =
        TextEditingController(text: widget.rect.height.toInt().toString());
    _rotationController =
        TextEditingController(text: widget.rotation.toInt().toString());
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
    );
  }
}
