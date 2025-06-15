#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// 增强版本地化检查脚本
/// 用于验证ARB文件的完整性和一致性，并查找所有硬编码中文文本
Future<void> main() async {
  print('🌐 开始增强版本地化检查...\n');

  // 检查配置文件
  await _checkL10nConfig();

  // 检查ARB文件
  await _checkArbFiles();

  // 检查生成的文件
  await _checkGeneratedFiles();

  // 增强检查硬编码文本
  await _checkHardcodedTextEnhanced();

  print('\n✅ 增强版本地化检查完成！');
}

Future<void> _checkL10nConfig() async {
  print('📋 检查 l10n.yaml 配置...');

  final l10nFile = File('l10n.yaml');
  if (!l10nFile.existsSync()) {
    print('❌ l10n.yaml 文件不存在');
    return;
  }

  final content = await l10nFile.readAsString();
  print('✅ l10n.yaml 配置正常');
  print('   内容预览: ${content.split('\n').take(3).join(', ')}...');
}

Future<void> _checkArbFiles() async {
  print('\n📝 检查 ARB 文件...');

  final l10nDir = Directory('lib/l10n');
  if (!l10nDir.existsSync()) {
    print('❌ l10n 目录不存在');
    return;
  }

  final arbFiles = l10nDir
      .listSync()
      .where((file) => file.path.endsWith('.arb'))
      .map((file) => file.path)
      .toList();

  if (arbFiles.isEmpty) {
    print('❌ 没有找到 ARB 文件');
    return;
  }

  print('✅ 找到 ${arbFiles.length} 个 ARB 文件:');

  final Map<String, Set<String>> allKeys = {};

  for (final arbPath in arbFiles) {
    final file = File(arbPath);
    final content = await file.readAsString();
    final Map<String, dynamic> arbData = jsonDecode(content);

    final keys = arbData.keys.where((key) => !key.startsWith('@')).toSet();

    final fileName = arbPath.split('/').last.split('\\').last;
    final locale = arbData['@@locale'] ?? 'unknown';

    print('   - $fileName');
    print('     语言: $locale, 键数量: ${keys.length}');

    allKeys[fileName] = keys;
  }

  // 检查键的一致性
  await _checkKeyConsistency(allKeys);
}

Future<void> _checkKeyConsistency(Map<String, Set<String>> allKeys) async {
  print('\n🔍 检查键的一致性...');

  final fileNames = allKeys.keys.toList();
  if (fileNames.length < 2) {
    print('⚠️  只有一个 ARB 文件，无需检查一致性');
    return;
  }

  final firstFile = fileNames[0];
  final firstKeys = allKeys[firstFile]!;

  bool hasInconsistency = false;

  for (int i = 1; i < fileNames.length; i++) {
    final currentFile = fileNames[i];
    final currentKeys = allKeys[currentFile]!;

    final missingInCurrent = firstKeys.difference(currentKeys);
    final extraInCurrent = currentKeys.difference(firstKeys);

    if (missingInCurrent.isNotEmpty) {
      print('❌ $currentFile 中缺少的键:');
      for (final key in missingInCurrent.take(5)) {
        print('   - $key');
      }
      if (missingInCurrent.length > 5) {
        print('   ... 还有 ${missingInCurrent.length - 5} 个');
      }
      hasInconsistency = true;
    }

    if (extraInCurrent.isNotEmpty) {
      print('❌ $currentFile 中多余的键:');
      for (final key in extraInCurrent.take(5)) {
        print('   - $key');
      }
      if (extraInCurrent.length > 5) {
        print('   ... 还有 ${extraInCurrent.length - 5} 个');
      }
      hasInconsistency = true;
    }
  }

  if (!hasInconsistency) {
    print('✅ 所有 ARB 文件的键保持一致');
  }
}

Future<void> _checkGeneratedFiles() async {
  print('\n🔧 检查生成的文件...');

  final generatedFiles = [
    'lib/l10n/app_localizations.dart',
    'lib/l10n/app_localizations_zh.dart',
    'lib/l10n/app_localizations_en.dart',
  ];

  for (final filePath in generatedFiles) {
    final file = File(filePath);
    if (file.existsSync()) {
      print('✅ $filePath 存在');
    } else {
      print('❌ $filePath 不存在');
    }
  }

  print('\n💡 如果生成的文件不存在，请运行:');
  print('   flutter packages get');
  print('   flutter gen-l10n');
}

Future<void> _checkHardcodedTextEnhanced() async {
  print('\n🔍 增强检查硬编码文本...');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ lib 目录不存在');
    return;
  }

  final dartFiles = libDir
      .listSync(recursive: true)
      .where((file) =>
          file.path.endsWith('.dart') &&
          !file.path.contains('/l10n/') &&
          !file.path.contains('\\l10n\\'))
      .map((file) => file.path)
      .toList();

  print('📄 检查 ${dartFiles.length} 个 Dart 文件...');
  var hardcodedCount = 0;
  final Map<String, List<int>> fileResults = {};

  for (final filePath in dartFiles) {
    final file = File(filePath);
    try {
      final lines = await file.readAsLines();
      final foundLines = <int>[];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];

        if (_isHardcodedChineseText(line)) {
          hardcodedCount++;
          foundLines.add(i + 1);
          final fileName = filePath.split('/').last.split('\\').last;
          print('⚠️  $fileName:${i + 1} - ${line.trim()}');
        }
      }

      if (foundLines.isNotEmpty) {
        fileResults[filePath] = foundLines;
      }
    } catch (e) {
      print('❌ 无法读取文件: $filePath');
    }
  }

  print('\n📊 统计结果:');
  if (hardcodedCount == 0) {
    print('✅ 没有发现硬编码中文文本');
  } else {
    print('❌ 发现 $hardcodedCount 处硬编码中文文本');
    print('📁 涉及 ${fileResults.length} 个文件');
    print('💡 请使用 AppLocalizations.of(context).keyName 替换硬编码文本');

    // 按文件分组显示
    print('\n📋 按文件分组:');
    for (final entry in fileResults.entries) {
      final fileName = entry.key.split('/').last.split('\\').last;
      final lineNumbers = entry.value;
      print(
          '   - $fileName: ${lineNumbers.length} 处 (行: ${lineNumbers.take(5).join(', ')}${lineNumbers.length > 5 ? '...' : ''})');
    }
  }
}

/// 检查是否是需要本地化的硬编码中文文本
bool _isHardcodedChineseText(String line) {
  // 基本检查
  if (!_containsChinese(line)) {
    return false;
  }

  final trimmedLine = line.trim();

  // 跳过注释行
  if (trimmedLine.startsWith('//') ||
      trimmedLine.startsWith('/*') ||
      trimmedLine.startsWith('*') ||
      trimmedLine.startsWith('///')) {
    return false;
  }

  // 跳过日志语句
  if (line.contains('AppLogger.') ||
      line.contains('EditPageLogger.') ||
      line.contains('developer.log') ||
      line.contains('debugPrint') ||
      line.contains('print(') ||
      line.contains('log(')) {
    return false;
  }

  // 跳过已经本地化的行
  if (line.contains('AppLocalizations.of(context)') ||
      line.contains('AppLocalizations.of(context).')) {
    return false;
  }

  // 跳过导入语句
  if (line.contains('import ')) {
    return false;
  }

  // 跳过字体文件路径等
  if (line.contains('assets/fonts/') ||
      line.contains('.otf') ||
      line.contains('.ttf')) {
    return false;
  }

  // 检查是否包含字符串字面量
  if (line.contains("'") || line.contains('"')) {
    return true;
  }

  return false;
}

/// 检查字符串是否包含中文字符
bool _containsChinese(String text) {
  for (int i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);
    if (code >= 0x4e00 && code <= 0x9fff) {
      return true;
    }
  }
  return false;
}
