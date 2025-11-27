import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/screens/settings_screen.dart';
import 'package:unipantry/screens/waste_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Text(
                              (user?.displayName ?? user?.email ?? "G")[0]
                                  .toUpperCase(),
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Welcome back,",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.displayName ?? "Guest User",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: Divider(height: 1),
            ),
            const SizedBox(height: 20),

            // --- 2. NAVIGATION ITEMS ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: PhosphorIconsDuotone.house,
                    label: 'Home',
                    onTap: () => Navigator.pop(context),
                    isActive: true,
                  ),

                  // --- REPLACED 'Categories' WITH 'Insights' ---
                  // inside AppDrawer ...
                  _buildDrawerItem(
                    context: context,
                    icon: PhosphorIconsDuotone.chartPieSlice,
                    label: 'Waste Insights',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      // Navigate to Waste Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const WasteScreen()),
                      );
                    },
                  ),

                  _buildDrawerItem(
                    context: context,
                    icon: PhosphorIconsDuotone.gear,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- 3. FOOTER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context: context,
                    icon: PhosphorIconsDuotone.signOut,
                    label: 'Log Out',
                    color: theme.colorScheme.error,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(authServiceProvider).signOut();
                    },
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "Version 1.0.0",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final itemColor = color ??
        (isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        leading: Icon(icon, color: itemColor, size: 24),
        title: Text(
          label,
          style: TextStyle(
            color: itemColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
