import 'user_model.dart';

class ActivityModel {
  final String id;
  final String groupId;
  final String userId;
  final UserModel? user;
  final String? groupName;
  final String actionType;
  final String details;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.groupId,
    required this.userId,
    this.user,
    this.groupName,
    required this.actionType,
    required this.details,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      userId: json['userId'] as String,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      groupName: json['group'] != null ? json['group']['name'] as String? : null,
      actionType: json['actionType'] as String,
      details: json['details'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}
