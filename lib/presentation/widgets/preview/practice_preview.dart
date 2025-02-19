import 'package:flutter/material.dart';

class PracticePreview extends StatefulWidget {
  final String practiceId;
  final int pageIndex;

  const PracticePreview({
    Key? key,
    required this.practiceId,
    required this.pageIndex,
  }) : super(key: key);

  @override
  State<PracticePreview> createState() => _PracticePreviewState();
}

class _PracticePreviewState extends State<PracticePreview> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: CustomPaint(
        painter: PracticePreviewPainter(),
        child: Container(), // 预览内容将由 CustomPainter 绘制
      ),
    );
  }
}

class PracticePreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // TODO: 实现字帖渲染逻辑
    // 1. 绘制背景
    // 2. 绘制网格
    // 3. 绘制集字
    // 4. 绘制其他元素
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
