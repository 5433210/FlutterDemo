import 'dart:io';

import 'package:path/path.dart' as path;

import 'check_logger.dart';

/// 环境变量验证器
class EnvironmentValidator {
  final CheckLogger logger;
  final Map<String, String> _requiredVars;
  final Map<String, String> _defaultValues;

  EnvironmentValidator({
    CheckLogger? logger,
    Map<String, String>? requiredVars,
    Map<String, String>? defaultValues,
  })  : logger = logger ?? CheckLogger.instance,
        _requiredVars = requiredVars ??
            const {
              'DART_SDK': '需要设置 Dart SDK 路径',
              'TEST_DATA_PATH': '测试数据目录路径',
              'TEST_LOG_LEVEL': '日志级别 (debug/info/warning/error)',
              'TEST_TIMEOUT': '测试超时时间（秒）',
            },
        _defaultValues = defaultValues ??
            const {
              'TEST_LOG_LEVEL': 'info',
              'TEST_TIMEOUT': '300',
              'TEST_DATA_PATH': 'test/data',
            };

  /// 自动修复环境问题
  Future<bool> autoFix() async {
    var fixed = false;

    try {
      // 检查并创建必要的目录
      for (final dir in [
        'test/data',
        'test/logs',
        'test/reports',
        'coverage',
      ]) {
        final directory = Directory(dir);
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
          logger.info('已创建目录: $dir');
          fixed = true;
        }
      }

      // 设置默认环境变量
      for (final entry in _defaultValues.entries) {
        if (Platform.environment[entry.key] == null) {
          // 在 Windows 上使用 setx，在 Unix 上修改 ~/.bashrc 或 ~/.zshrc
          if (Platform.isWindows) {
            await Process.run('setx', [entry.key, entry.value]);
          } else {
            final shell = Platform.environment['SHELL'] ?? '/bin/bash';
            final rcFile = shell.contains('zsh') ? '.zshrc' : '.bashrc';
            final home = Platform.environment['HOME'];
            if (home != null) {
              final file = File(path.join(home, rcFile));
              if (file.existsSync()) {
                await file.writeAsString(
                  '\nexport ${entry.key}=${entry.value}\n',
                  mode: FileMode.append,
                );
              }
            }
          }
          logger.info('已设置环境变量: ${entry.key}=${entry.value}');
          fixed = true;
        }
      }

      return fixed;
    } catch (e) {
      logger.error('自动修复失败', e);
      return false;
    }
  }

  /// 获取环境摘要
  String getSummary() {
    final result = validate();
    final buffer = StringBuffer('环境检查摘要:\n');

    if (result.missing.isNotEmpty) {
      buffer.writeln('\n缺少的环境变量:');
      for (final entry in result.missing.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value}');
      }
    }

    if (result.invalid.isNotEmpty) {
      buffer.writeln('\n无效的环境变量:');
      for (final entry in result.invalid.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value}');
      }
    }

    buffer.writeln('\n当前使用的环境变量:');
    for (final entry in result.using.entries) {
      buffer.writeln('- ${entry.key}=${entry.value}');
    }

    return buffer.toString();
  }

  /// 验证环境变量
  ValidationResult validate() {
    final missing = <String, String>{};
    final invalid = <String, String>{};
    final using = <String, String>{};

    for (final entry in _requiredVars.entries) {
      final name = entry.key;
      final description = entry.value;
      var value = Platform.environment[name];

      // 如果没有设置，使用默认值
      if (value == null || value.isEmpty) {
        value = _defaultValues[name];
        if (value == null) {
          missing[name] = description;
          continue;
        }
      }

      // 验证特定变量
      if (!_validateVariable(name, value)) {
        invalid[name] = value;
        continue;
      }

      using[name] = value;
    }

    return ValidationResult(
      missing: missing,
      invalid: invalid,
      using: using,
    );
  }

  /// 验证特定变量
  bool _validateVariable(String name, String value) {
    switch (name) {
      case 'DART_SDK':
        return Directory(value).existsSync() &&
            File(path.join(
                    value, 'bin', Platform.isWindows ? 'dart.exe' : 'dart'))
                .existsSync();

      case 'TEST_DATA_PATH':
        final dir = Directory(value);
        if (!dir.existsSync()) {
          try {
            dir.createSync(recursive: true);
          } catch (e) {
            return false;
          }
        }
        return true;

      case 'TEST_LOG_LEVEL':
        return ['debug', 'info', 'warning', 'error']
            .contains(value.toLowerCase());

      case 'TEST_TIMEOUT':
        return int.tryParse(value) != null && int.parse(value) > 0;

      default:
        return true;
    }
  }
}

/// 验证结果
class ValidationResult {
  final Map<String, String> missing;
  final Map<String, String> invalid;
  final Map<String, String> using;

  ValidationResult({
    required this.missing,
    required this.invalid,
    required this.using,
  });

  bool get isValid => missing.isEmpty && invalid.isEmpty;

  @override
  String toString() {
    if (isValid) {
      return '环境验证通过，使用 ${using.length} 个环境变量';
    }
    return '环境验证失败: ${missing.length} 个缺失, ${invalid.length} 个无效';
  }
}
