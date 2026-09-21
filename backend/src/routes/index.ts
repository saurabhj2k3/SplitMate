import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import groupRoutes from './group.routes';
import expenseRoutes from './expense.routes';
import balanceRoutes from './balance.routes';
import settlementRoutes from './settlement.routes';
import activityRoutes from './activity.routes';

const router = Router();

router.get('/', (req, res) => {
  res.status(200).json({
    status: 'online',
    message: 'SplitMate API v1 Base Route',
    endpoints: {
      auth: '/api/v1/auth',
      users: '/api/v1/users',
      groups: '/api/v1/groups',
      expenses: '/api/v1/expenses',
      balances: '/api/v1/balances',
      settlements: '/api/v1/settlements',
      activity: '/api/v1/activity',
    },
  });
});

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/groups', groupRoutes);
router.use('/expenses', expenseRoutes);
router.use('/balances', balanceRoutes);
router.use('/settlements', settlementRoutes);
router.use('/activity', activityRoutes);

export default router;
