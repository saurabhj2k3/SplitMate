import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../constants/colors.dart';
import '../utils/currency_formatter.dart';
import 'avatar_widget.dart';
import 'splitmate_button.dart';

class DebtFlowIndicator extends StatelessWidget {
  final String fromUserName;
  final String? fromUserAvatar;
  final String toUserName;
  final String? toUserAvatar;
  final double amount;
  final VoidCallback? onSettle;
  final bool isCurrentUserDebtor;
  final bool isCurrentUserCreditor;

  const DebtFlowIndicator({
    super.key,
    required this.fromUserName,
    this.fromUserAvatar,
    required this.toUserName,
    this.toUserAvatar,
    required this.amount,
    this.onSettle,
    this.isCurrentUserDebtor = false,
    this.isCurrentUserCreditor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isCurrentUserDebtor || isCurrentUserCreditor)
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
          width: (isCurrentUserDebtor || isCurrentUserCreditor) ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    AvatarWidget(
                      name: fromUserName,
                      imageUrl: fromUserAvatar,
                      size: 32,
                      fontSize: 12,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCurrentUserDebtor ? 'You' : fromUserName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrentUserDebtor
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'owes',
                            style: TextStyle(
                              fontSize: 11,
                              color: isCurrentUserDebtor
                                  ? AppColors.negative
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.arrow_right,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      CurrencyFormatter.format(amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isCurrentUserCreditor ? 'You' : toUserName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrentUserCreditor
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'receives',
                            style: TextStyle(
                              fontSize: 11,
                              color: isCurrentUserCreditor
                                  ? AppColors.positive
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AvatarWidget(
                      name: toUserName,
                      imageUrl: toUserAvatar,
                      size: 32,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (onSettle != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCurrentUserDebtor
                      ? 'You owe this settlement'
                      : isCurrentUserCreditor
                          ? 'You are owed this settlement'
                          : 'Settlement between members',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SplitMateButton(
                  label: 'Mark as Paid',
                  variant: ButtonVariant.secondary,
                  height: 32,
                  icon: LucideIcons.circle_check,
                  onPressed: onSettle,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
