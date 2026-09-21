import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/debt_flow_indicator.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/splitmate_card.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/balance_provider.dart';
import '../settlements/settle_up_dialog.dart';

class BalancesTab extends ConsumerWidget {
  final GroupModel group;

  const BalancesTab({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(groupBalancesProvider(group.id));
    final currentUserId = ref.watch(authProvider).user?.id;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupBalancesProvider(group.id));
      },
      child: balanceAsync.when(
        data: (balances) {
          final simplifiedDebts = balances.simplifiedDebts;
          final memberBalances = balances.memberBalances;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Simplified Debts Section ("Who Owes Whom")
                const Text(
                  'Who Owes Whom',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Simplified payment plan to settle all debts with minimum transactions.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                if (simplifiedDebts.isEmpty)
                  SplitMateCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.positiveLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.check_check,
                              color: AppColors.positive,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'All Settled Up!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No outstanding debts in this group.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: simplifiedDebts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final debt = simplifiedDebts[index];
                      final isCurrentUserDebtor = debt.fromUserId == currentUserId;
                      final isCurrentUserCreditor = debt.toUserId == currentUserId;

                      return DebtFlowIndicator(
                        fromUserName: debt.fromUserName,
                        fromUserAvatar: debt.fromUserAvatar,
                        toUserName: debt.toUserName,
                        toUserAvatar: debt.toUserAvatar,
                        amount: debt.amount,
                        isCurrentUserDebtor: isCurrentUserDebtor,
                        isCurrentUserCreditor: isCurrentUserCreditor,
                        onSettle: () {
                          showDialog(
                            context: context,
                            builder: (_) => SettleUpDialog(
                              groupId: group.id,
                              members: group.members,
                              defaultPayerId: debt.fromUserId,
                              defaultReceiverId: debt.toUserId,
                              defaultAmount: debt.amount,
                            ),
                          );
                        },
                      );
                    },
                  ),

                const SizedBox(height: 28),

                // 2. Individual Member Balances
                const Text(
                  'Member Net Balances',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total amount paid minus total expenses consumed.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                SplitMateCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: memberBalances.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final mb = memberBalances[index];
                      final isMe = mb.userId == currentUserId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            AvatarWidget(name: mb.name, size: 36, fontSize: 13),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        mb.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isMe
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'You',
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
                                  const SizedBox(height: 3),
                                  Text(
                                    'Paid: ${CurrencyFormatter.format(mb.amountPaid)} • Share: ${CurrencyFormatter.format(mb.amountOwed)}',
                                    style: const TextStyle(
                                      fontSize: 12,
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
                                  mb.netBalance == 0
                                      ? '₹0.00'
                                      : CurrencyFormatter.format(mb.netBalance,
                                          showSign: true),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: mb.isOwed
                                        ? AppColors.positiveText
                                        : mb.owes
                                            ? AppColors.negativeText
                                            : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mb.isOwed
                                      ? 'receives'
                                      : mb.owes
                                          ? 'owes'
                                          : 'settled',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: mb.isOwed
                                        ? AppColors.positive
                                        : mb.owes
                                            ? AppColors.negative
                                            : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Calculating balances...'),
        error: (err, _) => Center(child: Text('Error loading balances: $err')),
      ),
    );
  }
}
