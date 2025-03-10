import 'package:demo/presentation/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 构建应用程序并触发一帧
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // 验证应用程序已启动
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
