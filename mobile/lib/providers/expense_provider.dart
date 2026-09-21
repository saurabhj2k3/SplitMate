import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/expense_model.dart';
import 'balance_provider.dart';
import 'group_provider.dart';

class GroupExpensesNotifier extends StateNotifier<AsyncValue<List<ExpenseModel>>> {
  final String groupId;
  final Ref ref;

  GroupExpensesNotifier({required this.groupId, required this.ref})
      : super(const AsyncValue.loading()) {
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.client.get('/groups/$groupId/expenses');
      final rawList = response.data['data'] as List<dynamic>;
      final expenses = rawList
          .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(expenses);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createExpense({
    required String payerId,
    required String description,
    required double amount,
    required String splitMethod,
    String? category,
    DateTime? date,
    String? notes,
    required List<Map<String, dynamic>> splits,
  }) async {
    await apiClient.client.post('/groups/$groupId/expenses', data: {
      'payerId': payerId,
      'description': description.trim(),
      'amount': amount,
      'splitMethod': splitMethod,
      'category': category ?? 'Other',
      'date': date?.toIso8601String(),
      'notes': notes?.trim(),
      'splits': splits,
    });
    await fetchExpenses();
    ref.invalidate(groupBalancesProvider(groupId));
    ref.invalidate(dashboardSummaryProvider);
    ref.read(groupListProvider.notifier).fetchGroups();
  }

  Future<void> updateExpense({
    required String expenseId,
    required String payerId,
    required String description,
    required double amount,
    required String splitMethod,
    String? category,
    DateTime? date,
    String? notes,
    required List<Map<String, dynamic>> splits,
  }) async {
    await apiClient.client.patch('/expenses/$expenseId', data: {
      'payerId': payerId,
      'description': description.trim(),
      'amount': amount,
      'splitMethod': splitMethod,
      'category': category ?? 'Other',
      'date': date?.toIso8601String(),
      'notes': notes?.trim(),
      'splits': splits,
    });
    await fetchExpenses();
    ref.invalidate(groupBalancesProvider(groupId));
    ref.invalidate(dashboardSummaryProvider);
    ref.read(groupListProvider.notifier).fetchGroups();
  }

  Future<void> deleteExpense(String expenseId) async {
    await apiClient.client.delete('/expenses/$expenseId');
    await fetchExpenses();
    ref.invalidate(groupBalancesProvider(groupId));
    ref.invalidate(dashboardSummaryProvider);
    ref.read(groupListProvider.notifier).fetchGroups();
  }
}

final groupExpensesProvider = StateNotifierProvider.family<
    GroupExpensesNotifier,
    AsyncValue<List<ExpenseModel>>,
    String>((ref, groupId) {
  return GroupExpensesNotifier(groupId: groupId, ref: ref);
});
