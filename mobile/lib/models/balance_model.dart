class UserBalanceModel {
  final String userId;
  final String name;
  final String email;
  final String? avatarUrl;
  final double amountPaid;
  final double amountOwed;
  final double settlementPaid;
  final double settlementReceived;
  final double netBalance; // positive = receives, negative = owes

  UserBalanceModel({
    required this.userId,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.amountPaid,
    required this.amountOwed,
    required this.settlementPaid,
    required this.settlementReceived,
    required this.netBalance,
  });

  bool get isOwed => netBalance > 0.009;
  bool get owes => netBalance < -0.009;
  bool get isSettled => !isOwed && !owes;

  factory UserBalanceModel.fromJson(Map<String, dynamic> json) {
    return UserBalanceModel(
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      amountPaid: (json['amountPaid'] as num).toDouble(),
      amountOwed: (json['amountOwed'] as num).toDouble(),
      settlementPaid: (json['settlementPaid'] as num).toDouble(),
      settlementReceived: (json['settlementReceived'] as num).toDouble(),
      netBalance: (json['netBalance'] as num).toDouble(),
    );
  }
}

class SimplifiedDebtModel {
  final String fromUserId;
  final String fromUserName;
  final String? fromUserAvatar;
  final String toUserId;
  final String toUserName;
  final String? toUserAvatar;
  final double amount;

  SimplifiedDebtModel({
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserAvatar,
    required this.toUserId,
    required this.toUserName,
    this.toUserAvatar,
    required this.amount,
  });

  factory SimplifiedDebtModel.fromJson(Map<String, dynamic> json) {
    return SimplifiedDebtModel(
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      fromUserAvatar: json['fromUserAvatar'] as String?,
      toUserId: json['toUserId'] as String,
      toUserName: json['toUserName'] as String,
      toUserAvatar: json['toUserAvatar'] as String?,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class GroupBalancesModel {
  final String groupId;
  final String groupName;
  final double totalGroupExpense;
  final List<UserBalanceModel> memberBalances;
  final List<SimplifiedDebtModel> simplifiedDebts;

  GroupBalancesModel({
    required this.groupId,
    required this.groupName,
    required this.totalGroupExpense,
    required this.memberBalances,
    required this.simplifiedDebts,
  });

  factory GroupBalancesModel.fromJson(Map<String, dynamic> json) {
    final rawBalances = json['memberBalances'] as List<dynamic>? ?? [];
    final rawDebts = json['simplifiedDebts'] as List<dynamic>? ?? [];

    return GroupBalancesModel(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      totalGroupExpense: (json['totalGroupExpense'] as num).toDouble(),
      memberBalances: rawBalances
          .map((b) => UserBalanceModel.fromJson(b as Map<String, dynamic>))
          .toList(),
      simplifiedDebts: rawDebts
          .map((d) => SimplifiedDebtModel.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardGroupSummary {
  final String groupId;
  final String groupName;
  final double userNetBalance;

  DashboardGroupSummary({
    required this.groupId,
    required this.groupName,
    required this.userNetBalance,
  });

  factory DashboardGroupSummary.fromJson(Map<String, dynamic> json) {
    return DashboardGroupSummary(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      userNetBalance: (json['userNetBalance'] as num).toDouble(),
    );
  }
}

class DashboardSummaryModel {
  final double totalOwedToYou;
  final double totalYouOwe;
  final double netBalance;
  final List<DashboardGroupSummary> groupSummaries;

  DashboardSummaryModel({
    required this.totalOwedToYou,
    required this.totalYouOwe,
    required this.netBalance,
    required this.groupSummaries,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawSummaries = json['groupSummaries'] as List<dynamic>? ?? [];
    return DashboardSummaryModel(
      totalOwedToYou: (json['totalOwedToYou'] as num).toDouble(),
      totalYouOwe: (json['totalYouOwe'] as num).toDouble(),
      netBalance: (json['netBalance'] as num).toDouble(),
      groupSummaries: rawSummaries
          .map((s) => DashboardGroupSummary.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
