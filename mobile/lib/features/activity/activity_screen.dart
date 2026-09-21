import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/splitmate_card.dart';
import '../../providers/activity_provider.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(recentActivityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity Feed'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentActivityProvider);
        },
        child: activityAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return Center(
                child: EmptyStateWidget(
                  icon: LucideIcons.activity,
                  title: 'No recent activity',
                  description:
                      'Activities like new expenses, updates, and recorded settlements across all your groups will appear here.',
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final act = activities[index];
                    return SplitMateCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AvatarWidget(
                            name: act.user?.name ?? 'User',
                            size: 38,
                            fontSize: 13,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  act.details,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (act.groupName != null) ...[
                                      Text(
                                        act.groupName!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const Text(
                                        ' • ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    Text(
                                      DateFormatter.formatRelative(act.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _getActionIcon(act.actionType),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
          loading: () => const LoadingWidget(message: 'Loading activity feed...'),
          error: (err, _) => Center(child: Text('Error loading activity: $err')),
        ),
      ),
    );
  }

  Widget _getActionIcon(String actionType) {
    IconData icon;
    Color color;

    switch (actionType) {
      case 'EXPENSE_CREATED':
        icon = LucideIcons.receipt;
        color = AppColors.primary;
        break;
      case 'SETTLEMENT_RECORDED':
        icon = LucideIcons.check_check;
        color = AppColors.positive;
        break;
      case 'MEMBER_JOINED':
      case 'MEMBER_ADDED':
        icon = LucideIcons.user_plus;
        color = AppColors.primary;
        break;
      default:
        icon = LucideIcons.bell;
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
