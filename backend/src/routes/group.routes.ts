import { Router } from 'express';
import { GroupController } from '../controllers/group.controller';
import { ExpenseController } from '../controllers/expense.controller';
import { BalanceController } from '../controllers/balance.controller';
import { SettlementController } from '../controllers/settlement.controller';
import { ActivityController } from '../controllers/activity.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { requireGroupMembership, requireGroupOwner } from '../middleware/group-auth.middleware';

const router = Router();

router.use(authenticateToken as any);

// Group CRUD
router.post('/', GroupController.createGroup as any);
router.get('/', GroupController.getMyGroups as any);
router.post('/join', GroupController.joinByInviteCode as any);

router.get('/:id', requireGroupMembership as any, GroupController.getGroupById as any);
router.patch('/:id', requireGroupMembership as any, GroupController.updateGroup as any);
router.delete('/:id', requireGroupOwner as any, GroupController.deleteGroup as any);

// Group Members
router.post('/:id/members', requireGroupMembership as any, GroupController.addMember as any);
router.delete('/:id/members/:userId', requireGroupMembership as any, GroupController.removeMember as any);

// Group Expenses
router.post('/:groupId/expenses', requireGroupMembership as any, ExpenseController.createExpense as any);
router.get('/:groupId/expenses', requireGroupMembership as any, ExpenseController.getGroupExpenses as any);

// Group Balances & Debt Simplification
router.get('/:groupId/balances', requireGroupMembership as any, BalanceController.getGroupBalances as any);

// Group Settlements
router.post('/:groupId/settlements', requireGroupMembership as any, SettlementController.recordSettlement as any);
router.get('/:groupId/settlements', requireGroupMembership as any, SettlementController.getGroupSettlements as any);

// Group Activity Feed
router.get('/:groupId/activity', requireGroupMembership as any, ActivityController.getGroupActivity as any);

export default router;
