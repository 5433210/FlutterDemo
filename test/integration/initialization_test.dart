import 'dart:async';

import 'package:demo/infrastructure/persistence/database_state.dart';
import 'package:demo/infrastructure/providers/initialization_providers.dart';
import 'package:demo/presentation/pages/initialization/initialization_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/mock_test_helpers.dart';
import 'test_config.dart';

void main() {
  late ProviderContainer container;

  setUpAll(() async {
    TestConfig.configureTestEnv();
    TestLogger.logTestStart('初始化测试套件');

    await setupTestEnvironment();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    TestLogger.logTestStep('测试环境初始化完成');
  });

  setUp(() {
    TestLogger.logTestStep('开始新的测试用例');
    container = ProviderContainer(
      overrides: [
        // 使用mock初始化服务
        initializationServiceProvider
            .overrideWithValue(BaseMockInitializationService()),
      ],
    );
  });

  tearDown(() {
    TestLogger.logTestStep('清理测试用例');
    container.dispose();
  });

  group('初始化流程测试', () {
    test('数据库初始化状态变化', () async {
      TestLogger.logTestStep('测试数据库初始化状态变化');
      final states = <DatabaseState>[];

      container.listen(
        databaseStateProvider,
        (previous, next) {
          states.add(next);
          TestLogger.logTestStep('数据库状态变化: ${next.isInitialized}');
        },
        fireImmediately: true,
      );

      // 等待初始化完成或失败
      await AsyncTestHelper.waitUntil(
        () => states.isNotEmpty && states.last.isInitialized,
        timeout: TestConfig.timeoutDuration,
      );

      // 验证状态变化
      expect(states, hasLength(greaterThan(1)), reason: '应该有多个状态变化');
      expect(states.first.isInitialized, false, reason: '初始状态应为未初始化');
      expect(states.last.isInitialized, true, reason: '最终状态应为已初始化');
      expect(states.last.database, isNotNull, reason: '数据库实例应该存在');
    });

    test('初始化超时处理', () async {
      TestLogger.logTestStep('测试初始化超时处理');
      // 重置container使用慢速服务
      container = ProviderContainer(
        overrides: [
          initializationServiceProvider
              .overrideWithValue(MockSlowInitializationService()),
        ],
      );

      bool timeoutOccurred = false;
      try {
        await AsyncTestHelper.expectWithTimeout(
          () => Future.delayed(const Duration(seconds: 6)),
          null,
          timeout: const Duration(seconds: 5),
          description: '超时测试',
        );
      } on TimeoutException {
        timeoutOccurred = true;
        TestLogger.logTestStep('预期的超时发生');
      }

      expect(timeoutOccurred, true, reason: '应该触发超时');
    });

    testWidgets('初始化界面显示测试', (WidgetTester tester) async {
      TestLogger.logTestStep('测试初始化界面显示');
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InitializationScreen(),
          ),
        ),
      );

      // 验证加载指示器显示
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('正在初始化应用...'), findsOneWidget);
      TestLogger.logTestStep('加载指示器显示正确');

      // 等待初始化过程
      await tester.pumpAndSettle(TestConfig.timeoutDuration);
    });

    testWidgets('错误处理和重试功能测试', (WidgetTester tester) async {
      TestLogger.logTestStep('测试错误处理和重试功能');
      // 注入会失败的初始化服务
      final container = ProviderContainer(
        overrides: [
          initializationServiceProvider
              .overrideWithValue(MockFailingInitializationService()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: InitializationScreen(),
          ),
        ),
      );

      // 等待错误状态显示
      await tester.pumpAndSettle();
      TestLogger.logTestStep('错误状态显示');

      // 验证错误UI
      expect(find.text('初始化失败'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);

      // 测试重试按钮
      await tester.tap(find.text('重试'));
      await tester.pump();
      TestLogger.logTestStep('触发重试操作');

      // 验证重新显示加载状态
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  tearDownAll(() {
    TestLogger.logTestEnd('初始化测试套件');
  });
}
