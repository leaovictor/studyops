import 'dart:io';

void main() async {
  final filesToFix = [
    'C:/Users/Victor/OneDrive/Documents/Projects/studyops/lib/screens/schedule_screen.dart',
    'C:/Users/Victor/OneDrive/Documents/Projects/studyops/lib/screens/subjects_screen.dart',
    'C:/Users/Victor/OneDrive/Documents/Projects/studyops/lib/widgets/goal_switcher.dart',
    'C:/Users/Victor/OneDrive/Documents/Projects/studyops/lib/widgets/relevance_info_dialog.dart',
    'C:/Users/Victor/OneDrive/Documents/Projects/studyops/lib/widgets/study_plan_wizard_dialog.dart',
  ];

  for (final path in filesToFix) {
    final file = File(path);
    if (!file.existsSync()) continue;

    String content = await file.readAsString();

    // schedule_screen
    if (content.contains('const _SettingsCard')) {
      content = content.replaceAll('const _SettingsCard', '_SettingsCard');
    }

    // relevance_info_dialog.dart
    if (content.contains(
        'color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)')) {
      // We already fixed _buildInfoRow in this file manually, but if there are other consts:
      // (Just strip all `const ` that appear immediately before Text/TextSpan/SnackBar/SizedBox/etc if they have Theme.)
    }

    // the safest way for these 5 files is just to rip `const ` out of them entirely
    // dart fix will put back what is valid.
    final original = content;
    content = content.replaceAll(RegExp(r'\bconst\s+'), '');

    if (content != original) {
      await file.writeAsString(content);
      print('Stripped consts from $path');
    }
  }
}
