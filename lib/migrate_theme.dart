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
        !entity.path.contains('app_theme.dart')) {
      String content = await entity.readAsString();
      bool edited = false;

      final Map<String, String> replaces = {
        'Theme.of(context).scaffoldBackgroundColor':
            'Theme.of(context).scaffoldBackgroundColor',
        'Theme.of(context).colorScheme.surface':
            'Theme.of(context).colorScheme.surface',
        'Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface':
            'Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface',
        'Theme.of(context).colorScheme.surfaceContainerHighest':
            'Theme.of(context).colorScheme.surfaceContainerHighest',
        'Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white':
            'Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white',
        'Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey':
            'Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey',
        'Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey':
            'Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey',
        'Theme.of(context).dividerColor': 'Theme.of(context).dividerColor',
      };

      for (var k in replaces.keys) {
        if (content.contains(k)) {
          content = content.replaceAll(k, replaces[k]!);
          edited = true;
        }
      }

      if (edited) {
        // also we need to fix const AppTheme.text... to non-const, this is tricky via simple replace
        content = content.replaceAll(
            RegExp(r'const\s+(TextStyle.*?Theme\.of\()'), r'$1');
        content =
            content.replaceAll(RegExp(r'const\s+(.*?Theme\.of\()'), r'$1');

        await entity.writeAsString(content);
        editedCount++;
        print('Fixed ${entity.path}');
      }
    }
  }

  print('Fixed $editedCount files.');
}
