import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
import { BalanceService } from '../services/balance.service';
import { sendSuccess } from '../utils/api-response';

export class BalanceController {
  static async getGroupBalances(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const balances = await BalanceService.getGroupBalances(req.params.groupId);
      sendSuccess(res, balances);
    } catch (error) {
      next(error);
    }
  }

  static async getDashboardSummary(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const summary = await BalanceService.getUserDashboardSummary(req.user!.id);
      sendSuccess(res, summary);
    } catch (error) {
      next(error);
    }
  }
}
