import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
import { ActivityService } from '../services/activity.service';
import { sendSuccess } from '../utils/api-response';

export class ActivityController {
  static async getGroupActivity(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const activities = await ActivityService.getGroupActivity(req.params.groupId);
      sendSuccess(res, activities);
    } catch (error) {
      next(error);
    }
  }

  static async getMyRecentActivity(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const activities = await ActivityService.getUserRecentActivity(req.user!.id);
      sendSuccess(res, activities);
    } catch (error) {
      next(error);
    }
  }
}
