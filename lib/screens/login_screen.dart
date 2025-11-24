import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:unipantry/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State
  bool _isLogin = true; // Toggle between Login and Signup
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus(); // Close keyboard

    final auth = ref.read(authServiceProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await auth.signInWithEmail(email, password);
      } else {
        await auth.signUpWithEmail(email, password);
      }
      // If successful, the AuthState stream in App.dart will handle navigation
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // Background color acts as fallback while image loads
        backgroundColor: theme.colorScheme.primary,
        body: Stack(
          children: [
            // --- 1. BACKGROUND IMAGE ---
            Positioned.fill(
              child: Image.asset(
                'assets/login_bg.png', // <--- YOUR IMAGE HERE
                fit: BoxFit.cover,
              ),
            ),

            // --- 2. DARK OVERLAY ---
            // This ensures text is readable even if the image is bright
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5), // Adjust opacity (0.0 to 1.0)
              ),
            ),

            // --- 3. MAIN CONTENT ---
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Logo Section ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Icon(
                        PhosphorIconsDuotone.bowlFood,
                        size: 60,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Unipantry',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                    Text(
                      'Manage your food smarter.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- The Card ---
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      // Ensure card stands out against image
                      color: theme.colorScheme.surface.withOpacity(0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Toggle Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildToggleText('Log In', true),
                                  Container(width: 1, height: 20, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 16)),
                                  _buildToggleText('Sign Up', false),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration('Email', PhosphorIconsDuotone.envelope),
                                validator: (value) {
                                  if (value == null || !value.contains('@')) return 'Invalid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: _inputDecoration('Password', PhosphorIconsDuotone.lockKey),
                                validator: (value) {
                                  if (value == null || value.length < 6) return 'Password too short (min 6)';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24, 
                                          width: 24, 
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                        )
                                      : Text(
                                          _isLogin ? 'Log In' : 'Create Account',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Toggle Text
  Widget _buildToggleText(String title, bool isLoginState) {
    final isActive = _isLogin == isLoginState;
    return InkWell(
      onTap: () => setState(() => _isLogin = isLoginState),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isActive 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  // Helper for Input Styling
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
    );
  }
}