import 'dart:io';

void main() async {
  final output = File('analyze_output.txt');
  if (!output.existsSync()) return;

  final lines = await output.readAsLines();

  // Track files and lines to fix
  final fixes = <String, Set<int>>{};

  for (final line in lines) {
    if (!line.contains('lib\\')) continue;

    // Check for const error
    if (line.contains("Methods can't be invoked in constant expressions")) {
      final match = RegExp(r'lib\\([^:]+):(\d+):(\d+)').firstMatch(line);
      if (match != null) {
        final fileStr = 'lib/${match.group(1)!.replaceAll('\\', '/')}';
        final lineNum = int.parse(match.group(2)!) - 1; // 0-indexed

        fixes.putIfAbsent(fileStr, () => {}).add(lineNum);
      }
    }
  }

  int editedCount = 0;

  for (final entry in fixes.entries) {
    final file = File(entry.key);
    if (!file.existsSync()) continue;

    final fileLines = await file.readAsLines();
    bool edited = false;

    // We process from bottom up or just iterate, but removing 'const ' from a specific line is safe.
    for (final lineNum in entry.value) {
      if (lineNum < fileLines.length) {
        // The error points to the start of Theme.of,
        // but the `const` might be earlier on the same line.
        if (fileLines[lineNum].contains('const ')) {
          fileLines[lineNum] =
              fileLines[lineNum].replaceAll(RegExp(r'\bconst\s+'), '');
          edited = true;
        } else {
          // Sometimes the const is on the previous line e.g.
          // const BoxConstraints(
          //    color: Theme.of...
          // Let's search upwards up to 3 lines
          for (int up = lineNum; up >= 0 && up >= lineNum - 5; up--) {
            if (fileLines[up].contains('const ')) {
              fileLines[up] =
                  fileLines[up].replaceAll(RegExp(r'\bconst\s+'), '');
              edited = true;
              break;
            }
          }
        }
      }
    }

    if (edited) {
      await file.writeAsString(fileLines.join('\n'));
      editedCount++;
      print('Fixed consts in ${entry.key}');
    }
  }

  print('Fixed $editedCount files based on analyzer output.');
}
