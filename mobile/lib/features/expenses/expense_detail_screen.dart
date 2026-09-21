import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/splitmate_badge.dart';
import '../../core/widgets/splitmate_button.dart';
import '../../core/widgets/splitmate_card.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import 'add_expense_screen.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final String groupId;
  final ExpenseModel expense;

  const ExpenseDetailScreen({
    super.key,
    required this.groupId,
    required this.expense,
  });

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete this expense?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'This will recalculate and update the balances of all group members.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          SplitMateButton(
            label: 'Cancel',
            variant: ButtonVariant.outline,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          SplitMateButton(
            label: 'Delete',
            variant: ButtonVariant.danger,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(groupExpensesProvider(groupId).notifier)
                  .deleteExpense(expense.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authProvider).user?.id;
    final canEditOrDelete = currentUserId == expense.payerId ||
        currentUserId == expense.createdById;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          if (canEditOrDelete) ...[
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 18),
              tooltip: 'Edit Expense',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(
                      groupId: groupId,
                      existingExpense: expense,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash, size: 18, color: AppColors.negative),
              tooltip: 'Delete Expense',
              onPressed: () => _confirmDelete(context, ref),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                SplitMateCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SplitMateBadge(
                            label: expense.category,
                            variant: BadgeVariant.primary,
                          ),
                          Text(
                            DateFormatter.formatFull(expense.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        expense.description,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(expense.amount),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          AvatarWidget(
                            name: expense.payer?.name ?? 'Payer',
                            size: 32,
                            fontSize: 12,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${expense.payer?.name ?? "Unknown"} paid the full amount',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Split method: ${expense.splitMethod}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            expense.notes!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Splits Breakdown
                const Text(
                  'Split Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                SplitMateCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expense.splits.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final split = expense.splits[index];
                      final isPayer = split.userId == expense.payerId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            AvatarWidget(
                              name: split.user?.name ?? 'Member',
                              size: 32,
                              fontSize: 12,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    split.user?.name ?? 'Member',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isPayer)
                                    const Text(
                                      'Payer share',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(split.amount),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
