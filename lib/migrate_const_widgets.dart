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
      String content = await entity.readAsString();
      bool edited = false;

      // We know there are still leftover `const ` modifiers in front of Widgets that have `Theme.of(context)` inside.
      // E.g. `const EdgeInsets...` is fine, but `const Text(..., style: TextStyle(color: Theme.of...))` is bad.
      // A simple regex to just find `const ` followed by `\w+\(` and within the next 200 chars find `Theme.of`
      // Let's just do a naive regex that removes "const " if "Theme.of" is on the same line, or the next line.
      // But multi-line is hard.
      // Let's do this: if a file has "Theme.of(context)", just remove `const` from `const Text(`, `const Icon(`, `const Padding(`, `const Column(`, `const Row(`, `const Container(`, `const SizedBox(`, `const Center(`, `const Expanded(`, `const Flexible(`, `const Spacer(`, `const Divider(`, `const CircleAvatar(`, `const Card(`, `const ListTile(`

      final widgetsToStrip = [
        'Text',
        'Icon',
        'Padding',
        'Column',
        'Row',
        'Container',
        'SizedBox',
        'Center',
        'Expanded',
        'Flexible',
        'Spacer',
        'Divider',
        'CircleAvatar',
        'Card',
        'ListTile',
        'BoxDecoration',
        'TextStyle',
        'BorderSide',
        'InputDecoration',
        'Widget',
        'BoxConstraints',
        'BottomNavigationBarItem',
        'DrawerHeader',
        'LinearProgressIndicator',
        'CircularProgressIndicator',
        'TabBarView',
        'Tab',
        'AlertDialog',
        '_SettingsCard',
        '_SectionHeader',
        'Checkbox',
        'RichText',
        'TextSpan',
        'Positioned',
        'Align',
        '_InfoRow'
      ];

      for (final w in widgetsToStrip) {
        final p = 'const $w(';
        if (content.contains(p)) {
          // Only replace if the file actually contains Theme.of just to be relatively safe
          if (content.contains('Theme.of')) {
            content = content.replaceAll(p, '$w(');
            edited = true;
          }
        }
      }

      if (edited) {
        await entity.writeAsString(content);
        editedCount++;
        print('Fixed widget consts in ${entity.path}');
      }
    }
  }

  print('Fixed widget consts in $editedCount files.');
}
