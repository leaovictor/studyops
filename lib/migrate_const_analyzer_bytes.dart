import 'dart:io';

void main() async {
  // Use ripgrep approach or just read the analyze text file
  final file = File('analyze_output.txt');
  if (!file.existsSync()) return;

  // Read as string and manually split by lines to avoid encoding issues
  final bytes = await file.readAsBytes();
  final String content = String.fromCharCodes(bytes);
  final lines = content.split('\n');

  final Map<String, Set<int>> filesToFix = {};

  for (final line in lines) {
    if (line.contains("Methods can't be invoked in constant expressions")) {
      final match = RegExp(r'lib\\([^:]+):(\d+):(\d+)').firstMatch(line);
      if (match != null) {
        final path = 'lib/${match.group(1)!.replaceAll('\\', '/')}';
        final lineNum = int.parse(match.group(2)!) - 1;
        filesToFix.putIfAbsent(path, () => {}).add(lineNum);
      }
    }
  }

  int editedCount = 0;

  for (final path in filesToFix.keys) {
    final targetFile =
        File('C:/Users/Victor/OneDrive/Documents/Projects/studyops/$path');
    if (!targetFile.existsSync()) continue;

    final targetLines = await targetFile.readAsLines();
    bool edited = false;

    for (final lineNum in filesToFix[path]!) {
      if (lineNum < targetLines.length) {
        // Look within 8 lines upwards to find the nearest `const ` modifier that is decorating this widget
        for (int i = lineNum; i >= 0 && i >= lineNum - 8; i--) {
          if (targetLines[i].contains('const ')) {
            targetLines[i] = targetLines[i].replaceFirst('const ', '');
            edited = true;
            break;
          }
        }
      }
    }

    if (edited) {
      await targetFile.writeAsString(targetLines.join('\n'));
      editedCount++;
      print('Fixed consts in $path');
    }
  }

  print('Fixed $editedCount files automatically.');
}
