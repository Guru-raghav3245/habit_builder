import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_builder/screens/home_screen.dart';
import 'package:habit_builder/services/notification_service.dart';
import 'package:habit_builder/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Strict Daily Habits',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 400),
      themeAnimationCurve: Curves.easeInOut,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
