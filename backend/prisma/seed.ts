import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding SplitMate sample data...');

  const passwordHash = await bcrypt.hash('password123', 10);

  // 1. Create Users
  const saurabh = await prisma.user.upsert({
    where: { email: 'saurabh@example.com' },
    update: {},
    create: {
      name: 'Saurabh Sharma',
      email: 'saurabh@example.com',
      passwordHash,
      phone: '+919876543210',
    },
  });

  const rahul = await prisma.user.upsert({
    where: { email: 'rahul@example.com' },
    update: {},
    create: {
      name: 'Rahul Verma',
      email: 'rahul@example.com',
      passwordHash,
      phone: '+919876543211',
    },
  });

  const amit = await prisma.user.upsert({
    where: { email: 'amit@example.com' },
    update: {},
    create: {
      name: 'Amit Patel',
      email: 'amit@example.com',
      passwordHash,
      phone: '+919876543212',
    },
  });

  const neha = await prisma.user.upsert({
    where: { email: 'neha@example.com' },
    update: {},
    create: {
      name: 'Neha Singh',
      email: 'neha@example.com',
      passwordHash,
      phone: '+919876543213',
    },
  });

  console.log('Users created:', [saurabh.name, rahul.name, amit.name, neha.name]);

  // 2. Create Group: Goa Trip
  const goaGroup = await prisma.group.upsert({
    where: { inviteCode: 'GOA2026' },
    update: {},
    create: {
      name: 'Goa Trip',
      description: 'Beach, food and road trip expenses',
      inviteCode: 'GOA2026',
      createdById: saurabh.id,
      members: {
        create: [
          { userId: saurabh.id, role: 'OWNER' },
          { userId: rahul.id, role: 'MEMBER' },
          { userId: amit.id, role: 'MEMBER' },
          { userId: neha.id, role: 'MEMBER' },
        ],
      },
    },
  });

  // 3. Add Goa Trip Expenses (from PRD Section 71)
  // Hotel ₹8,000 paid by Rahul
  await prisma.expense.create({
    data: {
      groupId: goaGroup.id,
      payerId: rahul.id,
      createdById: rahul.id,
      description: 'Hotel Stay (3 Nights)',
      amount: 8000,
      splitMethod: 'EQUAL',
      category: 'Hotel',
      date: new Date('2026-09-20T14:00:00Z'),
      splits: {
        create: [
          { userId: saurabh.id, amount: 2000 },
          { userId: rahul.id, amount: 2000 },
          { userId: amit.id, amount: 2000 },
          { userId: neha.id, amount: 2000 },
        ],
      },
    },
  });

  // Dinner ₹2,400 paid by Saurabh
  await prisma.expense.create({
    data: {
      groupId: goaGroup.id,
      payerId: saurabh.id,
      createdById: saurabh.id,
      description: 'Seafood Dinner at Calangute',
      amount: 2400,
      splitMethod: 'EQUAL',
      category: 'Food',
      date: new Date('2026-09-21T20:30:00Z'),
      splits: {
        create: [
          { userId: saurabh.id, amount: 600 },
          { userId: rahul.id, amount: 600 },
          { userId: amit.id, amount: 600 },
          { userId: neha.id, amount: 600 },
        ],
      },
    },
  });

  // Taxi ₹800 paid by Amit
  await prisma.expense.create({
    data: {
      groupId: goaGroup.id,
      payerId: amit.id,
      createdById: amit.id,
      description: 'Airport Taxi',
      amount: 800,
      splitMethod: 'EQUAL',
      category: 'Travel',
      date: new Date('2026-09-20T10:00:00Z'),
      splits: {
        create: [
          { userId: saurabh.id, amount: 200 },
          { userId: rahul.id, amount: 200 },
          { userId: amit.id, amount: 200 },
          { userId: neha.id, amount: 200 },
        ],
      },
    },
  });

  // Breakfast ₹1,200 paid by Neha
  await prisma.expense.create({
    data: {
      groupId: goaGroup.id,
      payerId: neha.id,
      createdById: neha.id,
      description: 'Beach Cafe Breakfast',
      amount: 1200,
      splitMethod: 'EQUAL',
      category: 'Food',
      date: new Date('2026-09-21T09:00:00Z'),
      splits: {
        create: [
          { userId: saurabh.id, amount: 300 },
          { userId: rahul.id, amount: 300 },
          { userId: amit.id, amount: 300 },
          { userId: neha.id, amount: 300 },
        ],
      },
    },
  });

  console.log('Sample group and expenses seeded successfully.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
