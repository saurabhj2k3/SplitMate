import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/group_model.dart';

class GroupListNotifier extends StateNotifier<AsyncValue<List<GroupModel>>> {
  GroupListNotifier() : super(const AsyncValue.loading()) {
    fetchGroups();
  }

  Future<void> fetchGroups({bool forceRefresh = false}) async {
    if (state.value == null || forceRefresh) {
      state = const AsyncValue.loading();
    }
    try {
      final response = await apiClient.client.get('/groups');
      final rawList = response.data['data'] as List<dynamic>;
      final groups = rawList
          .map((g) => GroupModel.fromJson(g as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(groups);
    } catch (e, stack) {
      if (state.value == null) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<GroupModel> createGroup({
    required String name,
    String? description,
  }) async {
    final response = await apiClient.client.post('/groups', data: {
      'name': name.trim(),
      'description': description?.trim(),
    });
    final created = GroupModel.fromJson(response.data['data'] as Map<String, dynamic>);
    await fetchGroups();
    return created;
  }

  Future<GroupModel> joinByInviteCode(String inviteCode) async {
    final response = await apiClient.client.post('/groups/join', data: {
      'inviteCode': inviteCode.trim().toUpperCase(),
    });
    final group = GroupModel.fromJson(response.data['data']['group'] as Map<String, dynamic>);
    await fetchGroups();
    return group;
  }

  Future<void> addMember(String groupId, String identifier) async {
    await apiClient.client.post('/groups/$groupId/members', data: {
      'identifier': identifier.trim(),
    });
    await fetchGroups();
  }

  Future<void> removeMember(String groupId, String userId) async {
    await apiClient.client.delete('/groups/$groupId/members/$userId');
    await fetchGroups();
  }

  Future<void> deleteGroup(String groupId) async {
    await apiClient.client.delete('/groups/$groupId');
    await fetchGroups();
  }
}

final groupListProvider =
    StateNotifierProvider<GroupListNotifier, AsyncValue<List<GroupModel>>>((ref) {
  return GroupListNotifier();
});

final singleGroupProvider =
    FutureProvider.family<GroupModel, String>((ref, groupId) async {
  final response = await apiClient.client.get('/groups/$groupId');
  return GroupModel.fromJson(response.data['data'] as Map<String, dynamic>);
});
