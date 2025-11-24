import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/providers/theme_provider.dart'; // Import the new provider
import 'package:unipantry/screens/bottom_nav_screen.dart';
import 'package:unipantry/screens/login_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    // 1. Watch the theme mode
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'PantryPal',
      debugShowCheckedModeBanner: false,
      
      // 2. Connect the Mode
      themeMode: themeMode,

      // 3. Define Light Theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal, 
          brightness: Brightness.light
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Soft white
      ),

      // 4. Define Dark Theme
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal, 
          brightness: Brightness.dark // <--- This does the magic
        ),
        useMaterial3: true,
        // Optional: Customize dark background if you don't like pure black
        scaffoldBackgroundColor: const Color(0xFF121212), 
      ),

      home: authState.when(
        data: (user) {
          if (user != null) {
            return const BottomNavScreen();
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Error: ${err.toString()}')),
        ),
      ),
    );
  }
}