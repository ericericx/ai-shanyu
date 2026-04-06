import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/config/app_config.dart';
import 'core/config/development.dart';
import 'core/router/app_router.dart';
import 'firebase_options_development.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ProviderScope(
      child: ShanYuApp(config: developmentConfig),
    ),
  );
}

ThemeData _buildTheme() {
  // 標題字型：Playfair Display（優雅襯線體）
  final headlineStyle = GoogleFonts.playfairDisplay();
  // 內文字型：Inter（清晰無襯線體）
  final bodyStyle = GoogleFonts.inter();

  final baseTextTheme = TextTheme(
    displayLarge: headlineStyle,
    displayMedium: headlineStyle,
    displaySmall: headlineStyle,
    headlineLarge: headlineStyle,
    headlineMedium: headlineStyle,
    bodyLarge: bodyStyle,
    bodyMedium: bodyStyle,
    bodySmall: bodyStyle,
    labelLarge: bodyStyle,
    labelMedium: bodyStyle,
    labelSmall: bodyStyle,
  );

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB82020)),
    useMaterial3: true,
    textTheme: baseTextTheme,
    fontFamilyFallback: const ['Noto Sans TC'],
  );
}

class ShanYuApp extends ConsumerWidget {
  const ShanYuApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: config.appDisplayName,
      debugShowCheckedModeBanner: config.isDevelopment,
      theme: _buildTheme(),
      routerConfig: router,
    );
  }
}
