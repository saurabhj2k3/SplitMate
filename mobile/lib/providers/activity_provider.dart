import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/activity_model.dart';

final groupActivityProvider =
    FutureProvider.family<List<ActivityModel>, String>((ref, groupId) async {
  final response = await apiClient.client.get('/groups/$groupId/activity');
  final rawList = response.data['data'] as List<dynamic>;
  return rawList
      .map((a) => ActivityModel.fromJson(a as Map<String, dynamic>))
      .toList();
});

final recentActivityProvider = FutureProvider<List<ActivityModel>>((ref) async {
  final response = await apiClient.client.get('/activity/recent');
  final rawList = response.data['data'] as List<dynamic>;
  return rawList
      .map((a) => ActivityModel.fromJson(a as Map<String, dynamic>))
      .toList();
});
