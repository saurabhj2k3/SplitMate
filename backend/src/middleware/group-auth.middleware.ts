import { Response, NextFunction } from 'express';
import { AuthRequest } from './auth.middleware';
import { prisma } from '../config/db';
import { sendError } from '../utils/api-response';

export interface GroupAuthRequest extends AuthRequest {
  groupMember?: {
    id: string;
    groupId: string;
    userId: string;
    role: 'OWNER' | 'MEMBER';
  };
}

export async function requireGroupMembership(
  req: GroupAuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const userId = req.user?.id;
  const groupId = (req.params.groupId || req.params.id || req.body.groupId) as string | undefined;

  if (!userId) {
    sendError(res, 'Authentication required.', 401);
    return;
  }

  if (!groupId) {
    sendError(res, 'Group ID is required.', 400);
    return;
  }

  try {
    const membership = await prisma.groupMember.findUnique({
      where: {
        groupId_userId: {
          groupId,
          userId,
        },
      },
    });

    if (!membership) {
      sendError(res, 'You are not a member of this group.', 403);
      return;
    }

    req.groupMember = membership as any;
    next();
  } catch (error) {
    sendError(res, 'Unable to verify group membership.', 500);
  }
}

export async function requireGroupOwner(
  req: GroupAuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const userId = req.user?.id;
  const groupId = (req.params.groupId || req.params.id || req.body.groupId) as string | undefined;

  if (!userId) {
    sendError(res, 'Authentication required.', 401);
    return;
  }

  if (!groupId) {
    sendError(res, 'Group ID is required.', 400);
    return;
  }

  try {
    const membership = await prisma.groupMember.findUnique({
      where: {
        groupId_userId: {
          groupId,
          userId,
        },
      },
    });

    if (!membership) {
      sendError(res, 'You are not a member of this group.', 403);
      return;
    }

    if (membership.role !== 'OWNER') {
      sendError(res, 'Only the group owner can delete this group.', 403);
      return;
    }

    req.groupMember = membership as any;
    next();
  } catch (error) {
    sendError(res, 'Unable to verify group ownership.', 500);
  }
}
