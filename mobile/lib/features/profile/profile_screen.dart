import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/splitmate_button.dart';
import '../../core/widgets/splitmate_card.dart';
import '../../core/widgets/splitmate_text_field.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await ref.read(authProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
          );

      setState(() {
        _isLoading = false;
        _isEditing = false;
        _message = 'Profile updated successfully.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.log_out, size: 20, color: AppColors.negative),
            tooltip: 'Sign out',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_message != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.positiveLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _message!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.positiveText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                SplitMateCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      AvatarWidget(
                        name: user?.name ?? 'User',
                        size: 64,
                        fontSize: 24,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.indian_rupee,
                                    size: 12, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Currency: INR (₹)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (user?.createdAt != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              'Member since ${DateFormatter.formatFull(user!.createdAt!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SplitMateCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _isEditing = !_isEditing);
                            },
                            child: Text(
                              _isEditing ? 'Cancel' : 'Edit',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      SplitMateTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        readOnly: !_isEditing,
                      ),
                      const SizedBox(height: 14),

                      SplitMateTextField(
                        label: 'Email address (Read-only)',
                        hint: user?.email ?? '',
                        readOnly: true,
                      ),
                      const SizedBox(height: 14),

                      SplitMateTextField(
                        label: 'Phone number',
                        hint: '+91 98765 43210',
                        controller: _phoneController,
                        readOnly: !_isEditing,
                        keyboardType: TextInputType.phone,
                      ),

                      if (_isEditing) ...[
                        const SizedBox(height: 20),
                        SplitMateButton(
                          label: 'Save Changes',
                          isLoading: _isLoading,
                          onPressed: _handleSaveProfile,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SplitMateCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About SplitMate',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Version 1.0.0 • Built with Flutter & Node.js • Modern Fintech Experience',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      SplitMateButton(
                        label: 'Sign Out',
                        variant: ButtonVariant.danger,
                        icon: LucideIcons.log_out,
                        onPressed: _handleLogout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
