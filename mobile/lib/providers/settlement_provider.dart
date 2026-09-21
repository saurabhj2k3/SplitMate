import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/settlement_model.dart';
import 'balance_provider.dart';

class GroupSettlementsNotifier
    extends StateNotifier<AsyncValue<List<SettlementModel>>> {
  final String groupId;
  final Ref ref;

  GroupSettlementsNotifier({required this.groupId, required this.ref})
      : super(const AsyncValue.loading()) {
    fetchSettlements();
  }

  Future<void> fetchSettlements() async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.client.get('/groups/$groupId/settlements');
      final rawList = response.data['data'] as List<dynamic>;
      final settlements = rawList
          .map((s) => SettlementModel.fromJson(s as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(settlements);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> recordSettlement({
    required String payerId,
    required String receiverId,
    required double amount,
    String? notes,
    DateTime? date,
  }) async {
    await apiClient.client.post('/groups/$groupId/settlements', data: {
      'payerId': payerId,
      'receiverId': receiverId,
      'amount': amount,
      'notes': notes?.trim(),
      'date': date?.toIso8601String(),
    });
    await fetchSettlements();
    ref.invalidate(groupBalancesProvider(groupId));
    ref.invalidate(dashboardSummaryProvider);
  }
}

final groupSettlementsProvider = StateNotifierProvider.family<
    GroupSettlementsNotifier,
    AsyncValue<List<SettlementModel>>,
    String>((ref, groupId) {
  return GroupSettlementsNotifier(groupId: groupId, ref: ref);
});
