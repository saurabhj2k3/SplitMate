import { prisma } from '../config/db';
import { calculateDirectDebts, simplifyDebts, roundTo2Decimals } from '../utils/math';

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
            payer: { select: { id: true, name: true, email: true, avatarUrl: true } },
            splits: {
              include: {
                user: { select: { id: true, name: true, email: true, avatarUrl: true } },
              },
            },
          },
        },
        settlements: {
          where: { status: 'COMPLETED' },
          include: {
            payer: { select: { id: true, name: true, email: true, avatarUrl: true } },
            receiver: { select: { id: true, name: true, email: true, avatarUrl: true } },
          },
        },
      },
    });

    if (!group) {
      throw new Error('Group not found.');
    }

    const membersMap = new Map<string, { name: string; email: string; avatarUrl?: string | null }>();
    const balances: Record<string, UserBalance> = {};

    const ensureUserInBalances = (user: { id: string; name: string; email: string; avatarUrl?: string | null }) => {
      if (!membersMap.has(user.id)) {
        membersMap.set(user.id, {
          name: user.name,
          email: user.email,
          avatarUrl: user.avatarUrl,
        });
      }
      if (!balances[user.id]) {
        balances[user.id] = {
          userId: user.id,
          name: user.name,
          email: user.email,
          avatarUrl: user.avatarUrl,
          amountPaid: 0,
          amountOwed: 0,
          settlementPaid: 0,
          settlementReceived: 0,
          netBalance: 0,
        };
      }
    };

    for (const m of group.members) {
      ensureUserInBalances(m.user);
    }

    // 1. Process Expenses & register any non-member payers/participants
    for (const expense of group.expenses) {
      if (expense.payer) {
        ensureUserInBalances(expense.payer);
      }
      if (balances[expense.payerId]) {
        balances[expense.payerId].amountPaid += expense.amount;
      }
      for (const split of expense.splits) {
        if (split.user) {
          ensureUserInBalances(split.user);
        }
        if (balances[split.userId]) {
          balances[split.userId].amountOwed += split.amount;
        }
      }
    }

    // 2. Process Completed Settlements
    for (const settlement of group.settlements) {
      if (settlement.payer) {
        ensureUserInBalances(settlement.payer);
      }
      if (settlement.receiver) {
        ensureUserInBalances(settlement.receiver);
      }
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

    // 4. Compute Direct Debts (Option B: Itemized Payer-to-Participant bilateral debts)
    const directExpenses = group.expenses.map((e) => ({
      payerId: e.payerId,
      splits: e.splits.map((s) => ({ userId: s.userId, amount: s.amount })),
    }));

    const directSettlements = group.settlements.map((s) => ({
      payerId: s.payerId,
      receiverId: s.receiverId,
      amount: s.amount,
    }));

    const debtsList = calculateDirectDebts(directExpenses, directSettlements);

    const simplifiedDebts: GroupSettlementDebt[] = debtsList.map((debt) => {
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

    const groupBalances = await Promise.all(
      userGroups.map((ug) => this.getGroupBalances(ug.groupId))
    );

    for (const groupBalance of groupBalances) {
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
