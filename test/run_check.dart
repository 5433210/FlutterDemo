import 'dart:io';

void main() async {
  print('\n检查操作系统环境...\n');

  final isWindows = Platform.isWindows;
  final isMacOS = Platform.isMacOS;
  final isLinux = Platform.isLinux;

  print('检测到的操作系统: ${Platform.operatingSystem}');
  print('系统版本: ${Platform.operatingSystemVersion}\n');

  if (isWindows) {
    print('在 Windows 环境下运行检查...');
    await _runWindowsCheck();
  } else if (isMacOS || isLinux) {
    print('在 Unix 环境下运行检查...');
    await _runUnixCheck();
  } else {
    print('错误: 不支持的操作系统');
    exit(1);
  }
}

Future<void> _runUnixCheck() async {
  // 确保脚本有执行权限
  await Process.run('chmod', ['+x', 'test/check_environment.sh']);

  final result = await Process.run('./test/check_environment.sh', []);
  print(result.stdout);

  if (result.exitCode != 0) {
    print('错误: Unix 环境检查失败');
    print(result.stderr);
    exit(1);
  }
}

Future<void> _runWindowsCheck() async {
  final result =
      await Process.run('cmd', ['/c', 'test\\check_environment.bat']);
  print(result.stdout);

  if (result.exitCode != 0) {
    print('错误: Windows 环境检查失败');
    print(result.stderr);
    exit(1);
  }
}
