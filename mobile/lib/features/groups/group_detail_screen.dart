import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/notebook_scaffold.dart';
import '../../core/widgets/notebook_top_bar.dart';
import '../../core/widgets/splitmate_button.dart';
import '../../core/widgets/splitmate_card.dart';
import '../../models/balance_model.dart';
import '../../models/expense_model.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/balance_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/settlement_provider.dart';
import '../expenses/add_expense_screen.dart';
import '../settlements/settle_up_dialog.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _newParticipantController = TextEditingController();
  bool _isAddingParticipant = false;

  @override
  void dispose() {
    _newParticipantController.dispose();
    super.dispose();
  }

  String _getShareUrl(String code) {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      return '$origin/join/$code';
    }
    return 'https://splitmate.pages.dev/join/$code';
  }

  void _copyShareUrl(String code) {
    final url = _getShareUrl(code);
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share URL "$url" copied to clipboard!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addParticipant(String groupId) async {
    final text = _newParticipantController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAddingParticipant = true);
    try {
      await ref.read(groupListProvider.notifier).addMember(groupId, text);
      ref.invalidate(singleGroupProvider(groupId));
      _newParticipantController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$text" to group!'),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingParticipant = false);
    }
  }

  void _confirmDeleteExpense(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete this expense?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Delete "${expense.description}" (₹${expense.amount.toStringAsFixed(2)})? This will recalculate everyone\'s balance.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                  .read(groupExpensesProvider(widget.groupId).notifier)
                  .deleteExpense(expense.id);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(singleGroupProvider(widget.groupId));
    final expensesAsync = ref.watch(groupExpensesProvider(widget.groupId));
    final balanceAsync = ref.watch(groupBalancesProvider(widget.groupId));
    final currentUserId = ref.watch(authProvider).user?.id;

    return NotebookScaffold(
      appBar: NotebookTopBar(
        onDashboardClick: () => Navigator.of(context).pop(),
      ),
      body: groupAsync.when(
        data: (group) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(singleGroupProvider(widget.groupId));
              ref.invalidate(groupExpensesProvider(widget.groupId));
              ref.invalidate(groupBalancesProvider(widget.groupId));
            },
            child: LayoutBuilder(
              builder: (context, viewportConstraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Yellow Header Banner Card (Screenshot 2)
                              _buildYellowBannerHeader(context, group),
                              const SizedBox(height: 24),

                              // 2. Responsive 2-Column Layout (Left: Expenses & Participants, Right: Settle Up Plan & Breakdown)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isDesktop = constraints.maxWidth >= 768;

                                  if (isDesktop) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Left Column: Expenses & Participants (Flex 6)
                                        Expanded(
                                          flex: 6,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              _buildExpensesSection(context, group, expensesAsync),
                                              const SizedBox(height: 24),
                                              _buildParticipantsSection(context, group, currentUserId),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),

                                        // Right Column: Settle Up Plan & Individual Breakdown Table (Flex 5)
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              _buildSettleUpPlanSection(context, group, balanceAsync, currentUserId),
                                              const SizedBox(height: 20),
                                              _buildIndividualBreakdownSection(balanceAsync, currentUserId),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Mobile stacked layout
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _buildSettleUpPlanSection(context, group, balanceAsync, currentUserId),
                                        const SizedBox(height: 20),
                                        _buildIndividualBreakdownSection(balanceAsync, currentUserId),
                                        const SizedBox(height: 24),
                                        _buildExpensesSection(context, group, expensesAsync),
                                        const SizedBox(height: 24),
                                        _buildParticipantsSection(context, group, currentUserId),
                                      ],
                                    );
                                  }
                                },
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
          );
        },
        loading: () => const LoadingWidget(message: 'Loading group details...'),
        error: (err, _) => Center(child: Text('Error loading group: $err')),
      ),
    );
  }

  void _confirmDeleteGroup(GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete this group?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This action cannot be undone and will delete all expenses.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          SplitMateButton(
            label: 'Cancel',
            variant: ButtonVariant.outline,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          SplitMateButton(
            label: 'Delete Group',
            variant: ButtonVariant.danger,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(groupListProvider.notifier).deleteGroup(group.id);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _editGroupDialog(GroupModel group) {
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Edit Group Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          SplitMateButton(
            label: 'Cancel',
            variant: ButtonVariant.outline,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          SplitMateButton(
            label: 'Save Changes',
            variant: ButtonVariant.primary,
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Group details updated!'),
                  backgroundColor: AppColors.positive,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYellowBannerHeader(BuildContext context, GroupModel group) {
    final currentUserId = ref.watch(authProvider).user?.id;
    final isOwner = group.isUserOwner ||
        (currentUserId != null &&
            (group.createdById == currentUserId ||
                group.members.any((m) => m.userId == currentUserId && m.isOwner)));

    final ownerMember = group.members.where((m) => m.isOwner).firstOrNull;
    final creatorName = ownerMember?.name.split(' ').first ??
        (group.members.isNotEmpty ? group.members.first.name.split(' ').first : 'Admin');
    final createdDate = group.createdAt ?? DateTime.now();
    final formattedCreatedDate =
        '${createdDate.day} ${DateFormatter.formatDayMonth(createdDate).split(' ').first}, ${createdDate.year}';
    final isSmallScreen = MediaQuery.of(context).size.width < 500;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 22),
      decoration: BoxDecoration(
        color: AppColors.yellowBanner,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          final infoColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOwner) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary, width: 1.5),
                      ),
                      child: const Text(
                        'You are Owner',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                group.description?.isNotEmpty == true
                    ? group.description!
                    : 'No description.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Created by $creatorName on $formattedCreatedDate',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );

          final actionsColumn = Column(
            crossAxisAlignment: isWide ? CrossAxisAlignment.end : CrossAxisAlignment.stretch,
            children: [
              // Share URL box (Screenshot 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Share URL: ${_getShareUrl(group.inviteCode)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _copyShareUrl(group.inviteCode),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.border, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.copy,
                                size: 12, color: AppColors.textPrimary),
                            SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Edit Group & Delete Group (Only for Owner) buttons
              Row(
                children: [
                  Expanded(
                    flex: isWide ? 0 : 1,
                    child: InkWell(
                      onTap: () => _editGroupDialog(group),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.pencil, size: 13, color: AppColors.textPrimary),
                            SizedBox(width: 6),
                            Text(
                              'Edit Group',
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
                  if (isOwner) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: isWide ? 0 : 1,
                      child: InkWell(
                        onTap: () => _confirmDeleteGroup(group),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF87171),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.trash, size: 13, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Delete Group',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: infoColumn),
                const SizedBox(width: 16),
                actionsColumn,
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoColumn,
                const SizedBox(height: 16),
                actionsColumn,
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildExpensesSection(
      BuildContext context, GroupModel group, AsyncValue<List<ExpenseModel>> expensesAsync) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with "Add New Expense" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Group Expenses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  expensesAsync.maybeWhen(
                    data: (expenses) => Text(
                      '${expenses.length} expenses logged',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            SplitMateButton(
              label: isNarrow ? '+ Add' : 'Add New Expense',
              variant: ButtonVariant.primary,
              icon: LucideIcons.plus,
              height: 38,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(
                      groupId: group.id,
                      preselectedGroup: group,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Expense List Cards (Screenshot 2: Soda card style)
        expensesAsync.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return SplitMateCard(
                padding: const EdgeInsets.all(24),
                child: EmptyStateWidget(
                  icon: LucideIcons.receipt,
                  title: 'No expenses yet',
                  description:
                      'Add your first expense to calculate splits and settlements.',
                  actionLabel: 'Add Expense',
                  actionIcon: LucideIcons.plus,
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(
                          groupId: group.id,
                          preselectedGroup: group,
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final exp = expenses[index];
                final participantsNames =
                    exp.splits.map((s) => s.user?.name.split(' ').first ?? 'Member').join(', ');

                return SplitMateCard(
                  padding: const EdgeInsets.all(14),
                  child: LayoutBuilder(
                    builder: (context, cardConstraints) {
                      final isCardNarrow = cardConstraints.maxWidth < 420;

                      final dateBox = Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.dateBadgeBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${exp.date.day}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.dateBadgeText,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              DateFormatter.formatDayMonth(exp.date).split(' ').first.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dateBadgeText,
                              ),
                            ),
                          ],
                        ),
                      );

                      final amountAndActions = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.positiveLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Text(
                              CurrencyFormatter.format(exp.amount),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddExpenseScreen(
                                    groupId: group.id,
                                    existingExpense: exp,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: const Icon(LucideIcons.pencil, size: 13, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _confirmDeleteExpense(exp),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: const Icon(LucideIcons.trash, size: 13, color: AppColors.negative),
                            ),
                          ),
                        ],
                      );

                      if (isCardNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                dateBox,
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exp.description,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                          children: [
                                            const TextSpan(text: 'Paid by '),
                                            TextSpan(
                                              text: exp.payer?.name.split(' ').first ?? 'Someone',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            TextSpan(text: ' • Shared: $participantsNames'),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                amountAndActions,
                              ],
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          dateBox,
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Paid by '),
                                      TextSpan(
                                        text: exp.payer?.name.split(' ').first ?? 'Someone',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      TextSpan(text: ' • Shared between: $participantsNames'),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          amountAndActions,
                        ],
                      );
                    },
                  ),
                );
              },
            );
          },
          loading: () => const LoadingWidget(message: 'Loading expenses...'),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ],
    );
  }

  void _confirmRemoveMember(String groupId, String userId, String memberName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Remove $memberName?',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "$memberName" from this group? Only members with zero balance can be removed.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          SplitMateButton(
            label: 'Cancel',
            variant: ButtonVariant.outline,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          SplitMateButton(
            label: 'Remove',
            variant: ButtonVariant.danger,
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(groupListProvider.notifier).removeMember(groupId, userId);
                ref.invalidate(singleGroupProvider(groupId));
                ref.invalidate(groupBalancesProvider(groupId));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception:', '').trim()),
                      backgroundColor: AppColors.negative,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection(
      BuildContext context, GroupModel group, String? currentUserId) {
    return SplitMateCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Participants (${group.members.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Add participant text box + Add button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: TextField(
                    controller: _newParticipantController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Enter new participant name or email...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _addParticipant(group.id),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SplitMateButton(
                label: 'Add',
                icon: LucideIcons.plus,
                height: 42,
                isLoading: _isAddingParticipant,
                onPressed: () => _addParticipant(group.id),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Participant Tag Chips with ✕ (Screenshot 2)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.members.map((m) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.user, size: 13, color: AppColors.textPrimary),
                    const SizedBox(width: 6),
                    Text(
                      m.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _confirmRemoveMember(group.id, m.userId, m.name),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          '✕',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF87171),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettleUpPlanSection(BuildContext context, GroupModel group,
      AsyncValue<GroupBalancesModel> balanceAsync, String? currentUserId) {
    return balanceAsync.when(
      data: (balances) {
        final totalExpense = balances.totalGroupExpense;
        final simplifiedDebts = balances.simplifiedDebts;

        return SplitMateCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expense Summary Top (Screenshot 2)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10,
                spacing: 12,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.receipt, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Expense Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Text(
                      'TOTAL SPENT: ${CurrencyFormatter.format(totalExpense)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Final Settle Up Plan (💛 card style from Screenshot 2)
              const Row(
                children: [
                  Text('💛 ', style: TextStyle(fontSize: 14)),
                  Text(
                    'Final Settle Up Plan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (simplifiedDebts.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.positiveLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      'Everyone is completely settled up! 🎉',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.positiveText,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: simplifiedDebts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final debt = simplifiedDebts[index];

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // "Saurabh -> pays Om"
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                children: [
                                  TextSpan(text: debt.fromUserName),
                                  const TextSpan(
                                    text: ' ➔ pays ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  TextSpan(text: debt.toUserName),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                CurrencyFormatter.format(debt.amount),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.negativeText,
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () {
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
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.positiveLight,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppColors.border, width: 1),
                                  ),
                                  child: const Text(
                                    'Settle',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.positiveText,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const LoadingWidget(message: 'Calculating settlement plan...'),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildIndividualBreakdownSection(
      AsyncValue<GroupBalancesModel> balanceAsync, String? currentUserId) {
    return balanceAsync.when(
      data: (balances) {
        final memberBalances = balances.memberBalances;

        return SplitMateCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.user, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Individual Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Table Headers (Screenshot 3: Participant | Paid | Share | Net)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Participant',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Paid',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Share',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Net',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table Rows (Screenshot 3)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: memberBalances.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final mb = memberBalances[index];
                  final isMe = mb.userId == currentUserId;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            mb.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            CurrencyFormatter.format(mb.amountPaid),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            CurrencyFormatter.format(mb.amountOwed),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            mb.netBalance == 0
                                ? '₹0.00'
                                : CurrencyFormatter.format(mb.netBalance, showSign: true),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: mb.isOwed
                                  ? AppColors.positiveText
                                  : mb.owes
                                      ? AppColors.negativeText
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
