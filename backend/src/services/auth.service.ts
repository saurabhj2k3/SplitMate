import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../config/db';
import { config } from '../config/env';

export class AuthService {
  /**
   * Register a new user
   */
  static async register(data: {
    name: string;
    email: string;
    password: string;
    phone?: string;
    avatarUrl?: string;
  }) {
    const existing = await prisma.user.findUnique({
      where: { email: data.email.toLowerCase().trim() },
    });

    let user;
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(data.password, salt);

    if (existing) {
      if (existing.passwordHash && existing.passwordHash.startsWith('GHOST_USER_')) {
        // Claim existing placeholder/guest member profile
        user = await prisma.user.update({
          where: { id: existing.id },
          data: {
            name: data.name.trim(),
            passwordHash,
            phone: data.phone?.trim() || existing.phone,
            avatarUrl: data.avatarUrl || existing.avatarUrl,
          },
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            avatarUrl: true,
            currency: true,
            createdAt: true,
          },
        });
      } else {
        throw new Error('An account with this email already exists.');
      }
    } else {
      user = await prisma.user.create({
        data: {
          name: data.name.trim(),
          email: data.email.toLowerCase().trim(),
          passwordHash,
          phone: data.phone?.trim() || null,
          avatarUrl: data.avatarUrl || null,
        },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          avatarUrl: true,
          currency: true,
          createdAt: true,
        },
      });
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      config.jwtSecret,
      { expiresIn: config.jwtExpiresIn as any }
    );

    return { user, token };
  }

  /**
   * Login user
   */
  static async login(data: { email: string; password: string }) {
    const user = await prisma.user.findUnique({
      where: { email: data.email.toLowerCase().trim() },
    });

    if (!user) {
      throw new Error('Invalid email or password.');
    }

    const isMatch = await bcrypt.compare(data.password, user.passwordHash);
    if (!isMatch) {
      throw new Error('Invalid email or password.');
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      config.jwtSecret,
      { expiresIn: config.jwtExpiresIn as any }
    );

    const safeUser = {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      currency: user.currency,
      createdAt: user.createdAt,
    };

    return { user: safeUser, token };
  }

  /**
   * Get user profile by ID
   */
  static async getProfile(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        avatarUrl: true,
        currency: true,
        createdAt: true,
      },
    });

    if (!user) {
      throw new Error('User not found.');
    }

    return user;
  }

  /**
   * Update user profile
   */
  static async updateProfile(
    userId: string,
    data: { name?: string; phone?: string; avatarUrl?: string; currency?: string }
  ) {
    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(data.name ? { name: data.name.trim() } : {}),
        ...(data.phone !== undefined ? { phone: data.phone?.trim() || null } : {}),
        ...(data.avatarUrl !== undefined ? { avatarUrl: data.avatarUrl } : {}),
        ...(data.currency ? { currency: data.currency } : {}),
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        avatarUrl: true,
        currency: true,
        createdAt: true,
      },
    });

    return user;
  }

  /**
   * Search users by query (email, phone, or name)
   */
  static async searchUsers(query: string, currentUserId: string) {
    const trimmed = query.trim().toLowerCase();
    if (!trimmed) return [];

    const users = await prisma.user.findMany({
      where: {
        AND: [
          { id: { not: currentUserId } },
          {
            OR: [
              { email: { contains: trimmed } },
              { name: { contains: trimmed } },
              { phone: { contains: trimmed } },
            ],
          },
        ],
      },
      take: 10,
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        avatarUrl: true,
      },
    });

    return users;
  }
}
