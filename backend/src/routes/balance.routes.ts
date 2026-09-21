import { Router } from 'express';
import { BalanceController } from '../controllers/balance.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken as any);

router.get('/dashboard', BalanceController.getDashboardSummary as any);

export default router;
