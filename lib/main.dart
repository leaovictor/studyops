import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 App starting initialization...');

  try {
    debugPrint('📦 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable offline persistence and unlimited caching for Firestore PWA
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('✅ Firebase initialized successfully.');
  } catch (e, stack) {
    debugPrint('❌ Firebase initialization error: $e');
    debugPrint(stack.toString());
  }

  try {
    debugPrint('💾 Loading Shared Preferences...');
    final sharedPrefs = await SharedPreferences.getInstance();
    debugPrint('✅ Shared Preferences loaded.');

    try {
      debugPrint('📅 Initializing Date Formatting...');
      await initializeDateFormatting('pt_BR');
      debugPrint('✅ Date Formatting initialized.');
    } catch (e) {
      debugPrint('⚠️ Date formatting error: $e');
    }

    debugPrint('🏗️ Running App...');
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const StudyOpsApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('💥 CRITICAL STARTUP ERROR: $e');
    debugPrint(stack.toString());

    // Fallback UI in case of fatal error before runApp
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SelectableText(
                  'Ocorreu um erro fatal ao iniciar o app:\n\n$e'),
            ),
          ),
        ),
      ),
    );
  }
}

class StudyOpsApp extends ConsumerWidget {
  const StudyOpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'StudyOps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
