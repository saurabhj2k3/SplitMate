import { Router } from 'express';
import { ExpenseController } from '../controllers/expense.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken as any);

router.get('/:id', ExpenseController.getExpenseById as any);
router.patch('/:id', ExpenseController.updateExpense as any);
router.delete('/:id', ExpenseController.deleteExpense as any);

export default router;
