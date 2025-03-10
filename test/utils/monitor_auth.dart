import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'check_logger.dart';

/// 权限级别
enum AccessLevel {
  read, // 只读权限
  write, // 写入权限
  admin // 管理权限
}

/// 访问日志条目
class AccessLogEntry {
  final DateTime timestamp;
  final String username;
  final String action;
  final bool success;
  final String? token;
  final String? reason;

  AccessLogEntry({
    required this.timestamp,
    required this.username,
    required this.action,
    required this.success,
    this.token,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'username': username,
        'action': action,
        'success': success,
        if (token != null) 'token': token,
        if (reason != null) 'reason': reason,
      };
}

/// 认证配置
class AuthConfig {
  final AuthMethod method;
  final Duration tokenExpiry;
  final String secret;
  final Map<String, String> users;
  final Map<String, Set<AccessLevel>> roles;

  const AuthConfig({
    this.method = AuthMethod.none,
    this.tokenExpiry = const Duration(hours: 24),
    this.secret = '',
    this.users = const {},
    this.roles = const {},
  });
}

/// 认证管理器
class AuthManager {
  final CheckLogger logger;
  final AuthConfig config;
  final _tokens = <String, AuthToken>{};
  final _accessLog = <AccessLogEntry>[];
  Timer? _cleanupTimer;

  AuthManager({
    CheckLogger? logger,
    AuthConfig? config,
  })  : logger = logger ?? CheckLogger.instance,
        config = config ?? const AuthConfig() {
    _setupCleanup();
  }

  /// 释放资源
  void dispose() {
    _cleanupTimer?.cancel();
    _tokens.clear();
    _accessLog.clear();
  }

  /// 生成令牌
  Future<AuthToken?> generateToken(String username, String password) async {
    if (config.method == AuthMethod.none) return null;

    final storedPassword = config.users[username];
    if (storedPassword == null || !_verifyPassword(password, storedPassword)) {
      logger.warning('认证失败: $username');
      _logAccess(
        username: username,
        action: 'login',
        success: false,
        reason: 'Invalid credentials',
      );
      return null;
    }

    final token = _createToken(username);
    _tokens[token.token] = token;

    _logAccess(
      username: username,
      action: 'login',
      success: true,
      token: token.token,
    );

    return token;
  }

  /// 获取审计日志
  List<AccessLogEntry> getAuditLog({
    DateTime? start,
    DateTime? end,
    String? username,
    String? action,
  }) {
    var filtered = _accessLog.where((entry) {
      if (start != null && entry.timestamp.isBefore(start)) return false;
      if (end != null && entry.timestamp.isAfter(end)) return false;
      if (username != null && entry.username != username) return false;
      if (action != null && entry.action != action) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  /// 吊销令牌
  void revokeToken(String token) {
    final authToken = _tokens.remove(token);
    if (authToken != null) {
      _logAccess(
        username: authToken.userId,
        action: 'revoke',
        success: true,
        token: token,
      );
    }
  }

  /// 验证令牌
  bool verifyToken(String token, Set<AccessLevel> requiredPermissions) {
    final authToken = _tokens[token];
    if (authToken == null || !authToken.isValid) {
      _logAccess(
        username: 'unknown',
        action: 'verify',
        success: false,
        reason: 'Invalid token',
      );
      return false;
    }

    final hasPermissions = requiredPermissions.every(
      (permission) => authToken.permissions.contains(permission),
    );

    _logAccess(
      username: authToken.userId,
      action: 'verify',
      success: hasPermissions,
      token: token,
      reason: hasPermissions ? null : 'Insufficient permissions',
    );

    return hasPermissions;
  }

  /// 创建令牌
  AuthToken _createToken(String userId) {
    final expiry = DateTime.now().add(config.tokenExpiry);
    final tokenData =
        '$userId:${expiry.millisecondsSinceEpoch}:${config.secret}';
    final tokenHash = sha256.convert(utf8.encode(tokenData)).toString();

    return AuthToken(
      userId: userId,
      permissions: config.roles[userId] ?? {AccessLevel.read},
      expiry: expiry,
      token: tokenHash,
    );
  }

  /// 记录访问日志
  void _logAccess({
    required String username,
    required String action,
    required bool success,
    String? token,
    String? reason,
  }) {
    _accessLog.add(AccessLogEntry(
      timestamp: DateTime.now(),
      username: username,
      action: action,
      success: success,
      token: token,
      reason: reason,
    ));
  }

  /// 设置清理定时器
  void _setupCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      final now = DateTime.now();
      _tokens.removeWhere((_, token) => token.expiry.isBefore(now));

      // 保留30天的日志
      final cutoff = now.subtract(const Duration(days: 30));
      _accessLog.removeWhere((entry) => entry.timestamp.isBefore(cutoff));
    });
  }

  /// 验证密码
  bool _verifyPassword(String input, String stored) {
    final inputHash = sha256.convert(utf8.encode(input)).toString();
    return inputHash == stored;
  }
}

/// 认证方式
enum AuthMethod {
  none, // 无认证
  basic, // 基本认证
  token, // 令牌认证
  jwt, // JWT认证
}

/// 认证令牌
class AuthToken {
  final String userId;
  final Set<AccessLevel> permissions;
  final DateTime expiry;
  final String token;

  AuthToken({
    required this.userId,
    required this.permissions,
    required this.expiry,
    required this.token,
  });

  bool get isValid => DateTime.now().isBefore(expiry);

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'permissions': permissions.map((p) => p.toString()).toList(),
        'expiry': expiry.toIso8601String(),
        'token': token,
      };
}
