import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/notebook_scaffold.dart';
import '../../core/widgets/notebook_top_bar.dart';
import '../../core/widgets/splitmate_button.dart';
import '../../core/widgets/splitmate_card.dart';
import '../../core/widgets/splitmate_text_field.dart';
import '../../models/expense_model.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  final GroupModel? preselectedGroup;
  final ExpenseModel? existingExpense;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    this.preselectedGroup,
    this.existingExpense,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _splitMethod = 'EQUAL'; // EQUAL, EXACT, PERCENTAGE, SHARES
  String? _selectedPayerId;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final Set<String> _selectedParticipants = {};
  final Map<String, TextEditingController> _customInputControllers = {};

  bool _isLoading = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final authUser = ref.read(authProvider).user;
    _selectedPayerId = authUser?.id;

    if (widget.existingExpense != null) {
      final exp = widget.existingExpense!;
      _descController.text = exp.description;
      _amountController.text = exp.amount.toStringAsFixed(2);
      _notesController.text = exp.notes ?? '';
      _splitMethod = exp.splitMethod;
      _selectedPayerId = exp.payerId;
      _selectedCategory = exp.category;
      _selectedDate = exp.date;

      for (final s in exp.splits) {
        _selectedParticipants.add(s.userId);
        if (_splitMethod == 'EXACT') {
          _customInputControllers[s.userId] =
              TextEditingController(text: s.amount.toStringAsFixed(2));
        } else if (_splitMethod == 'PERCENTAGE') {
          _customInputControllers[s.userId] =
              TextEditingController(text: (s.percentage ?? 0).toStringAsFixed(1));
        } else if (_splitMethod == 'SHARES') {
          _customInputControllers[s.userId] =
              TextEditingController(text: (s.shares ?? 1).toStringAsFixed(0));
        }
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final c in _customInputControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initializeParticipants(List<GroupMemberModel> members) {
    if (_selectedParticipants.isEmpty && widget.existingExpense == null) {
      for (final m in members) {
        _selectedParticipants.add(m.userId);
        _customInputControllers[m.userId] = TextEditingController(text: '1');
      }
    } else {
      for (final m in members) {
        if (!_customInputControllers.containsKey(m.userId)) {
          _customInputControllers[m.userId] = TextEditingController(text: '1');
        }
      }
    }
    if (_selectedPayerId == null && members.isNotEmpty) {
      _selectedPayerId = members.first.userId;
    }
  }

  double get _parsedTotalAmount {
    return double.tryParse(_amountController.text.trim()) ?? 0.0;
  }

  String? _validateInputs() {
    if (_descController.text.trim().isEmpty) {
      return 'Please enter an expense title (e.g. Dinner, Taxi fare).';
    }
    final total = _parsedTotalAmount;
    if (total <= 0) {
      return 'Please enter a valid expense amount greater than ₹0.';
    }
    if (_selectedPayerId == null) {
      return 'Please select who paid for this expense.';
    }
    if (_selectedParticipants.isEmpty) {
      return 'Please select at least one participant.';
    }

    if (_splitMethod == 'EXACT') {
      double exactSum = 0;
      for (final userId in _selectedParticipants) {
        final val = double.tryParse(_customInputControllers[userId]?.text ?? '') ?? 0;
        exactSum += val;
      }
      final diff = (total - exactSum).abs();
      if (diff > 0.05) {
        return 'Exact split sum (₹${exactSum.toStringAsFixed(2)}) must equal total (₹${total.toStringAsFixed(2)}). Diff: ₹${diff.toStringAsFixed(2)}';
      }
    } else if (_splitMethod == 'PERCENTAGE') {
      double pctSum = 0;
      for (final userId in _selectedParticipants) {
        final val = double.tryParse(_customInputControllers[userId]?.text ?? '') ?? 0;
        pctSum += val;
      }
      if ((pctSum - 100).abs() > 0.05) {
        return 'Percentages must total exactly 100%. Current sum: ${pctSum.toStringAsFixed(1)}%';
      }
    } else if (_splitMethod == 'SHARES') {
      double shareSum = 0;
      for (final userId in _selectedParticipants) {
        final val = double.tryParse(_customInputControllers[userId]?.text ?? '') ?? 0;
        shareSum += val;
      }
      if (shareSum <= 0) {
        return 'Total shares must be greater than zero.';
      }
    }

    return null;
  }

  Future<void> _handleSave() async {
    final error = _validateInputs();
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _validationError = null;
    });

    final splits = _selectedParticipants.map((userId) {
      final inputVal = double.tryParse(_customInputControllers[userId]?.text ?? '') ?? 0;
      return {
        'userId': userId,
        if (_splitMethod == 'EXACT') 'amount': inputVal,
        if (_splitMethod == 'PERCENTAGE') 'percentage': inputVal,
        if (_splitMethod == 'SHARES') 'shares': inputVal,
      };
    }).toList();

    try {
      if (widget.existingExpense != null) {
        await ref
            .read(groupExpensesProvider(widget.groupId).notifier)
            .updateExpense(
              expenseId: widget.existingExpense!.id,
              payerId: _selectedPayerId!,
              description: _descController.text.trim(),
              amount: _parsedTotalAmount,
              splitMethod: _splitMethod,
              category: _selectedCategory,
              date: _selectedDate,
              notes: _notesController.text.trim(),
              splits: splits,
            );
      } else {
        await ref
            .read(groupExpensesProvider(widget.groupId).notifier)
            .createExpense(
              payerId: _selectedPayerId!,
              description: _descController.text.trim(),
              amount: _parsedTotalAmount,
              splitMethod: _splitMethod,
              category: _selectedCategory,
              date: _selectedDate,
              notes: _notesController.text.trim(),
              splits: splits,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _validationError = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(singleGroupProvider(widget.groupId));

    return NotebookScaffold(
      appBar: NotebookTopBar(
        onDashboardClick: () => Navigator.of(context).pop(),
      ),
      body: groupAsync.when(
        data: (group) {
          _initializeParticipants(group.members);

          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 500;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20,
              vertical: isMobile ? 16 : 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: SplitMateCard(
                  padding: EdgeInsets.all(isMobile ? 18 : 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header (Screenshot 4)
                      Text(
                        widget.existingExpense != null
                            ? 'Edit Expense'
                            : 'Add New Expense',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Group: ${group.name}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_validationError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.negativeLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.negative.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.circle_alert,
                                  size: 16, color: AppColors.negative),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _validationError!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.negativeText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Expense Title * (Screenshot 4)
                      SplitMateTextField(
                        label: 'Expense Title *',
                        hint: 'e.g. Dinner at Bistro, Grocery Shopping, Taxi fare',
                        controller: _descController,
                        autofocus: widget.existingExpense == null,
                      ),
                      const SizedBox(height: 16),

                      // Row: Amount (₹) * & Expense Date (Screenshot 4)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SplitMateTextField(
                              label: 'Amount (₹) *',
                              hint: '0.00',
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Expense Date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedDate = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border, width: 2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const Icon(LucideIcons.calendar,
                                            size: 16, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Who Paid? * dropdown (Screenshot 4)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Who Paid? *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text('-- Select Participant Who Paid --'),
                                value: _selectedPayerId,
                                items: group.members.map((m) {
                                  return DropdownMenuItem(
                                    value: m.userId,
                                    child: Text(
                                      m.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedPayerId = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Split Between Selected Participants * (Screenshot 4)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Split Between Selected Participants *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_selectedParticipants.length == group.members.length) {
                                  _selectedParticipants.clear();
                                } else {
                                  _selectedParticipants.addAll(group.members.map((m) => m.userId));
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: Text(
                                _selectedParticipants.length == group.members.length
                                    ? 'Deselect All'
                                    : 'Select All',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Participant Checkbox Grid (Screenshot 4: 2 columns in pill containers)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 400 ? 2 : 1;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              mainAxisExtent: 48,
                            ),
                            itemCount: group.members.length,
                            itemBuilder: (context, index) {
                              final member = group.members[index];
                              final isSelected = _selectedParticipants.contains(member.userId);

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedParticipants.remove(member.userId);
                                    } else {
                                      _selectedParticipants.add(member.userId);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedParticipants.add(member.userId);
                                            } else {
                                              _selectedParticipants.remove(member.userId);
                                            }
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: Text(
                                          member.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_splitMethod != 'EQUAL' && isSelected) ...[
                                        SizedBox(
                                          width: 50,
                                          height: 30,
                                          child: TextField(
                                            controller: _customInputControllers[member.userId],
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 11),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button (Screenshot 4)
                      SplitMateButton(
                        label: widget.existingExpense != null ? 'Save Changes' : 'Save Expense',
                        variant: ButtonVariant.primary,
                        height: 48,
                        isLoading: _isLoading,
                        onPressed: _handleSave,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
