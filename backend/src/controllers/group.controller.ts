import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
import { GroupService } from '../services/group.service';
import { sendSuccess } from '../utils/api-response';

export class GroupController {
  static async createGroup(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { name, description, imageUrl } = req.body;
      const group = await GroupService.createGroup(req.user!.id, {
        name,
        description,
        imageUrl,
      });
      sendSuccess(res, group, 'Group created successfully.', 201);
    } catch (error) {
      next(error);
    }
  }

  static async getMyGroups(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const groups = await GroupService.getUserGroups(req.user!.id);
      sendSuccess(res, groups);
    } catch (error) {
      next(error);
    }
  }

  static async getGroupById(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const group = await GroupService.getGroupById(req.params.id as string, req.user?.id);
      sendSuccess(res, group);
    } catch (error) {
      next(error);
    }
  }

  static async updateGroup(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { name, description, imageUrl } = req.body;
      const group = await GroupService.updateGroup(req.params.id as string, {
        name,
        description,
        imageUrl,
      });
      sendSuccess(res, group, 'Group updated successfully.');
    } catch (error) {
      next(error);
    }
  }

  static async deleteGroup(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await GroupService.deleteGroup(req.params.id as string);
      sendSuccess(res, null, 'Group deleted successfully.');
    } catch (error) {
      next(error);
    }
  }

  static async addMember(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { identifier } = req.body; // email, userId, or phone
      const member = await GroupService.addMember(req.params.id as string, req.user!.id, identifier);
      sendSuccess(res, member, 'Member added successfully.', 201);
    } catch (error) {
      next(error);
    }
  }

  static async joinByInviteCode(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { inviteCode } = req.body;
      const result = await GroupService.joinByInviteCode(req.user!.id, inviteCode);
      sendSuccess(res, result, 'Joined group successfully.');
    } catch (error) {
      next(error);
    }
  }

  static async removeMember(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await GroupService.removeMember(req.params.id as string, req.params.userId as string, req.user!.id);
      sendSuccess(res, null, 'Member removed successfully.');
    } catch (error) {
      next(error);
    }
  }
}
