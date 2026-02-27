import 'dart:io';

void main() async {
  final dir =
      Directory('C:/Users/Victor/OneDrive/Documents/Projects/studyops/lib');

  if (!dir.existsSync()) {
    print('Dir not found');
    return;
  }

  int editedCount = 0;

  final Map<String, String> replaces = {
    'AppTheme.bg0': 'Theme.of(context).scaffoldBackgroundColor',
    'AppTheme.bg1': 'Theme.of(context).colorScheme.surface',
    'AppTheme.bg2':
        '(Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface)',
    'AppTheme.bg3': 'Theme.of(context).colorScheme.surfaceContainerHighest',
    'AppTheme.textPrimary':
        '(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)',
    'AppTheme.textSecondary':
        '(Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)',
    'AppTheme.textMuted':
        '(Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey)',
    'AppTheme.border': 'Theme.of(context).dividerColor',
  };

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.contains('app_theme.dart') &&
        !entity.path.contains('migrate_')) {
      String content = await entity.readAsString();
      bool edited = false;

      for (var k in replaces.keys) {
        if (content.contains(k)) {
          // This time, we only replace the exact references.
          // BUT if they are inside a const list or object, it's a problem.
          // So we specifically look for `const ` preceeding it and carefully strip `const ` from that specific Widget constructor.
          // Example: const Text('Hello', style: TextStyle(color: AppTheme.textPrimary)) -> Text('Hello', style: TextStyle(color: Theme.of(context)...))

          content = content.replaceAll(
              RegExp(r'const\s+([A-Z][a-zA-Z0-9_]*\([^)]*' +
                  RegExp.escape(k) +
                  r')'),
              r'$1');

          // And also catch `const TextStyle(color: AppTheme.textPrimary)`
          content = content.replaceAll(
              RegExp(r'const\s+(TextStyle\([^)]*' + RegExp.escape(k) + r')'),
              r'$1');

          // Finally replace the actual property
          content = content.replaceAll(k, replaces[k]!);
          edited = true;
        }
      }

      if (edited) {
        await entity.writeAsString(content);
        editedCount++;
        print('Migrated ${entity.path}');
      }
    }
  }

  print('Migrated $editedCount files.');
}
