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
      List<String> lines = await entity.readAsLines();
      bool edited = false;

      for (int i = 0; i < lines.length; i++) {
        String originalLine = lines[i];
        String newLine = originalLine;

        bool hasTheme = false;
        for (var k in replaces.keys) {
          if (newLine.contains(k)) {
            newLine = newLine.replaceAll(k, replaces[k]!);
            hasTheme = true;
          }
        }

        if (hasTheme) {
          // Strip const safely from the beginning of THIS line only if it exists
          newLine = newLine.replaceAll(RegExp(r'\bconst\s+'), '');
          edited = true;
          lines[i] = newLine;

          // Note: If const was on a previous line, dart fix will catch it!
        }
      }

      if (edited) {
        await entity.writeAsString(lines.join('\n'));
        editedCount++;
        print('Migrated safely ${entity.path}');
      }
    }
  }

  print('Migrated safely $editedCount files.');
}
