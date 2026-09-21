import crypto from 'crypto';
import { prisma } from '../config/db';

export class GroupService {
  /**
   * Generates a clean, readable invite code (e.g., 'GOA123', 'SPL892')
   */
  private static generateInviteCode(): string {
    return crypto.randomBytes(4).toString('hex').toUpperCase().substring(0, 6);
  }

  /**
   * Create a new group with creator as OWNER
   */
  static async createGroup(
    userId: string,
    data: { name: string; description?: string; imageUrl?: string }
  ) {
    if (!data.name || data.name.trim().length === 0) {
      throw new Error('Group name is required.');
    }

    let inviteCode = this.generateInviteCode();
    // Ensure uniqueness
    let attempts = 0;
    while (attempts < 5) {
      const existing = await prisma.group.findUnique({ where: { inviteCode } });
      if (!existing) break;
      inviteCode = this.generateInviteCode();
      attempts++;
    }

    const group = await prisma.group.create({
      data: {
        name: data.name.trim(),
        description: data.description?.trim() || null,
        imageUrl: data.imageUrl || null,
        inviteCode,
        createdById: userId,
        members: {
          create: {
            userId,
            role: 'OWNER',
          },
        },
      },
      include: {
        members: {
          include: {
            user: {
              select: { id: true, name: true, email: true, avatarUrl: true, phone: true },
            },
          },
        },
      },
    });

    // Record activity
    await prisma.activity.create({
      data: {
        groupId: group.id,
        userId,
        actionType: 'GROUP_CREATED',
        details: `Created group "${group.name}"`,
      },
    });

    return group;
  }

  /**
   * Get all groups that the user is a member of
   */
  static async getUserGroups(userId: string) {
    const memberships = await prisma.groupMember.findMany({
      where: { userId },
      include: {
        group: {
          include: {
            members: {
              include: {
                user: {
                  select: { id: true, name: true, email: true, avatarUrl: true },
                },
              },
            },
            expenses: {
              where: { isDeleted: false },
              select: { id: true, amount: true },
            },
          },
        },
      },
      orderBy: {
        joinedAt: 'desc',
      },
    });

    return memberships.map((m) => {
      const g = m.group;
      const totalExpenses = g.expenses.reduce((sum, exp) => sum + exp.amount, 0);
      return {
        id: g.id,
        name: g.name,
        description: g.description,
        imageUrl: g.imageUrl,
        inviteCode: g.inviteCode,
        createdById: g.createdById,
        role: m.role,
        memberCount: g.members.length,
        totalExpensesAmount: Math.round(totalExpenses * 100) / 100,
        expenseCount: g.expenses.length,
        members: g.members.map((mem) => ({
          id: mem.id,
          userId: mem.user.id,
          name: mem.user.name,
          email: mem.user.email,
          avatarUrl: mem.user.avatarUrl,
          role: mem.role,
        })),
        createdAt: g.createdAt,
      };
    });
  }

  /**
   * Get group by ID
   */
  static async getGroupById(groupId: string, currentUserId?: string) {
    const group = await prisma.group.findUnique({
      where: { id: groupId },
      include: {
        members: {
          include: {
            user: {
              select: { id: true, name: true, email: true, phone: true, avatarUrl: true },
            },
          },
        },
        createdBy: {
          select: { id: true, name: true, email: true },
        },
      },
    });

    if (!group) {
      throw new Error('Group not found.');
    }

    const currentMember = currentUserId
      ? group.members.find((m) => m.userId === currentUserId)
      : undefined;
    const role = currentMember?.role || (group.createdById === currentUserId ? 'OWNER' : 'MEMBER');

    return {
      id: group.id,
      name: group.name,
      description: group.description,
      imageUrl: group.imageUrl,
      inviteCode: group.inviteCode,
      createdById: group.createdById,
      createdBy: group.createdBy,
      role,
      createdAt: group.createdAt,
      members: group.members.map((m) => ({
        id: m.id,
        userId: m.user.id,
        name: m.user.name,
        email: m.user.email,
        phone: m.user.phone,
        avatarUrl: m.user.avatarUrl,
        role: m.role,
        joinedAt: m.joinedAt,
      })),
    };
  }

  /**
   * Add a member to a group by email, phone, name, or userId (no pre-registration required)
   */
  static async addMember(groupId: string, addedByUserId: string, targetIdentifier: string) {
    const trimmed = targetIdentifier.trim();
    if (!trimmed) {
      throw new Error('Member name or email is required.');
    }

    // 1. Check if user already exists by email, id, phone, or exact name
    let user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: trimmed.toLowerCase() },
          { id: trimmed },
          { phone: trimmed },
          { name: { equals: trimmed, mode: 'insensitive' } },
        ],
      },
    });

    // 2. If not registered, automatically create a placeholder / guest member profile
    if (!user) {
      const isEmail = trimmed.includes('@');
      const name = isEmail ? trimmed.split('@')[0] : trimmed;
      const email = isEmail
        ? trimmed.toLowerCase()
        : `guest_${crypto.randomBytes(4).toString('hex')}@splitmate.local`;

      user = await prisma.user.create({
        data: {
          name,
          email,
          phone: !isEmail && /^\+?[0-9]{7,15}$/.test(trimmed) ? trimmed : null,
          passwordHash: 'GHOST_USER_' + crypto.randomBytes(16).toString('hex'),
        },
      });
    }

    const existingMember = await prisma.groupMember.findUnique({
      where: {
        groupId_userId: {
          groupId,
          userId: user.id,
        },
      },
    });

    if (existingMember) {
      throw new Error(`${user.name} is already a member of this group.`);
    }

    const member = await prisma.groupMember.create({
      data: {
        groupId,
        userId: user.id,
        role: 'MEMBER',
      },
      include: {
        user: {
          select: { id: true, name: true, email: true, phone: true, avatarUrl: true },
        },
      },
    });

    await prisma.activity.create({
      data: {
        groupId,
        userId: addedByUserId,
        actionType: 'MEMBER_ADDED',
        details: `Added ${user.name} to the group`,
      },
    });

    return member;
  }

  /**
   * Join a group using an invite code
   */
  static async joinByInviteCode(userId: string, inviteCode: string) {
    const group = await prisma.group.findUnique({
      where: { inviteCode: inviteCode.trim().toUpperCase() },
      include: { members: true },
    });

    if (!group) {
      throw new Error('Invalid invite code. Group does not exist.');
    }

    const isMember = group.members.some((m) => m.userId === userId);
    if (isMember) {
      return { group, alreadyMember: true };
    }

    await prisma.groupMember.create({
      data: {
        groupId: group.id,
        userId,
        role: 'MEMBER',
      },
    });

    const user = await prisma.user.findUnique({ where: { id: userId } });

    await prisma.activity.create({
      data: {
        groupId: group.id,
        userId,
        actionType: 'MEMBER_JOINED',
        details: `${user?.name || 'A new user'} joined via invite link`,
      },
    });

    return { group, alreadyMember: false };
  }

  /**
   * Remove member from group
   */
  static async removeMember(groupId: string, targetUserId: string, requestingUserId: string) {
    const member = await prisma.groupMember.findUnique({
      where: {
        groupId_userId: {
          groupId,
          userId: targetUserId,
        },
      },
    });

    if (!member) {
      throw new Error('Member not found in this group.');
    }

    if (member.role === 'OWNER') {
      throw new Error('The group owner cannot be removed. Transfer ownership or delete the group.');
    }

    await prisma.groupMember.delete({
      where: {
        groupId_userId: {
          groupId,
          userId: targetUserId,
        },
      },
    });

    await prisma.activity.create({
      data: {
        groupId,
        userId: requestingUserId,
        actionType: 'MEMBER_REMOVED',
        details: `Member was removed from the group`,
      },
    });

    return { success: true };
  }

  /**
   * Update group details
   */
  static async updateGroup(
    groupId: string,
    data: { name?: string; description?: string; imageUrl?: string }
  ) {
    const updated = await prisma.group.update({
      where: { id: groupId },
      data: {
        ...(data.name ? { name: data.name.trim() } : {}),
        ...(data.description !== undefined ? { description: data.description?.trim() || null } : {}),
        ...(data.imageUrl !== undefined ? { imageUrl: data.imageUrl } : {}),
      },
    });
    return updated;
  }

  /**
   * Delete group (Owner only)
   */
  static async deleteGroup(groupId: string) {
    await prisma.group.delete({
      where: { id: groupId },
    });
    return { success: true };
  }
}
