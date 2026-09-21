import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/splitmate_card.dart';
import '../../providers/group_provider.dart';
import 'create_group_dialog.dart';
import 'join_group_dialog.dart';
import 'group_detail_screen.dart';

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Groups'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.user_plus, size: 20),
            tooltip: 'Join with Code',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const JoinGroupDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.circle_plus, size: 20),
            tooltip: 'Create Group',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const CreateGroupDialog(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(groupListProvider.notifier).fetchGroups();
        },
        child: groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return Center(
                child: EmptyStateWidget(
                  icon: LucideIcons.users,
                  title: 'No groups created yet',
                  description:
                      'Create a group for an outing, trip, or apartment to start sharing costs.',
                  actionLabel: 'Create a Group',
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

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = groups[index];
                return SplitMateCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(groupId: group.id),
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.users,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    group.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (group.isUserOwner) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Owner',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${group.memberCount} members • Code: ${group.inviteCode}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(group.totalExpensesAmount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${group.expenseCount} expenses',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.chevron_right,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const LoadingWidget(message: 'Loading your groups...'),
          error: (err, _) => Center(
            child: Text('Error loading groups: $err'),
          ),
        ),
      ),
    );
  }
}
