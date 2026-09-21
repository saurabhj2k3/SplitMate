import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/auth.service';
import { sendSuccess } from '../utils/api-response';
import { AuthRequest } from '../middleware/auth.middleware';

export class AuthController {
  static async register(req: Request, res: Response, next: NextFunction) {
    try {
      const { name, email, password, phone, avatarUrl } = req.body;
      const result = await AuthService.register({ name, email, password, phone, avatarUrl });
      sendSuccess(res, result, 'Account created successfully.', 201);
    } catch (error) {
      next(error);
    }
  }

  static async login(req: Request, res: Response, next: NextFunction) {
    try {
      const { email, password } = req.body;
      const result = await AuthService.login({ email, password });
      sendSuccess(res, result, 'Login successful.');
    } catch (error) {
      next(error);
    }
  }

  static async getMe(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const user = await AuthService.getProfile(userId);
      sendSuccess(res, user);
    } catch (error) {
      next(error);
    }
  }

  static async logout(req: Request, res: Response) {
    sendSuccess(res, null, 'Logged out successfully.');
  }
}
