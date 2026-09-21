import { Router } from 'express';
import { SettlementController } from '../controllers/settlement.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken as any);

router.patch('/:id/status', SettlementController.updateSettlementStatus as any);

export default router;
