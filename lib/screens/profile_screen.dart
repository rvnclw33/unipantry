import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:unipantry/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  File? _selectedImage; 
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(firebaseAuthProvider).currentUser;
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 512, 
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isUploading = true);
    FocusScope.of(context).unfocus();
    
    final authService = ref.read(authServiceProvider);
    
    try {
      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await authService.uploadProfileImage(_selectedImage!);
      }

      await authService.updateUserProfile(
        name: _nameController.text.trim(),
        photoUrl: photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated Successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showJoinDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Household'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Enter Invite Code',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            // Fix for dialog input in dark mode
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).joinHousehold(controller.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined household successfully!')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  InputDecoration _modernInput(String label, IconData icon, BuildContext context) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final householdId = ref.watch(householdIdProvider);
    final theme = Theme.of(context);
    
    // Helper to check if we are in Dark Mode
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _isUploading ? null : _saveProfile,
              tooltip: 'Save Changes',
              icon: _isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(PhosphorIconsDuotone.check, color: theme.colorScheme.primary),
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // --- 1. AVATAR PICKER ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!) as ImageProvider
                          : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
                      child: (_selectedImage == null && user?.photoURL == null)
                          ? Text(
                              (user?.email ?? "G")[0].toUpperCase(),
                              style: TextStyle(fontSize: 40, color: theme.colorScheme.primary),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.surface, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)
                            ],
                          ),
                          child: const Icon(PhosphorIconsDuotone.camera, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- 2. PERSONAL INFO ---
              TextFormField(
                controller: _nameController,
                decoration: _modernInput('Display Name', PhosphorIconsDuotone.user, context),
              ),
              const SizedBox(height: 16),
              
              // --- 3. UPDATED EMAIL FIELD (Theme Aware) ---
              TextFormField(
                controller: _emailController,
                readOnly: true,
                // Text color: Dimmed, but visible on both backgrounds
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)), 
                decoration: _modernInput('Email Address', PhosphorIconsDuotone.envelopeSimple, context).copyWith(
                  fillColor: isDark ? Colors.black26 : Colors.grey.shade200,
                ),
              ),
              
              const SizedBox(height: 32),

              // --- 4. HOUSEHOLD CARD ---
              Card(
                elevation: 0,
                // Card background logic
                color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(PhosphorIconsDuotone.houseLine, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            "HOUSEHOLD SETTINGS",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Invite family members with this code:",
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      
                      // Code Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                householdId ?? "Loading...",
                                style: const TextStyle(
                                  fontFamily: 'Courier', 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(PhosphorIconsDuotone.copy, color: theme.colorScheme.primary),
                              onPressed: () {
                                if (householdId != null) {
                                  Clipboard.setData(ClipboardData(text: householdId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Invite code copied!')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showJoinDialog(context),
                          icon: Icon(PhosphorIconsDuotone.signIn),
                          label: const Text("Join Different Household"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              
              // --- 5. LOGOUT ---
              TextButton.icon(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                icon: const Icon(PhosphorIconsDuotone.signOut, color: Colors.red),
                label: const Text("Log Out", style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}