import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../utils/alert_notifier.dart';

/// 认证配置
class AuthConfig {
  final Duration tokenExpiry;
  final int maxLoginAttempts;
  final Duration lockoutDuration;
  final bool requireMfa;
  final Set<String> allowedRoles;

  const AuthConfig({
    this.tokenExpiry = const Duration(hours: 1),
    this.maxLoginAttempts = 3,
    this.lockoutDuration = const Duration(minutes: 15),
    this.requireMfa = false,
    this.allowedRoles = const {'user', 'admin'},
  });
}

/// 认证管理器
class AuthManager {
  final AlertNotifier notifier;
  final AuthConfig config;
  final _users = <String, UserInfo>{};
  final _tokens = <String, TokenInfo>{};
  final _loginAttempts = <String, LoginAttempts>{};

  AuthManager({
    required this.notifier,
    AuthConfig? config,
  }) : config = config ?? const AuthConfig();

  /// 清理过期token
  void cleanup() {
    final now = DateTime.now();
    _tokens.removeWhere((_, info) => info.expiresAt.isBefore(now));
  }

  /// 检查权限
  bool hasRole(String token, String role) {
    final info = _tokens[token];
    if (info == null) return false;

    final user = _users[info.username];
    return user?.roles.contains(role) ?? false;
  }

  /// 用户登录
  Future<String> login(String username, String password) async {
    final user = _users[username];
    if (user == null) {
      throw StateError('用户不存在');
    }

    final attempts = _getLoginAttempts(username);
    if (attempts.isLocked) {
      throw StateError('账户已锁定');
    }

    final hash = _hashPassword(password, user.salt);
    if (hash != user.passwordHash) {
      await _handleFailedLogin(username);
      throw StateError('密码错误');
    }

    attempts.reset();
    final token = _generateToken();
    _tokens[token] = TokenInfo(
      username: username,
      expiresAt: DateTime.now().add(config.tokenExpiry),
    );

    notifier.notify(AlertBuilder()
        .message('用户登录成功: $username')
        .level(AlertLevel.info)
        .build());

    return token;
  }

  /// 注销
  void logout(String token) {
    final info = _tokens.remove(token);
    if (info != null) {
      notifier.notify(AlertBuilder()
          .message('用户注销: ${info.username}')
          .level(AlertLevel.info)
          .build());
    }
  }

  /// 注册用户
  Future<void> register(
      String username, String password, Set<String> roles) async {
    if (_users.containsKey(username)) {
      throw StateError('用户已存在');
    }

    if (!roles.every(config.allowedRoles.contains)) {
      throw ArgumentError('包含无效角色');
    }

    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);

    _users[username] = UserInfo(
      username: username,
      passwordHash: hash,
      salt: salt,
      roles: roles,
    );

    notifier.notify(AlertBuilder()
        .message('新用户注册: $username')
        .level(AlertLevel.info)
        .addData('roles', roles.toList())
        .build());
  }

  /// 验证token
  bool verifyToken(String token) {
    final info = _tokens[token];
    if (info == null) return false;

    if (info.expiresAt.isBefore(DateTime.now())) {
      _tokens.remove(token);
      return false;
    }

    return true;
  }

  /// 生成盐值
  String _generateSalt() {
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    return base64Encode(sha256.convert(utf8.encode(random)).bytes);
  }

  /// 生成token
  String _generateToken() {
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    return base64Encode(sha256.convert(utf8.encode(random)).bytes);
  }

  /// 获取登录尝试记录
  LoginAttempts _getLoginAttempts(String username) {
    return _loginAttempts.putIfAbsent(
      username,
      () => LoginAttempts(maxAttempts: config.maxLoginAttempts),
    );
  }

  /// 处理登录失败
  Future<void> _handleFailedLogin(String username) async {
    final attempts = _getLoginAttempts(username);
    attempts.increment();

    if (attempts.isLocked) {
      notifier.notify(AlertBuilder()
          .message('账户锁定: $username')
          .level(AlertLevel.warning)
          .addData('attempts', attempts.count)
          .addData('lockout_duration', config.lockoutDuration.inMinutes)
          .build());

      await Future.delayed(config.lockoutDuration);
      attempts.reset();
    }
  }

  /// 密码哈希
  String _hashPassword(String password, String salt) {
    final data = utf8.encode(password + salt);
    return base64Encode(sha256.convert(data).bytes);
  }
}

/// 登录尝试记录
class LoginAttempts {
  final int maxAttempts;
  int count = 0;
  DateTime? lastFailure;

  LoginAttempts({required this.maxAttempts});

  bool get isLocked => count >= maxAttempts;

  void increment() {
    count++;
    lastFailure = DateTime.now();
  }

  void reset() {
    count = 0;
    lastFailure = null;
  }
}

/// Token信息
class TokenInfo {
  final String username;
  final DateTime expiresAt;

  const TokenInfo({
    required this.username,
    required this.expiresAt,
  });
}

/// 用户信息
class UserInfo {
  final String username;
  final String passwordHash;
  final String salt;
  final Set<String> roles;

  const UserInfo({
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.roles,
  });
}
