import { prisma } from '../config/db';

export class SettlementService {
  /**
   * Record a settlement (e.g. Rahul paid Saurabh ₹600)
   */
  static async recordSettlement(
    recordedById: string,
    data: {
      groupId: string;
      payerId: string;
      receiverId: string;
      amount: number;
      notes?: string;
      date?: string | Date;
    }
  ) {
    if (data.amount <= 0) {
      throw new Error('Settlement amount must be greater than zero.');
    }
    if (data.payerId === data.receiverId) {
      throw new Error('Payer and receiver cannot be the same person.');
    }

    // Verify both are members of the group
    const members = await prisma.groupMember.findMany({
      where: {
        groupId: data.groupId,
        userId: { in: [data.payerId, data.receiverId] },
      },
      include: { user: { select: { id: true, name: true } } },
    });

    if (members.length < 2) {
      throw new Error('Both payer and receiver must be members of this group.');
    }

    const payer = members.find((m) => m.userId === data.payerId)?.user;
    const receiver = members.find((m) => m.userId === data.receiverId)?.user;

    const settlement = await prisma.$transaction(async (tx) => {
      const s = await tx.settlement.create({
        data: {
          groupId: data.groupId,
          payerId: data.payerId,
          receiverId: data.receiverId,
          amount: data.amount,
          status: 'COMPLETED',
          notes: data.notes?.trim() || null,
          date: data.date ? new Date(data.date) : new Date(),
        },
        include: {
          payer: { select: { id: true, name: true, email: true, avatarUrl: true } },
          receiver: { select: { id: true, name: true, email: true, avatarUrl: true } },
        },
      });

      await tx.activity.create({
        data: {
          groupId: data.groupId,
          userId: recordedById,
          actionType: 'SETTLEMENT_RECORDED',
          details: `${payer?.name || 'Someone'} paid ₹${s.amount.toFixed(2)} to ${receiver?.name || 'Someone'}`,
        },
      });

      return s;
    });

    return settlement;
  }

  /**
   * Get all settlements for a group
   */
  static async getGroupSettlements(groupId: string) {
    const settlements = await prisma.settlement.findMany({
      where: { groupId },
      include: {
        payer: { select: { id: true, name: true, email: true, avatarUrl: true } },
        receiver: { select: { id: true, name: true, email: true, avatarUrl: true } },
      },
      orderBy: { date: 'desc' },
    });

    return settlements;
  }

  /**
   * Update settlement status
   */
  static async updateSettlementStatus(
    settlementId: string,
    userId: string,
    status: 'COMPLETED' | 'PENDING' | 'CANCELLED'
  ) {
    const settlement = await prisma.settlement.update({
      where: { id: settlementId },
      data: { status },
      include: {
        payer: { select: { id: true, name: true } },
        receiver: { select: { id: true, name: true } },
      },
    });

    await prisma.activity.create({
      data: {
        groupId: settlement.groupId,
        userId,
        actionType: 'SETTLEMENT_STATUS_UPDATED',
        details: `Settlement status updated to ${status}`,
      },
    });

    return settlement;
  }
}
