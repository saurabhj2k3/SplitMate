class GroupMemberModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role; // OWNER or MEMBER
  final DateTime? joinedAt;

  GroupMemberModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.joinedAt,
  });

  bool get isOwner => role == 'OWNER';

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id']?.toString() ?? '',
      userId: (json['userId'] ?? json['id'])?.toString() ?? '',
      name: json['name'] as String? ?? 'Member',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'MEMBER',
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString())
          : null,
    );
  }
}

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String inviteCode;
  final String createdById;
  final String? role;
  final int memberCount;
  final double totalExpensesAmount;
  final int expenseCount;
  final List<GroupMemberModel> members;
  final DateTime? createdAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.inviteCode,
    required this.createdById,
    this.role,
    this.memberCount = 0,
    this.totalExpensesAmount = 0.0,
    this.expenseCount = 0,
    this.members = const [],
    this.createdAt,
  });

  bool get isUserOwner => role == 'OWNER';

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? [];
    final parsedMembers = rawMembers
        .map((m) => GroupMemberModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      inviteCode: json['inviteCode'] as String? ?? '',
      createdById: json['createdById'] as String? ?? '',
      role: json['role'] as String?,
      memberCount: json['memberCount'] as int? ?? parsedMembers.length,
      totalExpensesAmount: (json['totalExpensesAmount'] as num?)?.toDouble() ?? 0.0,
      expenseCount: json['expenseCount'] as int? ?? 0,
      members: parsedMembers,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
