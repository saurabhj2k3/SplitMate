import { prisma } from '../config/db';

export class ActivityService {
  /**
   * Get activity feed for a specific group
   */
  static async getGroupActivity(groupId: string, limit: number = 50) {
    const activities = await prisma.activity.findMany({
      where: { groupId },
      include: {
        user: { select: { id: true, name: true, email: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    return activities;
  }

  /**
   * Get recent activity across all groups for a user
   */
  static async getUserRecentActivity(userId: string, limit: number = 30) {
    const userGroups = await prisma.groupMember.findMany({
      where: { userId },
      select: { groupId: true },
    });

    const groupIds = userGroups.map((ug) => ug.groupId);

    const activities = await prisma.activity.findMany({
      where: {
        groupId: { in: groupIds },
      },
      include: {
        user: { select: { id: true, name: true, email: true, avatarUrl: true } },
        group: { select: { id: true, name: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    return activities;
  }
}
