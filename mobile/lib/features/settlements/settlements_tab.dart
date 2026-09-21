import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/splitmate_badge.dart';
import '../../core/widgets/splitmate_card.dart';
import '../../models/group_model.dart';
import '../../providers/settlement_provider.dart';
import 'settle_up_dialog.dart';

class SettlementsTab extends ConsumerWidget {
  final GroupModel group;

  const SettlementsTab({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementsAsync = ref.watch(groupSettlementsProvider(group.id));

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(groupSettlementsProvider(group.id).notifier)
            .fetchSettlements();
      },
      child: settlementsAsync.when(
        data: (settlements) {
          if (settlements.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                icon: LucideIcons.circle_check,
                title: 'No settlements recorded yet',
                description:
                    'When group members pay each other back to settle debts, record them here.',
                actionLabel: 'Record a Settlement',
                actionIcon: LucideIcons.plus,
                onAction: () {
                  if (group.members.length >= 2) {
                    showDialog(
                      context: context,
                      builder: (_) => SettleUpDialog(
                        groupId: group.id,
                        members: group.members,
                        defaultPayerId: group.members[0].userId,
                        defaultReceiverId: group.members[1].userId,
                        defaultAmount: 0.0,
                      ),
                    );
                  }
                },
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: settlements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final s = settlements[index];
              return SplitMateCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.positiveLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.check_check,
                        color: AppColors.positive,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.payer?.name ?? "Someone"} paid ${s.receiver?.name ?? "Someone"}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DateFormatter.formatFull(s.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (s.notes != null && s.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              s.notes!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(s.amount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.positiveText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const SplitMateBadge(
                          label: 'Completed',
                          variant: BadgeVariant.success,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Loading settlements...'),
        error: (err, _) => Center(child: Text('Error loading settlements: $err')),
      ),
    );
  }
}
