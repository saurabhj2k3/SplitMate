import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/splitmate_button.dart';
import '../../core/widgets/splitmate_text_field.dart';
import '../../models/group_model.dart';
import '../../providers/settlement_provider.dart';

class SettleUpDialog extends ConsumerStatefulWidget {
  final String groupId;
  final List<GroupMemberModel> members;
  final String defaultPayerId;
  final String defaultReceiverId;
  final double defaultAmount;

  const SettleUpDialog({
    super.key,
    required this.groupId,
    required this.members,
    required this.defaultPayerId,
    required this.defaultReceiverId,
    required this.defaultAmount,
  });

  @override
  ConsumerState<SettleUpDialog> createState() => _SettleUpDialogState();
}

class _SettleUpDialogState extends ConsumerState<SettleUpDialog> {
  late String _payerId;
  late String _receiverId;
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _payerId = widget.defaultPayerId;
    _receiverId = widget.defaultReceiverId;
    _amountController =
        TextEditingController(text: widget.defaultAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSettle() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Please enter an amount greater than ₹0.');
      return;
    }
    if (_payerId == _receiverId) {
      setState(() => _errorMessage = 'Payer and recipient cannot be the same person.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(groupSettlementsProvider(widget.groupId).notifier)
          .recordSettlement(
            payerId: _payerId,
            receiverId: _receiverId,
            amount: amount,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Record Settlement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Confirm a direct payment between group members (Cash, UPI, Bank transfer).',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: AppColors.negative),
                ),
                const SizedBox(height: 12),
              ],

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Who paid?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _payerId,
                        items: widget.members.map((m) {
                          return DropdownMenuItem(
                            value: m.userId,
                            child: Row(
                              children: [
                                AvatarWidget(name: m.name, size: 24, fontSize: 10),
                                const SizedBox(width: 8),
                                Text(m.name, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _payerId = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paid to whom?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _receiverId,
                        items: widget.members.map((m) {
                          return DropdownMenuItem(
                            value: m.userId,
                            child: Row(
                              children: [
                                AvatarWidget(name: m.name, size: 24, fontSize: 10),
                                const SizedBox(width: 8),
                                Text(m.name, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _receiverId = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              SplitMateTextField(
                label: 'Amount (₹ INR)',
                hint: '0.00',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 14),

              SplitMateTextField(
                label: 'Notes (Optional)',
                hint: 'e.g. Paid via Google Pay / Cash',
                controller: _notesController,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SplitMateButton(
                    label: 'Cancel',
                    variant: ButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  SplitMateButton(
                    label: 'Confirm Settlement',
                    isLoading: _isLoading,
                    onPressed: _handleSettle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
