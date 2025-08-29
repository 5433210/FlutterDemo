import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';

/// 简化版初始化屏幕
/// 只负责显示UI，不重复执行初始化工作
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

  Timer? _displayTimer;
  String _currentStatus = '';
  int _currentStep = 0;

  // 预定义的显示步骤，不执行实际初始化
  final List<String> _displaySteps = [
    'initializingServices',
    'connectingDatabase',
    'loadingUserSettings',
    'preparingComplete',
  ];

  @override
  void initState() {
    super.initState();

    AppLogger.info('初始化屏幕启动', tag: 'InitScreen');

    _setupAnimations();
    _startDisplaySequence();
  }

  void _setupAnimations() {
    _logoAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

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

    // 启动logo动画
    _logoAnimationController.forward();
  }

  void _startDisplaySequence() {
    // 仅用于显示的步骤序列，不执行实际初始化
    _displayTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_currentStep < _displaySteps.length) {
        if (mounted) {
          setState(() {
            _currentStatus = _displaySteps[_currentStep];
            _currentStep++;
          });

          // 更新进度动画
          _progressAnimationController.animateTo(
            _currentStep / _displaySteps.length,
          );
        }
      } else {
        timer.cancel();
        // 显示完成后短暂停留
        Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _currentStatus = 'initializationComplete';
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _logoAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('初始化屏幕构建开始', tag: 'InitScreen');

    // 获取本地化资源
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
      AppLogger.debug('成功获取本地化资源', tag: 'InitScreen');
    } catch (e) {
      AppLogger.warning('获取本地化资源失败，使用默认文本', error: e, tag: 'InitScreen');
    }

    AppLogger.info('初始化加载中', tag: 'InitScreen');

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo动画
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // 如果logo加载失败，回退到原来的图标
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.edit_note,
                                size: 60,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // 应用标题
              Text(
                l10n?.appTitle ?? '字字珠玑',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),

              const SizedBox(height: 60),

              // 进度指示器
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    // 进度条
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // 状态文本
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _getStatusText(l10n),
                        key: ValueKey(_currentStatus),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 加载动画
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(AppLocalizations? l10n) {
    switch (_currentStatus) {
      case 'initializingServices':
        return l10n?.initializingServices ?? '正在初始化服务...';
      case 'connectingDatabase':
        return l10n?.connectingDatabase ?? '正在连接数据库...';
      case 'loadingUserSettings':
        return l10n?.loadingUserSettings ?? '正在加载用户设置...';
      case 'preparingComplete':
        return l10n?.preparingComplete ?? '准备完成...';
      case 'initializationComplete':
        return l10n?.initializationComplete ?? '初始化完成';
      default:
        return l10n?.startingApplication ?? '正在启动应用...';
    }
  }
}

/// 自定义loading动画widget
class _LoadingAnimation extends StatefulWidget {
  final Color color;

  const _LoadingAnimation({required this.color});

  @override
  State<_LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<_LoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2.0 * math.pi,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: CustomPaint(
              painter: _LoadingPainter(
                color: widget.color,
                progress: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final Color color;
  final double progress;

  _LoadingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress * 0.8,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
