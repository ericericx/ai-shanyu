import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class ShanYuApp extends ConsumerWidget {
  const ShanYuApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: config.appDisplayName,
      debugShowCheckedModeBanner: config.isDevelopment,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C4033)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
