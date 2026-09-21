import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
import { SettlementService } from '../services/settlement.service';
import { sendSuccess } from '../utils/api-response';

export class SettlementController {
  static async recordSettlement(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { groupId, payerId, receiverId, amount, notes, date } = req.body;
      const targetGroupId = req.params.groupId || groupId;

      const settlement = await SettlementService.recordSettlement(req.user!.id, {
        groupId: targetGroupId,
        payerId: payerId || req.user!.id,
        receiverId,
        amount: Number(amount),
        notes,
        date,
      });

      sendSuccess(res, settlement, 'Settlement recorded successfully.', 201);
    } catch (error) {
      next(error);
    }
  }

  static async getGroupSettlements(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const settlements = await SettlementService.getGroupSettlements(req.params.groupId);
      sendSuccess(res, settlements);
    } catch (error) {
      next(error);
    }
  }

  static async updateSettlementStatus(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { status } = req.body;
      const settlement = await SettlementService.updateSettlementStatus(
        req.params.id,
        req.user!.id,
        status
      );
      sendSuccess(res, settlement, 'Settlement status updated successfully.');
    } catch (error) {
      next(error);
    }
  }
}
