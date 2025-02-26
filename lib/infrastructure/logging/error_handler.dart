import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logger.dart';

class AppErrorHandler {
  static void initialize() {
    // Capture Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error(
        details.exceptionAsString(),
        error: details.exception,
        stackTrace: details.stack,
        tag: 'Flutter',
      );
      // Forward to Flutter's default handler
      FlutterError.presentError(details);
    };

    // Capture Dart uncaught errors
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.fatal(
        'Uncaught exception',
        error: error,
        stackTrace: stack,
        tag: 'Dart',
      );
      // Allow normal handling to continue
      return false;
    };
  }
}

// Riverpod observer example
class ProviderLogger extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    AppLogger.debug(
      'Provider ${provider.name ?? provider.runtimeType} was initialized with $value',
      tag: 'Riverpod',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    AppLogger.debug(
      'Provider ${provider.name ?? provider.runtimeType} was disposed',
      tag: 'Riverpod',
    );
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.error(
      'Provider ${provider.name ?? provider.runtimeType} failed',
      error: error,
      stackTrace: stackTrace,
      tag: 'Riverpod',
    );
  }
}
