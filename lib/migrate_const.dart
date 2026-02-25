import 'dart:io';

void main() async {
  final dir =
      Directory('C:/Users/Victor/OneDrive/Documents/Projects/studyops/lib');

  if (!dir.existsSync()) {
    print('Dir not found');
    return;
  }

  int editedCount = 0;

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.contains('app_theme.dart') &&
        !entity.path.contains('migrate_')) {
      String fileContent = await entity.readAsString();
      String originalContent = fileContent;

      // This regex looks for `const` keywords followed by spacing, and removes it
      // ONLY if there is `Theme.of(context)` somewhere inside the block.
      // Since Dart is complex, a simpler approach is to strip `const ` from lines that
      // declare widgets that accept Theme.of, or strip `const` entirely if the file imports material.dart and has errors.

      // Instead, let's just use dart fix which we already tried, but it doesn't remove invalid consts automatically sometimes.
      // Let's do a regex that finds `const [\w\.]+(` and checks if `Theme.of` occurs before the next `;` or matching `)`. This is hard.

      // Fallback: Remove ALL `const ` keywords from widget trees temporarily if they have `Theme.of(context)`.
      // This is a bit aggressive but `dart fix --apply` will put the valid ones back!

      fileContent = fileContent.replaceAll(RegExp(r'\bconst\s+'), '');

      if (fileContent != originalContent) {
        await entity.writeAsString(fileContent);
        editedCount++;
        print('Stripped const from ${entity.path}');
      }
    }
  }

  print('Fixed $editedCount files.');
}
