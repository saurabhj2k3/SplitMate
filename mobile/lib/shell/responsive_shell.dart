import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../core/constants/colors.dart';
import '../core/widgets/avatar_widget.dart';
import '../features/activity/activity_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/groups/group_list_screen.dart';
import '../features/profile/profile_screen.dart';
import '../providers/auth_provider.dart';

class ResponsiveShell extends ConsumerStatefulWidget {
  const ResponsiveShell({super.key});

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    GroupListScreen(),
    ActivityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Left Sidebar for Desktop Web
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.split,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'SplitMate',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Navigation Links
                  _buildSidebarItem(0, 'Dashboard', LucideIcons.layout_dashboard),
                  _buildSidebarItem(1, 'Groups', LucideIcons.users),
                  _buildSidebarItem(2, 'Activity', LucideIcons.activity),
                  _buildSidebarItem(3, 'Profile', LucideIcons.user),

                  const Spacer(),

                  // Bottom User Info in Sidebar
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        AvatarWidget(
                          name: user?.name ?? 'User',
                          size: 36,
                          fontSize: 13,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'User',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: _screens[_currentIndex],
            ),
          ],
        ),
      );
    }

    // Mobile Layout with Bottom Navigation Bar
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.primaryLight,
          height: 64,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(LucideIcons.layout_dashboard, size: 20),
              selectedIcon:
                  Icon(LucideIcons.layout_dashboard, size: 20, color: AppColors.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.users, size: 20),
              selectedIcon:
                  Icon(LucideIcons.users, size: 20, color: AppColors.primary),
              label: 'Groups',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.activity, size: 20),
              selectedIcon:
                  Icon(LucideIcons.activity, size: 20, color: AppColors.primary),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.user, size: 20),
              selectedIcon:
                  Icon(LucideIcons.user, size: 20, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon) {
    final isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
