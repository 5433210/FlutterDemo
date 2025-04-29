import 'dart:io';

void main() async {
  // Run flutter gen-l10n
  print('Running flutter gen-l10n...');
  final genL10nResult = await Process.run('flutter', ['gen-l10n']);
  
  if (genL10nResult.exitCode != 0) {
    print('Error running flutter gen-l10n:');
    print(genL10nResult.stderr);
    return;
  }
  
  print('Successfully regenerated localization files.');
}
