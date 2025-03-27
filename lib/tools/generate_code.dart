import 'dart:io';

void main() async {
  print('Running build_runner to generate code files...');

  // Clean first to ensure we don't have stale files
  final cleanResult = await Process.run(
    'flutter',
    ['pub', 'run', 'build_runner', 'clean'],
    runInShell: true,
  );

  if (cleanResult.exitCode != 0) {
    print('Error during clean:');
    print(cleanResult.stderr);
    return;
  }

  print('Clean successful. Building generated files...');

  // Build with delete-conflicting-outputs flag to handle conflicts
  final buildResult = await Process.run(
    'flutter',
    ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    runInShell: true,
  );

  if (buildResult.exitCode != 0) {
    print('Error during build:');
    print(buildResult.stderr);
    return;
  }

  print('Build successful. Generated files are ready!');
  print(buildResult.stdout);
}
