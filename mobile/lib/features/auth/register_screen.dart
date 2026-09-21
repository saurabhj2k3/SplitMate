import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/splitmate_button.dart';
import '../../core/widgets/splitmate_card.dart';
import '../../core/widgets/splitmate_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../shell/responsive_shell.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please provide name, email, and password.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters long.');
      return;
    }

    setState(() => _errorMessage = null);
    final success = await ref.read(authProvider.notifier).register(
          name: name,
          email: email,
          password: password,
          phone: phone.isNotEmpty ? phone : null,
        );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ResponsiveShell()),
        (route) => false,
      );
    } else if (mounted) {
      final error = ref.read(authProvider).error;
      setState(() => _errorMessage = error ?? 'Registration failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back to Login Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.arrow_left, size: 14, color: AppColors.textPrimary),
                          SizedBox(width: 6),
                          Text(
                            'Back to Login',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.split,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SplitMate',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your free account',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Main Form Card
                SplitMateCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.negativeLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.negative.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.circle_alert,
                                size: 16,
                                color: AppColors.negative,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.negativeText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      SplitMateTextField(
                        label: 'Full name',
                        hint: 'e.g. Saurabh Sharma',
                        controller: _nameController,
                        prefix: const Icon(LucideIcons.user, size: 18, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      SplitMateTextField(
                        label: 'Email address',
                        hint: 'name@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefix: const Icon(LucideIcons.mail, size: 18, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      SplitMateTextField(
                        label: 'Phone number (Optional)',
                        hint: '+91 98765 43210',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefix: const Icon(LucideIcons.phone, size: 18, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      SplitMateTextField(
                        label: 'Password',
                        hint: 'Create a password (min 6 characters)',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefix: const Icon(LucideIcons.lock, size: 18, color: AppColors.textSecondary),
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? LucideIcons.eye : LucideIcons.eye_off,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      SplitMateButton(
                        label: 'Create Account',
                        isLoading: authState.isLoading,
                        onPressed: _handleRegister,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sign in Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
