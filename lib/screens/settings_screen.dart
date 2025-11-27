import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/providers/theme_provider.dart';
import 'package:unipantry/screens/household_screen.dart'; // Ensure this exists

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local state for notifications (would be connected to SharedPreferences in a full production app)
  bool _notificationsEnabled = true; 

  // --- Logic: Send Password Reset Email ---
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

  // --- Logic: Sign Out ---
  void _signOut(BuildContext context) {
    ref.read(authServiceProvider).signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMode = ref.watch(themeProvider);
    final user = ref.watch(firebaseAuthProvider).currentUser;
    
    // Helper to determine if Dark Mode is active
    final isDarkMode = currentMode == ThemeMode.dark || 
       (currentMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // --- SECTION: PREFERENCES ---
          _buildSectionHeader(context, 'Preferences'),
          
          // Dark Mode Switch
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: Icon(PhosphorIconsDuotone.moon, color: theme.colorScheme.primary),
            value: isDarkMode,
            onChanged: (bool value) {
              ref.read(themeProvider.notifier).toggleTheme(value);
            },
          ),
          
          // Notification Switch
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive expiry reminders'),
            secondary: Icon(PhosphorIconsDuotone.bell, color: theme.colorScheme.primary),
            value: _notificationsEnabled, 
            onChanged: (bool value) {
               setState(() {
                 _notificationsEnabled = value;
               });
               if (value) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications Enabled')));
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications Paused')));
               }
            },
          ),

          const Divider(),

          // --- SECTION: ACCOUNT ---
          _buildSectionHeader(context, 'Account'),
          
          // 1. Manage Household (New Feature)
          ListTile(
            leading: Icon(PhosphorIconsDuotone.usersThree, color: theme.colorScheme.primary),
            title: const Text('Manage Household'),
            subtitle: const Text('Members & Invite Code'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HouseholdScreen()),
              );
            },
          ),

          // 2. Change Password
          ListTile(
            leading: Icon(PhosphorIconsDuotone.lockKey, color: theme.colorScheme.primary),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => _changePassword(context, user),
          ),

          // 3. Log Out
          ListTile(
            leading: Icon(PhosphorIconsDuotone.signOut, color: theme.colorScheme.error),
            title: Text('Log Out', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
            onTap: () => _signOut(context),
          ),

          // 4. Delete Account (Spacer to separate dangerous action)
          ListTile(
            leading: Icon(PhosphorIconsDuotone.trash, color: Colors.grey),
            title: const Text('Delete Account', style: TextStyle(color: Colors.grey)),
            onTap: () {
              showDialog(
                context: context, 
                builder: (ctx) => AlertDialog(
                  title: const Text("Delete Account"),
                  content: const Text("This action cannot be undone. Are you sure?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx), 
                      child: const Text("Delete", style: TextStyle(color: Colors.red))
                    ),
                  ],
                )
              );
            },
          ),

          const Divider(),

          // --- SECTION: ABOUT ---
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