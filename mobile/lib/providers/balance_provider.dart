import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/balance_model.dart';

final groupBalancesProvider =
    FutureProvider.family<GroupBalancesModel, String>((ref, groupId) async {
  final response = await apiClient.client.get('/groups/$groupId/balances');
  return GroupBalancesModel.fromJson(response.data['data'] as Map<String, dynamic>);
});

final dashboardSummaryProvider =
    FutureProvider<DashboardSummaryModel>((ref) async {
  final response = await apiClient.client.get('/balances/dashboard');
  return DashboardSummaryModel.fromJson(response.data['data'] as Map<String, dynamic>);
});
