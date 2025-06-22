#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// 本地化检查脚本
/// 用于验证ARB文件的完整性和一致性
Future<void> main() async {
  print('🌐 开始检查本地化配置...\n');

  // 检查配置文件
  await _checkL10nConfig();

  // 检查ARB文件
  await _checkArbFiles();

  // 检查生成的文件
  await _checkGeneratedFiles();

  // 检查硬编码文本
  await _checkHardcodedText();

  print('\n✅ 本地化检查完成！');
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

  Map<String, Map<String, dynamic>> arbContents = {};

  for (final arbFile in arbFiles) {
    final file = File(arbFile);
    final filename = arbFile.split('/').last;
    print('   - $filename');

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      arbContents[filename] = json;

      final locale = json['@@locale'] as String?;
      final keyCount = json.keys.where((key) => !key.startsWith('@')).length;
      print('     语言: $locale, 键数量: $keyCount');
    } catch (e) {
      print('     ❌ 解析失败: $e');
    }
  }

  // 检查键的一致性
  await _checkKeyConsistency(arbContents);
}

Future<void> _checkKeyConsistency(
    Map<String, Map<String, dynamic>> arbContents) async {
  if (arbContents.length < 2) return;

  print('\n🔍 检查键的一致性...');

  final allKeys = <String, Set<String>>{};

  arbContents.forEach((filename, content) {
    final keys = content.keys.where((key) => !key.startsWith('@')).toSet();
    allKeys[filename] = keys;
  });

  final fileNames = allKeys.keys.toList();
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

Future<void> _checkHardcodedText() async {
  print('\n🔍 检查硬编码文本...');

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

  for (final filePath in dartFiles) {
    final file = File(filePath);
    try {
      final lines = await file.readAsLines();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];

        // 增强的硬编码文本检查
        final hardcodedTexts = _findHardcodedChineseText(line);
        for (final text in hardcodedTexts) {
          hardcodedCount++;
          final fileName = filePath.split('/').last.split('\\').last;
          print('⚠️  $fileName:${i + 1} - ${line.trim()}');
          break; // 每行只报告一次，避免重复
        }
      }
    } catch (e) {
      print('❌ 无法读取文件: $filePath');
    }
  }

  if (hardcodedCount == 0) {
    print('✅ 没有发现硬编码中文文本');
  } else {
    print('❌ 发现 $hardcodedCount 处硬编码中文文本');
    print('💡 请使用 AppLocalizations.of(context)!.keyName 替换硬编码文本');
  }
}

/// 查找硬编码中文文本的增强版本
List<String> _findHardcodedChineseText(String line) {
  final List<String> hardcodedTexts = [];

  // 跳过注释行
  final trimmedLine = line.trim();
  if (trimmedLine.startsWith('//') ||
      trimmedLine.startsWith('/*') ||
      trimmedLine.startsWith('*')) {
    return hardcodedTexts;
  }

  // 跳过日志语句
  if (line.contains('AppLogger.') ||
      line.contains('EditPageLogger.') ||
      line.contains('developer.log') ||
      line.contains('debugPrint') ||
      line.contains('print(')) {
    return hardcodedTexts;
  }

  // 跳过已经本地化的行
  if (line.contains('AppLocalizations.of(context)') ||
      line.contains('AppLocalizations.of(context).')) {
    return hardcodedTexts;
  }
  // 使用正则表达式查找所有中文字符串
  final patterns = [
    // 单引号中的中文
    RegExp(r"'[^']*[\u4e00-\u9fff][^']*'"),
    // 双引号中的中文
    RegExp(r'"[^"]*[\u4e00-\u9fff][^"]*"'),
    // title: '中文' 模式
    RegExp(r'''title:\s*['"][^'"]*[\u4e00-\u9fff][^'"]*['"]'''),
    // label: '中文' 模式
    RegExp(r'''label:\s*['"][^'"]*[\u4e00-\u9fff][^'"]*['"]'''),
    // text: '中文' 模式
    RegExp(r'''text:\s*['"][^'"]*[\u4e00-\u9fff][^'"]*['"]'''),
    // hint: '中文' 模式
    RegExp(r'''hint:\s*['"][^'"]*[\u4e00-\u9fff][^'"]*['"]'''),
    // content: '中文' 模式
    RegExp(r'''content:\s*['"][^'"]*[\u4e00-\u9fff][^'"]*['"]'''),
    // message: '中文' 模式
    RegExp(r'''message:\s*['"][^'"]*[\u4e00-\u9fff][^'"]*['"]'''),
  ];

  for (final pattern in patterns) {
    final matches = pattern.allMatches(line);
    for (final match in matches) {
      final text = match.group(0)!;
      if (!hardcodedTexts.contains(text)) {
        hardcodedTexts.add(text);
      }
    }
  }

  return hardcodedTexts;
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
