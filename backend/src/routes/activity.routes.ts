import { Router } from 'express';
import { ActivityController } from '../controllers/activity.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken as any);

router.get('/recent', ActivityController.getMyRecentActivity as any);

export default router;
