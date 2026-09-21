import { prisma } from '../config/db';
import {
  calculateEqualSplit,
  validateAndCalculateExactSplit,
  validateAndCalculatePercentageSplit,
  validateAndCalculateSharesSplit,
  SplitResult,
} from '../utils/math';

export type SplitMethodType = 'EQUAL' | 'EXACT' | 'PERCENTAGE' | 'SHARES';

export interface CreateExpenseDTO {
  groupId: string;
  payerId: string;
  description: string;
  amount: number;
  splitMethod: SplitMethodType;
  category?: string;
  date?: string | Date;
  notes?: string;
  receiptUrl?: string;
  splits: Array<{
    userId: string;
    amount?: number;
    percentage?: number;
    shares?: number;
  }>;
}

export class ExpenseService {
  /**
   * Helper to validate that all given userIds are members of the group
   */
  private static async validateGroupMembership(groupId: string, userIds: string[]) {
    const members = await prisma.groupMember.findMany({
      where: {
        groupId,
        userId: { in: userIds },
      },
      select: { userId: true },
    });

    const memberIds = new Set(members.map((m) => m.userId));
    for (const id of userIds) {
      if (!memberIds.has(id)) {
        throw new Error(`User ${id} is not a member of this group.`);
      }
    }
  }

  /**
   * Calculate splits based on method
   */
  public static computeSplits(
    amount: number,
    splitMethod: SplitMethodType,
    splits: Array<{ userId: string; amount?: number; percentage?: number; shares?: number }>
  ): SplitResult[] {
    if (amount <= 0) {
      throw new Error('Expense amount must be greater than zero.');
    }

    if (!splits || splits.length === 0) {
      throw new Error('At least one participant must be selected.');
    }

    switch (splitMethod) {
      case 'EQUAL': {
        const userIds = splits.map((s) => s.userId);
        return calculateEqualSplit(amount, userIds);
      }
      case 'EXACT': {
        const exactSplits = splits.map((s) => ({
          userId: s.userId,
          amount: s.amount ?? 0,
        }));
        return validateAndCalculateExactSplit(amount, exactSplits);
      }
      case 'PERCENTAGE': {
        const pctSplits = splits.map((s) => ({
          userId: s.userId,
          percentage: s.percentage ?? 0,
        }));
        return validateAndCalculatePercentageSplit(amount, pctSplits);
      }
      case 'SHARES': {
        const shareSplits = splits.map((s) => ({
          userId: s.userId,
          shares: s.shares ?? 1,
        }));
        return validateAndCalculateSharesSplit(amount, shareSplits);
      }
      default:
        throw new Error(`Unsupported split method: ${splitMethod}`);
    }
  }

  /**
   * Create an expense
   */
  static async createExpense(createdById: string, data: CreateExpenseDTO) {
    if (!data.description || data.description.trim().length === 0) {
      throw new Error('Expense description is required.');
    }

    const participantIds = [data.payerId, ...data.splits.map((s) => s.userId)];
    const uniqueParticipants = Array.from(new Set(participantIds));

    // Verify membership
    await this.validateGroupMembership(data.groupId, uniqueParticipants);

    // Compute exact splits
    const computedSplits = this.computeSplits(data.amount, data.splitMethod, data.splits);

    // Create expense and splits in transaction
    const expense = await prisma.$transaction(async (tx) => {
      const exp = await tx.expense.create({
        data: {
          groupId: data.groupId,
          payerId: data.payerId,
          createdById,
          description: data.description.trim(),
          amount: data.amount,
          splitMethod: data.splitMethod as any,
          category: data.category || 'Other',
          date: data.date ? new Date(data.date) : new Date(),
          notes: data.notes?.trim() || null,
          receiptUrl: data.receiptUrl || null,
          splits: {
            create: computedSplits.map((s) => ({
              userId: s.userId,
              amount: s.amount,
              percentage: s.percentage !== undefined ? s.percentage : null,
              shares: s.shares !== undefined ? s.shares : null,
            })),
          },
        },
        include: {
          payer: { select: { id: true, name: true, email: true, avatarUrl: true } },
          createdBy: { select: { id: true, name: true, email: true } },
          splits: {
            include: {
              user: { select: { id: true, name: true, email: true, avatarUrl: true } },
            },
          },
        },
      });

      // Record activity
      await tx.activity.create({
        data: {
          groupId: data.groupId,
          userId: createdById,
          actionType: 'EXPENSE_CREATED',
          details: `Added "${exp.description}" for ₹${exp.amount.toFixed(2)}`,
        },
      });

      return exp;
    });

    return expense;
  }

  /**
   * Get all expenses for a group
   */
  static async getGroupExpenses(groupId: string) {
    const expenses = await prisma.expense.findMany({
      where: {
        groupId,
        isDeleted: false,
      },
      include: {
        payer: { select: { id: true, name: true, email: true, avatarUrl: true } },
        createdBy: { select: { id: true, name: true, email: true } },
        splits: {
          include: {
            user: { select: { id: true, name: true, email: true, avatarUrl: true } },
          },
        },
      },
      orderBy: {
        date: 'desc',
      },
    });

    return expenses;
  }

  /**
   * Get expense by ID
   */
  static async getExpenseById(expenseId: string) {
    const expense = await prisma.expense.findUnique({
      where: { id: expenseId },
      include: {
        payer: { select: { id: true, name: true, email: true, avatarUrl: true } },
        createdBy: { select: { id: true, name: true, email: true } },
        splits: {
          include: {
            user: { select: { id: true, name: true, email: true, avatarUrl: true } },
          },
        },
      },
    });

    if (!expense || expense.isDeleted) {
      throw new Error('Expense not found.');
    }

    return expense;
  }

  /**
   * Update an existing expense
   */
  static async updateExpense(
    expenseId: string,
    userId: string,
    data: Partial<CreateExpenseDTO>
  ) {
    const existing = await prisma.expense.findUnique({
      where: { id: expenseId },
      include: { splits: true },
    });

    if (!existing || existing.isDeleted) {
      throw new Error('Expense not found.');
    }

    const updatedAmount = data.amount ?? existing.amount;
    const updatedMethod = (data.splitMethod ?? existing.splitMethod) as SplitMethodType;
    const updatedPayer = data.payerId ?? existing.payerId;
    const updatedSplitsInput = data.splits ?? existing.splits;

    const participantIds = [updatedPayer, ...updatedSplitsInput.map((s) => s.userId)];
    await this.validateGroupMembership(existing.groupId, Array.from(new Set(participantIds)));

    const computedSplits = this.computeSplits(updatedAmount, updatedMethod, updatedSplitsInput);

    const updatedExpense = await prisma.$transaction(async (tx) => {
      // Delete old splits
      await tx.expenseSplit.deleteMany({
        where: { expenseId },
      });

      // Update expense & create new splits
      const exp = await tx.expense.update({
        where: { id: expenseId },
        data: {
          payerId: updatedPayer,
          description: data.description !== undefined ? data.description.trim() : existing.description,
          amount: updatedAmount,
          splitMethod: updatedMethod as any,
          category: data.category !== undefined ? data.category : existing.category,
          date: data.date ? new Date(data.date) : existing.date,
          notes: data.notes !== undefined ? data.notes?.trim() || null : existing.notes,
          receiptUrl: data.receiptUrl !== undefined ? data.receiptUrl : existing.receiptUrl,
          splits: {
            create: computedSplits.map((s) => ({
              userId: s.userId,
              amount: s.amount,
              percentage: s.percentage !== undefined ? s.percentage : null,
              shares: s.shares !== undefined ? s.shares : null,
            })),
          },
        },
        include: {
          payer: { select: { id: true, name: true, email: true, avatarUrl: true } },
          createdBy: { select: { id: true, name: true, email: true } },
          splits: {
            include: {
              user: { select: { id: true, name: true, email: true, avatarUrl: true } },
            },
          },
        },
      });

      await tx.activity.create({
        data: {
          groupId: existing.groupId,
          userId,
          actionType: 'EXPENSE_UPDATED',
          details: `Updated "${exp.description}"`,
        },
      });

      return exp;
    });

    return updatedExpense;
  }

  /**
   * Delete expense
   */
  static async deleteExpense(expenseId: string, userId: string) {
    const existing = await prisma.expense.findUnique({
      where: { id: expenseId },
    });

    if (!existing || existing.isDeleted) {
      throw new Error('Expense not found.');
    }

    await prisma.$transaction(async (tx) => {
      await tx.expense.update({
        where: { id: expenseId },
        data: { isDeleted: true },
      });

      await tx.activity.create({
        data: {
          groupId: existing.groupId,
          userId,
          actionType: 'EXPENSE_DELETED',
          details: `Deleted "${existing.description}" (₹${existing.amount.toFixed(2)})`,
        },
      });
    });

    return { success: true };
  }
}
