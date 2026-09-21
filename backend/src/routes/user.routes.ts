import { Router } from 'express';
import { UserController } from '../controllers/user.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken as any);

router.get('/me', UserController.getMe as any);
router.patch('/me', UserController.updateMe as any);
router.get('/search', UserController.searchUsers as any);

export default router;
