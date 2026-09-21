import 'user_model.dart';

class ExpenseSplitModel {
  final String id;
  final String userId;
  final UserModel? user;
  final double amount;
  final double? percentage;
  final double? shares;

  ExpenseSplitModel({
    required this.id,
    required this.userId,
    this.user,
    required this.amount,
    this.percentage,
    this.shares,
  });

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSplitModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] as String,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
      shares: (json['shares'] as num?)?.toDouble(),
    );
  }
}

class ExpenseModel {
  final String id;
  final String groupId;
  final String payerId;
  final UserModel? payer;
  final String createdById;
  final UserModel? createdBy;
  final String description;
  final double amount;
  final String splitMethod; // EQUAL, EXACT, PERCENTAGE, SHARES
  final String category;
  final DateTime date;
  final String? notes;
  final String? receiptUrl;
  final List<ExpenseSplitModel> splits;
  final DateTime? createdAt;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.payerId,
    this.payer,
    required this.createdById,
    this.createdBy,
    required this.description,
    required this.amount,
    required this.splitMethod,
    this.category = 'Other',
    required this.date,
    this.notes,
    this.receiptUrl,
    this.splits = const [],
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final rawSplits = json['splits'] as List<dynamic>? ?? [];
    return ExpenseModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      payerId: json['payerId'] as String,
      payer: json['payer'] != null
          ? UserModel.fromJson(json['payer'] as Map<String, dynamic>)
          : null,
      createdById: json['createdById'] as String? ?? '',
      createdBy: json['createdBy'] != null
          ? UserModel.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      splitMethod: json['splitMethod'] as String? ?? 'EQUAL',
      category: json['category'] as String? ?? 'Other',
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      notes: json['notes'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      splits: rawSplits
          .map((s) => ExpenseSplitModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
