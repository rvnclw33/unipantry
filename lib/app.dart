// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/screens/bottom_nav_screen.dart';
import 'package:unipantry/screens/login_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the authentication state
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'PantryPal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: authState.when(
        data: (user) {
          // If user is logged in, show the main app
          if (user != null) {
            return const BottomNavScreen();
          }
          // Otherwise, show the login screen
          return const LoginScreen();
        },
        // Show loading/error screens while checking auth
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