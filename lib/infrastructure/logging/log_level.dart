import 'package:flutter/material.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal;

  Color get color {
    return switch (this) {
      LogLevel.debug => Colors.grey,
      LogLevel.info => Colors.blue,
      LogLevel.warning => Colors.yellow,
      LogLevel.error => Colors.red,
      LogLevel.fatal => Colors.purple,
    };
  }

  String get emoji {
    return switch (this) {
      LogLevel.debug => '🔍',
      LogLevel.info => 'ℹ️',
      LogLevel.warning => '⚠️',
      LogLevel.error => '❌',
      LogLevel.fatal => '☠️',
    };
  }

  String get name => toString().split('.').last.toUpperCase();
}
