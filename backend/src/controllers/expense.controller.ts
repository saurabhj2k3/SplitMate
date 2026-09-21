import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
import { ExpenseService } from '../services/expense.service';
import { sendSuccess } from '../utils/api-response';

export class ExpenseController {
  static async createExpense(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const {
        payerId,
        description,
        amount,
        splitMethod,
        category,
        date,
        notes,
        receiptUrl,
        splits,
      } = req.body;

      const expense = await ExpenseService.createExpense(req.user!.id, {
        groupId: req.params.groupId || req.body.groupId,
        payerId: payerId || req.user!.id,
        description,
        amount: Number(amount),
        splitMethod: splitMethod || 'EQUAL',
        category,
        date,
        notes,
        receiptUrl,
        splits: splits || [],
      });

      sendSuccess(res, expense, 'Expense recorded successfully.', 201);
    } catch (error) {
      next(error);
    }
  }

  static async getGroupExpenses(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const expenses = await ExpenseService.getGroupExpenses(req.params.groupId);
      sendSuccess(res, expenses);
    } catch (error) {
      next(error);
    }
  }

  static async getExpenseById(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const expense = await ExpenseService.getExpenseById(req.params.id);
      sendSuccess(res, expense);
    } catch (error) {
      next(error);
    }
  }

  static async updateExpense(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const {
        payerId,
        description,
        amount,
        splitMethod,
        category,
        date,
        notes,
        receiptUrl,
        splits,
      } = req.body;

      const expense = await ExpenseService.updateExpense(req.params.id, req.user!.id, {
        payerId,
        description,
        amount: amount !== undefined ? Number(amount) : undefined,
        splitMethod,
        category,
        date,
        notes,
        receiptUrl,
        splits,
      });

      sendSuccess(res, expense, 'Expense updated successfully.');
    } catch (error) {
      next(error);
    }
  }

  static async deleteExpense(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await ExpenseService.deleteExpense(req.params.id, req.user!.id);
      sendSuccess(res, null, 'Expense deleted successfully.');
    } catch (error) {
      next(error);
    }
  }
}
