import 'user_model.dart';

class SettlementModel {
  final String id;
  final String groupId;
  final String payerId;
  final UserModel? payer;
  final String receiverId;
  final UserModel? receiver;
  final double amount;
  final String status; // PENDING, COMPLETED, CANCELLED
  final String? notes;
  final DateTime date;
  final DateTime? createdAt;

  SettlementModel({
    required this.id,
    required this.groupId,
    required this.payerId,
    this.payer,
    required this.receiverId,
    this.receiver,
    required this.amount,
    this.status = 'COMPLETED',
    this.notes,
    required this.date,
    this.createdAt,
  });

  bool get isCompleted => status == 'COMPLETED';

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      payerId: json['payerId'] as String,
      payer: json['payer'] != null
          ? UserModel.fromJson(json['payer'] as Map<String, dynamic>)
          : null,
      receiverId: json['receiverId'] as String,
      receiver: json['receiver'] != null
          ? UserModel.fromJson(json['receiver'] as Map<String, dynamic>)
          : null,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'COMPLETED',
      notes: json['notes'] as String?,
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
