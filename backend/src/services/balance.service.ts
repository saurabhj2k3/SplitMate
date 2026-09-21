import { prisma } from '../config/db';
import { simplifyDebts, roundTo2Decimals } from '../utils/math';

export interface UserBalance {
  userId: string;
  name: string;
  email: string;
  avatarUrl?: string | null;
  amountPaid: number;
  amountOwed: number;
  settlementPaid: number;
  settlementReceived: number;
  netBalance: number; // positive = should receive, negative = owes
}

export interface GroupSettlementDebt {
  fromUserId: string;
  fromUserName: string;
  fromUserAvatar?: string | null;
  toUserId: string;
  toUserName: string;
  toUserAvatar?: string | null;
  amount: number;
}

export class BalanceService {
  /**
   * Calculate detailed balances and simplified debts for a specific group
   */
  static async getGroupBalances(groupId: string) {
    const group = await prisma.group.findUnique({
      where: { id: groupId },
      include: {
        members: {
          include: {
            user: { select: { id: true, name: true, email: true, avatarUrl: true } },
          },
        },
        expenses: {
          where: { isDeleted: false },
          include: {
            splits: true,
          },
        },
        settlements: {
          where: { status: 'COMPLETED' },
        },
      },
    });

    if (!group) {
      throw new Error('Group not found.');
    }

    const membersMap = new Map<string, { name: string; email: string; avatarUrl?: string | null }>();
    const balances: Record<string, UserBalance> = {};

    for (const m of group.members) {
      membersMap.set(m.user.id, {
        name: m.user.name,
        email: m.user.email,
        avatarUrl: m.user.avatarUrl,
      });
      balances[m.user.id] = {
        userId: m.user.id,
        name: m.user.name,
        email: m.user.email,
        avatarUrl: m.user.avatarUrl,
        amountPaid: 0,
        amountOwed: 0,
        settlementPaid: 0,
        settlementReceived: 0,
        netBalance: 0,
      };
    }

    // 1. Process Expenses
    for (const expense of group.expenses) {
      if (balances[expense.payerId]) {
        balances[expense.payerId].amountPaid += expense.amount;
      }
      for (const split of expense.splits) {
        if (balances[split.userId]) {
          balances[split.userId].amountOwed += split.amount;
        }
      }
    }

    // 2. Process Completed Settlements
    for (const settlement of group.settlements) {
      if (balances[settlement.payerId]) {
        balances[settlement.payerId].settlementPaid += settlement.amount;
      }
      if (balances[settlement.receiverId]) {
        balances[settlement.receiverId].settlementReceived += settlement.amount;
      }
    }

    // 3. Compute Net Balance for each member
    const netBalancesRecord: Record<string, number> = {};
    const memberBalancesList: UserBalance[] = [];

    for (const userId of Object.keys(balances)) {
      const b = balances[userId];
      b.amountPaid = roundTo2Decimals(b.amountPaid);
      b.amountOwed = roundTo2Decimals(b.amountOwed);
      b.settlementPaid = roundTo2Decimals(b.settlementPaid);
      b.settlementReceived = roundTo2Decimals(b.settlementReceived);

      // Net balance formula:
      // What user paid for others - What user owes for expenses + What user paid in settlements - What user received in settlements
      const net = roundTo2Decimals(
        b.amountPaid - b.amountOwed + (b.settlementPaid - b.settlementReceived)
      );
      b.netBalance = net;
      netBalancesRecord[userId] = net;
      memberBalancesList.push(b);
    }

    // 4. Compute Simplified Debts ("Who Owes Whom")
    const simplified = simplifyDebts(netBalancesRecord);

    const simplifiedDebts: GroupSettlementDebt[] = simplified.map((debt) => {
      const fromUser = membersMap.get(debt.from);
      const toUser = membersMap.get(debt.to);
      return {
        fromUserId: debt.from,
        fromUserName: fromUser?.name || 'Unknown',
        fromUserAvatar: fromUser?.avatarUrl,
        toUserId: debt.to,
        toUserName: toUser?.name || 'Unknown',
        toUserAvatar: toUser?.avatarUrl,
        amount: debt.amount,
      };
    });

    const totalGroupExpense = roundTo2Decimals(
      group.expenses.reduce((sum, e) => sum + e.amount, 0)
    );

    return {
      groupId: group.id,
      groupName: group.name,
      totalGroupExpense,
      memberBalances: memberBalancesList,
      simplifiedDebts,
    };
  }

  /**
   * Calculate dashboard overview for a specific user across all their groups
   */
  static async getUserDashboardSummary(userId: string) {
    const userGroups = await prisma.groupMember.findMany({
      where: { userId },
      select: { groupId: true },
    });

    let totalOwedToYou = 0;
    let totalYouOwe = 0;
    const groupSummaries: Array<{
      groupId: string;
      groupName: string;
      userNetBalance: number;
    }> = [];

    for (const ug of userGroups) {
      const groupBalance = await this.getGroupBalances(ug.groupId);
      const myBalance = groupBalance.memberBalances.find((m) => m.userId === userId);
      const userNet = myBalance ? myBalance.netBalance : 0;

      if (userNet > 0) {
        totalOwedToYou += userNet;
      } else if (userNet < 0) {
        totalYouOwe += Math.abs(userNet);
      }

      groupSummaries.push({
        groupId: groupBalance.groupId,
        groupName: groupBalance.groupName,
        userNetBalance: userNet,
      });
    }

    totalOwedToYou = roundTo2Decimals(totalOwedToYou);
    totalYouOwe = roundTo2Decimals(totalYouOwe);
    const netBalance = roundTo2Decimals(totalOwedToYou - totalYouOwe);

    return {
      totalOwedToYou,
      totalYouOwe,
      netBalance,
      groupSummaries,
    };
  }
}
