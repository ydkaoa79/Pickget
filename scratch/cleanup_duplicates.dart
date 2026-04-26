import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  final lines = file.readAsLinesSync();

  int deleteStart = -1;
  int deleteEnd = -1;

  for (int i = 0; i < lines.length; i++) {
    // Look for the duplicate, corrupted start after the first clean one.
    if (i > 300 && lines[i].contains('_allPosts = [') && (lines[i].contains('?') || lines[i-1].contains('?'))) {
      deleteStart = i - 1; // Include the comment line if possible
    }
    if (deleteStart != -1 && lines[i] == '  }' && i > deleteStart) {
      deleteEnd = i + 1;
      break;
    }
  }

  if (deleteStart != -1 && deleteEnd != -1) {
    print('Deleting duplicate block from index $deleteStart to $deleteEnd');
    lines.removeRange(deleteStart, deleteEnd);
    file.writeAsStringSync(lines.join('\n'));
    print('Cleaned up duplicate corrupted code.');
  } else {
    print('Could not find duplicate corrupted block.');
  }
}
