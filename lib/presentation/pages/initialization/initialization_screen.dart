import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/initialization_providers.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';

class InitializationScreen extends ConsumerStatefulWidget {
  const InitializationScreen({super.key});

  @override
  ConsumerState<InitializationScreen> createState() =>
      _InitializationScreenState();
}

class _InitializationScreenState extends ConsumerState<InitializationScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _progressAnimation;

  Timer? _minimumDurationTimer;
  bool _minimumTimeElapsed = false;
  bool _initializationComplete = false;

  String _currentStatus = '';
  String? _errorMessage;
  List<String> _initializationSteps = [];
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();

    // 设置动画控制器
    _logoAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 设置动画
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    // 启动动画
    _logoAnimationController.forward();
    _progressAnimationController.repeat();

    // 设置最小显示时间（5秒）
    _minimumDurationTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _minimumTimeElapsed = true;
        });
      }
    });

    AppLogger.info('初始化屏幕启动', tag: 'InitScreen');
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _progressAnimationController.dispose();
    _minimumDurationTimer?.cancel();
    super.dispose();
  }

  void _updateInitializationSteps(AppLocalizations? l10n) {
    // 每次都重新生成，确保语言变化时文本能正确更新
    _initializationSteps = [
      l10n?.configInitializing ?? 'Initializing configuration...',
      l10n?.connectingDatabase ?? 'Connecting to database...',
      l10n?.loadingUserSettings ?? 'Loading user settings...',
      l10n?.initializingServices ?? 'Initializing services...',
      l10n?.preparingComplete ?? 'Preparation complete...',
    ];
    
    // 如果当前状态文本需要更新，也要重新设置
    if (_currentStepIndex < _initializationSteps.length) {
      _currentStatus = _initializationSteps[_currentStepIndex];
    }
  }

  void _simulateProgress() {
    if (_currentStepIndex < _initializationSteps.length - 1) {
      Timer(Duration(milliseconds: 300 + math.Random().nextInt(700)), () {
        if (mounted) {
          setState(() {
            _currentStepIndex++;
            _currentStatus = _initializationSteps[_currentStepIndex];
          });
          _simulateProgress();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('初始化屏幕构建开始', tag: 'InitScreen');
    final initState = ref.watch(appInitializationProvider);

    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Builder(builder: (context) {
          // 尝试获取本地化资源
          AppLocalizations? l10n;
          try {
            l10n = AppLocalizations.of(context);
            AppLogger.debug('成功获取本地化资源', tag: 'InitScreen');
          } catch (e) {
            AppLogger.warning('无法获取本地化资源', error: e, tag: 'InitScreen');
            l10n = null;
          }

          // 更新初始化步骤
          _updateInitializationSteps(l10n);

          return initState.when(
            data: (_) {
              _initializationComplete = true;
              AppLogger.info('初始化完成', tag: 'InitScreen');

              // 只有在最小时间已过且初始化完成时才继续
              if (!_minimumTimeElapsed) {
                return _buildLoadingScreen(context, l10n, theme, size,
                    l10n?.initializationCompleteMessage ?? 'Initialization complete, ready to start...',
                    isCompleted: true);
              }

              // 延迟跳转，显示完成状态
              Future.delayed(const Duration(milliseconds: 500), () {
                // 这里不需要做什么，app.dart会自动处理路由
              });

              return _buildCompletedScreen(context, l10n, theme, size);
            },
            loading: () {
              AppLogger.info('初始化加载中', tag: 'InitScreen');

              // 启动进度模拟（如果还没开始）
              if (_currentStepIndex == 0 && _initializationSteps.isNotEmpty) {
                _currentStatus = _initializationSteps[0];
                _simulateProgress();
              }

              return _buildLoadingScreen(
                  context,
                  l10n,
                  theme,
                  size,
                  _currentStatus.isEmpty
                      ? (l10n?.initializing ?? 'Initializing...')
                      : _currentStatus);
            },
            error: (error, stack) {
              AppLogger.error('初始化失败',
                  error: error, stackTrace: stack, tag: 'InitScreen');
              _errorMessage = error.toString();
              return _buildErrorScreen(context, l10n, theme, size, error);
            },
          );
        }),
      ),
    );
  }

  Widget _buildLoadingScreen(BuildContext context, AppLocalizations? l10n,
      ThemeData theme, Size size, String statusText,
      {bool isCompleted = false}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainer,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo区域
          Flexible(
            flex: 3,
            child: Center(
              child: AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(8), // 添加内边距确保logo完整显示
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 124,
                          height: 124,
                          fit: BoxFit.contain, // 改为contain确保logo完整显示
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 124,
                              height: 124,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary,
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 60,
                                color: theme.colorScheme.onPrimary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 标题区域
          Flexible(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n?.appTitle ?? '字字珠玑',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.appTitle == 'Char As Gem' ? 'Character As Gem' : 'CharAsGem',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // 进度区域
          Flexible(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 进度指示器
                  if (!isCompleted) ...[
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _CircularProgressPainter(
                              progress: _progressAnimation.value,
                              color: theme.colorScheme.primary,
                              backgroundColor:
                                  theme.colorScheme.outline.withOpacity(0.2),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.hourglass_empty,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                      child: Icon(
                        Icons.check,
                        color: theme.colorScheme.onPrimary,
                        size: 32,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 状态文本
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      statusText,
                      key: ValueKey(statusText),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 进度步骤指示器
                  if (_initializationSteps.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          _initializationSteps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final isActive = index <= _currentStepIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedScreen(BuildContext context, AppLocalizations? l10n,
      ThemeData theme, Size size) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.initializationComplete ?? '初始化完成',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.startingApplication ?? '正在启动应用...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, AppLocalizations? l10n,
      ThemeData theme, Size size, Object error) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.initializationError ?? '初始化失败',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.initializationErrorDetails ?? '错误详情:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.initializationErrorMessage ?? '请重新启动应用，如果问题持续存在，请联系支持团队',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              // 重新触发初始化
              ref.invalidate(appInitializationProvider);
            },
            child: Text(l10n?.retry ?? '重试'),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3.0;

    // Draw background circle
    paint.color = backgroundColor;
    canvas.drawCircle(center, radius, paint);

    // Draw progress arc
    paint.color = color;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
