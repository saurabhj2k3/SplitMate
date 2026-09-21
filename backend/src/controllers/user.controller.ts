import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
import { AuthService } from '../services/auth.service';
import { sendSuccess } from '../utils/api-response';

export class UserController {
  static async getMe(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const user = await AuthService.getProfile(req.user!.id);
      sendSuccess(res, user);
    } catch (error) {
      next(error);
    }
  }

  static async updateMe(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { name, phone, avatarUrl, currency } = req.body;
      const user = await AuthService.updateProfile(req.user!.id, {
        name,
        phone,
        avatarUrl,
        currency,
      });
      sendSuccess(res, user, 'Profile updated successfully.');
    } catch (error) {
      next(error);
    }
  }

  static async searchUsers(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const query = (req.query.q as string) || '';
      const users = await AuthService.searchUsers(query, req.user!.id);
      sendSuccess(res, users);
    } catch (error) {
      next(error);
    }
  }
}
