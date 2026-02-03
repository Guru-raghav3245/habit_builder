import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth
import 'package:habitit/screens/home_screen.dart';
import 'package:habitit/screens/login_screen.dart'; // Import Login Screen
import 'package:habitit/services/notification_service.dart';
import 'package:habitit/providers/settings_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  
  // You already have this in your file, just ensuring it's kept
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'HabitIt',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      // ... keep your existing theme config ...
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      
      // CHANGE: Replace 'home: const HomeScreen()' with this StreamBuilder
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. While checking auth status, show a spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // 2. If user is logged in, go to Home
          if (snapshot.hasData) {
            return const HomeScreen(); 
          }
          
          // 3. Otherwise, show Login
          return const LoginScreen(); 
        },
      ),
    );
  }
}