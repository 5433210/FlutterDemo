import 'dart:io';

import 'package:path/path.dart' as path;

void main() async {
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    print('Coverage file not found');
    exit(1);
  }

  final lines = lcovFile.readAsLinesSync();
  int totalLines = 0;
  int coveredLines = 0;
  String currentFile = '';
  bool isLibFile = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    // 检查是否是库文件
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      isLibFile = currentFile.startsWith('lib/') &&
          !currentFile.contains('.g.dart') &&
          !currentFile.contains('.freezed.dart');
    }

    // 只统计库文件
    if (!isLibFile) continue;

    // 统计行数
    if (line.startsWith('LF:')) {
      totalLines += int.parse(line.substring(3));
    }
    if (line.startsWith('LH:')) {
      coveredLines += int.parse(line.substring(3));
    }
  }

  if (totalLines == 0) {
    print('No lines to cover');
    exit(1);
  }

  final coverage = (coveredLines / totalLines * 100).toStringAsFixed(2);
  print(coverage);

  // 生成详细报告
  await _generateDetailedReport(lines);
}

Future<void> _generateDetailedReport(List<String> lines) async {
  final report = StringBuffer();
  report.writeln('Coverage Report');
  report.writeln('===============\n');

  String currentFile = '';
  Map<String, int> fileTotalLines = {};
  Map<String, int> fileCoveredLines = {};
  Map<String, List<int>> fileUncoveredLines = {};

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileTotalLines[currentFile] = 0;
      fileCoveredLines[currentFile] = 0;
      fileUncoveredLines[currentFile] = [];
    }

    if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      final lineNumber = int.parse(parts[0]);
      final executionCount = int.parse(parts[1]);

      fileTotalLines[currentFile] = (fileTotalLines[currentFile] ?? 0) + 1;
      if (executionCount > 0) {
        fileCoveredLines[currentFile] =
            (fileCoveredLines[currentFile] ?? 0) + 1;
      } else {
        fileUncoveredLines[currentFile]?.add(lineNumber);
      }
    }
  }

  // 按覆盖率排序
  final sortedFiles = fileTotalLines.keys.toList()
    ..sort((a, b) {
      final coverageA = fileCoveredLines[a]! / fileTotalLines[a]! * 100;
      final coverageB = fileCoveredLines[b]! / fileTotalLines[b]! * 100;
      return coverageB.compareTo(coverageA);
    });

  // 生成报告
  for (final file in sortedFiles) {
    if (!file.startsWith('lib/')) continue;
    if (file.contains('.g.dart') || file.contains('.freezed.dart')) continue;

    final total = fileTotalLines[file]!;
    final covered = fileCoveredLines[file]!;
    final coverage = (covered / total * 100).toStringAsFixed(2);

    report.writeln('File: $file');
    report.writeln('Coverage: $coverage%');
    report.writeln('Lines: $covered/$total');

    if (fileUncoveredLines[file]?.isNotEmpty ?? false) {
      report
          .writeln('Uncovered lines: ${fileUncoveredLines[file]?.join(', ')}');
    }
    report.writeln('');
  }

  // 保存报告
  final reportDir = Directory('coverage/reports');
  if (!reportDir.existsSync()) {
    reportDir.createSync(recursive: true);
  }

  final reportFile = File(path.join(reportDir.path,
      'coverage_report_${DateTime.now().toIso8601String().replaceAll(':', '-')}.txt'));

  await reportFile.writeAsString(report.toString());
}
