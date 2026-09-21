import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/notebook_scaffold.dart';
import '../../core/widgets/notebook_top_bar.dart';
import '../../core/widgets/splitmate_button.dart';
import '../../core/widgets/splitmate_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/balance_provider.dart';
import '../../providers/group_provider.dart';
import '../groups/create_group_dialog.dart';
import '../groups/join_group_dialog.dart';
import '../groups/group_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupListProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return NotebookScaffold(
      appBar: const NotebookTopBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          await ref.read(groupListProvider.notifier).fetchGroups();
        },
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            final isMobile = MediaQuery.of(context).size.width < 600;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 24,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 1100,
                    minHeight: viewportConstraints.maxHeight - 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Title & Create New Group Button (Responsive)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobileLayout = constraints.maxWidth < 650;

                              if (isMobileLayout) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'My Expense Groups',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Manage your group expenses, split bills, and track settlements.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SplitMateButton(
                                            label: 'Join Code',
                                            variant: ButtonVariant.outline,
                                            icon: LucideIcons.user_plus,
                                            height: 40,
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => const JoinGroupDialog(),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: SplitMateButton(
                                            label: 'Create Group',
                                            variant: ButtonVariant.primary,
                                            icon: LucideIcons.plus,
                                            height: 40,
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => const CreateGroupDialog(),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'My Expense Groups',
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Manage your group expenses, split bills, and track settlements.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Row(
                                    children: [
                                      SplitMateButton(
                                        label: 'Join with Code',
                                        variant: ButtonVariant.outline,
                                        icon: LucideIcons.user_plus,
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => const JoinGroupDialog(),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      SplitMateButton(
                                        label: 'Create New Group',
                                        variant: ButtonVariant.primary,
                                        icon: LucideIcons.plus,
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => const CreateGroupDialog(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Overall Net Balance Banner (Quick summary)
                          summaryAsync.when(
                            data: (summary) {
                              final net = summary.netBalance;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  color: net > 0
                                      ? AppColors.positiveLight
                                      : net < 0
                                          ? AppColors.negativeLight
                                          : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.shadowColor,
                                      offset: Offset(2, 2),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      net > 0
                                          ? LucideIcons.arrow_down_left
                                          : net < 0
                                              ? LucideIcons.arrow_up_right
                                              : LucideIcons.circle_check,
                                      size: 20,
                                      color: net > 0
                                          ? AppColors.positive
                                          : net < 0
                                              ? AppColors.negative
                                              : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        net > 0
                                            ? "Overall, you are owed ${CurrencyFormatter.format(summary.totalOwedToYou)}"
                                            : net < 0
                                                ? "Overall, you owe ${CurrencyFormatter.format(summary.totalYouOwe)}"
                                                : "All your groups are completely settled up!",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: net > 0
                                              ? AppColors.positiveText
                                              : net < 0
                                                  ? AppColors.negativeText
                                                  : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 24),

                          // Groups Grid with Notebook Cards & Sticky Tape (Screenshot 1)
                          groupsAsync.when(
                            data: (groups) {
                              if (groups.isEmpty) {
                                return Center(
                                  child: EmptyStateWidget(
                                    icon: LucideIcons.users,
                                    title: 'No groups created yet',
                                    description:
                                        'Create a group for an outing, trip, or apartment to start sharing costs.',
                                    actionLabel: 'Create New Group',
                                    actionIcon: LucideIcons.plus,
                                    onAction: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => const CreateGroupDialog(),
                                      );
                                    },
                                  ),
                                );
                              }

                              return LayoutBuilder(
                                builder: (context, gridConstraints) {
                                  final screenW = gridConstraints.maxWidth;
                                  int crossAxisCount = 1;
                                  if (screenW >= 950) {
                                    crossAxisCount = 3;
                                  } else if (screenW >= 600) {
                                    crossAxisCount = 2;
                                  }

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 18,
                                      mainAxisSpacing: 22,
                                      mainAxisExtent: 195,
                                    ),
                                    itemCount: groups.length,
                                    itemBuilder: (context, index) {
                                      final group = groups[index];
                                      final isOwner = group.isUserOwner ||
                                          (ref.watch(authProvider).user?.id == group.createdById);

                                      return SplitMateCard(
                                        hasStickyTape: true,
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    group.name,
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isOwner) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surface,
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(
                                                          color: AppColors.border, width: 1.2),
                                                    ),
                                                    child: const Text(
                                                      'Owner',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              group.description?.isNotEmpty == true
                                                  ? group.description!
                                                  : 'No description provided.',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 12),

                                            // Stats Box (Screenshot 1)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceMuted,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: AppColors.borderLight, width: 1),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          'TOTAL SPENT',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w700,
                                                            color: AppColors.textMuted,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          CurrencyFormatter.format(
                                                              group.totalExpensesAmount),
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w800,
                                                            color: AppColors.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          'EXPENSES',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w700,
                                                            color: AppColors.textMuted,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '${group.expenseCount}',
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w800,
                                                            color: AppColors.textPrimary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),

                                            // Action Buttons: View Group + Code
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 5,
                                                  child: SplitMateButton(
                                                    label: 'View Group',
                                                    variant: ButtonVariant.primary,
                                                    icon: LucideIcons.eye,
                                                    height: 36,
                                                    onPressed: () {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (_) => GroupDetailScreen(
                                                            groupId: group.id,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 5,
                                                  child: SplitMateButton(
                                                    label: 'Code: ${group.inviteCode}',
                                                    variant: ButtonVariant.outline,
                                                    icon: LucideIcons.copy,
                                                    height: 36,
                                                    onPressed: () {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Invite Code: ${group.inviteCode}'),
                                                          backgroundColor: AppColors.primary,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            loading: () =>
                                const LoadingWidget(message: 'Loading expense groups...'),
                            error: (err, _) => Center(child: Text('Error: $err')),
                          ),
                        ],
                      ),
                      const Column(
                        children: [
                          SizedBox(height: 48),
                          Center(
                            child: Text(
                              '© 2026 SplitMate PRO – Group Expense Tracker. Dynamic Group Expense Tracker & Settle-up Calculator.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
