Faisal

// setting

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/providers/theme_provider.dart';

// 1. Changed to ConsumerStatefulWidget to allow local state (the toggle)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // 2. Add a variable to track the switch state
  bool _notificationsEnabled = true; 

  Future<void> _changePassword(BuildContext context, User? user) async {
    if (user == null || user.email == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in with an email to change password.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to ${user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _signOut(BuildContext context) {
    ref.read(authServiceProvider).signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMode = ref.watch(themeProvider);
    final user = ref.watch(firebaseAuthProvider).currentUser;
    
    final isDarkMode = currentMode == ThemeMode.dark || 
       (currentMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          _buildSectionHeader(context, 'Preferences'),
          
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: Icon(PhosphorIconsDuotone.moon, color: theme.colorScheme.primary),
            value: isDarkMode,
            onChanged: (bool value) {
              ref.read(themeProvider.notifier).toggleTheme(value);
            },
          ),
          
          // --- FIXED NOTIFICATION SWITCH ---
          SwitchListTile(
            title: const Text('Push Notifications'),
            secondary: Icon(PhosphorIconsDuotone.bell, color: theme.colorScheme.primary),
            // 3. Connect the switch to the variable
            value: _notificationsEnabled, 
            onChanged: (bool value) {
               // 4. Update the variable inside setState
               setState(() {
                 _notificationsEnabled = value;
               });
               
               if (value) {
                 // Logic to enable notifications (e.g., re-request permission)
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Notifications Enabled')),
                 );
               } else {
                 // Logic to cancel all notifications
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Notifications Paused')),
                 );
               }
            },
          ),

          const Divider(),

          _buildSectionHeader(context, 'Account'),
          
          ListTile(
            leading: Icon(PhosphorIconsDuotone.lockKey, color: theme.colorScheme.primary),
            title: const Text('Change Password'),
            subtitle: const Text('Send reset email'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _changePassword(context, user),
          ),

          ListTile(
            leading: Icon(PhosphorIconsDuotone.signOut, color: theme.colorScheme.error),
            title: Text('Log Out', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
            onTap: () => _signOut(context),
          ),

          ListTile(
            leading: Icon(PhosphorIconsDuotone.trash, color: Colors.grey),
            title: const Text('Delete Account', style: TextStyle(color: Colors.grey)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This feature is coming soon.')),
              );
            },
          ),

          const Divider(),

          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: Icon(PhosphorIconsDuotone.info),
            title: const Text('Version'),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}