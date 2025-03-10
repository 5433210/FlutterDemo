import 'dart:convert';
import 'dart:io';

/// 分支覆盖率
class BranchCoverage {
  final int blockNumber;
  final int branchNumber;
  final int executionCount;

  const BranchCoverage({
    required this.blockNumber,
    required this.branchNumber,
    required this.executionCount,
  });

  Map<String, dynamic> toJson() => {
        'block': blockNumber,
        'branch': branchNumber,
        'count': executionCount,
      };
}

/// 覆盖率指标
class CoverageMetrics {
  final int lineCoverage;
  final int branchCoverage;
  final int totalLines;
  final int coveredLines;
  final int totalBranches;
  final int coveredBranches;

  const CoverageMetrics({
    required this.lineCoverage,
    required this.branchCoverage,
    required this.totalLines,
    required this.coveredLines,
    required this.totalBranches,
    required this.coveredBranches,
  });

  Map<String, dynamic> toJson() => {
        'lineCoverage': lineCoverage,
        'branchCoverage': branchCoverage,
        'totalLines': totalLines,
        'coveredLines': coveredLines,
        'totalBranches': totalBranches,
        'coveredBranches': coveredBranches,
      };
}

/// 函数覆盖率
class FunctionCoverage {
  final String name;
  final int executionCount;

  const FunctionCoverage({
    required this.name,
    required this.executionCount,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': executionCount,
      };
}

/// LCOV 文档
class LcovDocument {
  final List<LcovRecord> records;

  const LcovDocument(this.records);

  /// 计算覆盖率
  CoverageMetrics calculateMetrics() {
    var totalLines = 0;
    var coveredLines = 0;
    var totalBranches = 0;
    var coveredBranches = 0;

    for (final record in records) {
      totalLines += record.lines.length;
      coveredLines += record.lines.where((l) => l.executionCount > 0).length;

      totalBranches += record.branches.length;
      coveredBranches +=
          record.branches.where((b) => b.executionCount > 0).length;
    }

    return CoverageMetrics(
      lineCoverage:
          totalLines > 0 ? (coveredLines / totalLines * 100).round() : 0,
      branchCoverage: totalBranches > 0
          ? (coveredBranches / totalBranches * 100).round()
          : 0,
      totalLines: totalLines,
      coveredLines: coveredLines,
      totalBranches: totalBranches,
      coveredBranches: coveredBranches,
    );
  }

  /// 生成报告
  Future<void> generateReport(String path) async {
    final metrics = calculateMetrics();
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'metrics': metrics.toJson(),
      'files': records.map((r) => r.toJson()).toList(),
    };

    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
  }

  /// 从文件加载
  static Future<LcovDocument> fromFile(String path) async {
    final content = await File(path).readAsString();
    return parse(content);
  }

  /// 解析 LCOV 内容
  static LcovDocument parse(String content) {
    final records = <LcovRecord>[];
    LcovRecord? current;

    for (final line in content.split('\n')) {
      if (line.startsWith('SF:')) {
        current = LcovRecord(
          source: line.substring(3),
          lines: [],
          functions: [],
          branches: [],
        );
        records.add(current);
      } else if (line.startsWith('DA:')) {
        final parts = line.substring(3).split(',');
        current?.lines.add(LineCoverage(
          lineNumber: int.parse(parts[0]),
          executionCount: int.parse(parts[1]),
        ));
      }
    }

    return LcovDocument(records);
  }
}

/// LCOV 记录
class LcovRecord {
  final String source;
  final List<LineCoverage> lines;
  final List<FunctionCoverage> functions;
  final List<BranchCoverage> branches;

  const LcovRecord({
    required this.source,
    required this.lines,
    required this.functions,
    required this.branches,
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'lines': lines.map((l) => l.toJson()).toList(),
        'functions': functions.map((f) => f.toJson()).toList(),
        'branches': branches.map((b) => b.toJson()).toList(),
      };
}

/// 行覆盖率
class LineCoverage {
  final int lineNumber;
  final int executionCount;

  const LineCoverage({
    required this.lineNumber,
    required this.executionCount,
  });

  Map<String, dynamic> toJson() => {
        'line': lineNumber,
        'count': executionCount,
      };
}
