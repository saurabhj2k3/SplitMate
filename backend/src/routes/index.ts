import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import groupRoutes from './group.routes';
import expenseRoutes from './expense.routes';
import balanceRoutes from './balance.routes';
import settlementRoutes from './settlement.routes';
import activityRoutes from './activity.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/groups', groupRoutes);
router.use('/expenses', expenseRoutes);
router.use('/balances', balanceRoutes);
router.use('/settlements', settlementRoutes);
router.use('/activity', activityRoutes);

export default router;
