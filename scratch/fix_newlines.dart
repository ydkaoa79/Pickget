import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  final content = file.readAsStringSync();
  final fixed = content.replaceAll('\\n', '\n');
  file.writeAsStringSync(fixed);
  print('Restored line endings.');
}
