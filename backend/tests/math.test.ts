import {
  calculateEqualSplit,
  validateAndCalculateExactSplit,
  validateAndCalculatePercentageSplit,
  validateAndCalculateSharesSplit,
  calculateDirectDebts,
  simplifyDebts,
  toCents,
  fromCents,
} from '../src/utils/math';

describe('SplitMate Financial Math & Debt Engine', () => {
  describe('Cents & Rounding Precision', () => {
    it('accurately converts currency to integer cents and back', () => {
      expect(toCents(12.34)).toBe(1234);
      expect(fromCents(1234)).toBe(12.34);
      expect(toCents(0.01)).toBe(1);
      expect(fromCents(1)).toBe(0.01);
    });
  });

  describe('Equal Split Algorithm', () => {
    it('splits ₹5,000 equally among 4 participants (PRD Example 1)', () => {
      const users = ['Saurabh', 'Rahul', 'Amit', 'Neha'];
      const result = calculateEqualSplit(5000, users);

      expect(result).toHaveLength(4);
      expect(result.map((r) => r.amount)).toEqual([1250, 1250, 1250, 1250]);

      const sum = result.reduce((acc, r) => acc + r.amount, 0);
      expect(sum).toBe(5000);
    });

    it('splits ₹100 among 3 participants with ZERO CENT LOSS (₹33.34, ₹33.33, ₹33.33)', () => {
      const users = ['User1', 'User2', 'User3'];
      const result = calculateEqualSplit(100, users);

      expect(result).toHaveLength(3);
      expect(result[0].amount).toBe(33.34);
      expect(result[1].amount).toBe(33.33);
      expect(result[2].amount).toBe(33.33);

      const sum = result.reduce((acc, r) => acc + r.amount, 0);
      expect(sum).toBe(100.0);
    });

    it('splits ₹10 among 6 participants with zero cent loss', () => {
      const users = ['U1', 'U2', 'U3', 'U4', 'U5', 'U6'];
      const result = calculateEqualSplit(10, users);

      const sum = result.reduce((acc, r) => acc + r.amount, 0);
      expect(sum).toBe(10.0);
      // 1000 cents / 6 = 166 cents remainder 4 -> four 1.67 and two 1.66
      expect(result.filter((r) => r.amount === 1.67)).toHaveLength(4);
      expect(result.filter((r) => r.amount === 1.66)).toHaveLength(2);
    });

    it('throws error if participants list is empty or amount <= 0', () => {
      expect(() => calculateEqualSplit(100, [])).toThrow();
      expect(() => calculateEqualSplit(0, ['U1'])).toThrow();
      expect(() => calculateEqualSplit(-50, ['U1'])).toThrow();
    });
  });

  describe('Exact Split Algorithm', () => {
    it('accepts exact splits that match total amount (PRD Example Section 18)', () => {
      const splits = [
        { userId: 'Saurabh', amount: 800 },
        { userId: 'Rahul', amount: 500 },
        { userId: 'Amit', amount: 400 },
        { userId: 'Neha', amount: 300 },
      ];
      const result = validateAndCalculateExactSplit(2000, splits);
      expect(result).toHaveLength(4);
      expect(result.reduce((acc, r) => acc + r.amount, 0)).toBe(2000);
    });

    it('throws error if exact splits do not match total amount', () => {
      const splits = [
        { userId: 'Saurabh', amount: 800 },
        { userId: 'Rahul', amount: 500 },
        { userId: 'Amit', amount: 400 },
        { userId: 'Neha', amount: 200 }, // sum 1900 instead of 2000
      ];
      expect(() => validateAndCalculateExactSplit(2000, splits)).toThrow(
        /Sum of exact splits/
      );
    });
  });

  describe('Percentage Split Algorithm', () => {
    it('splits ₹2,000 by 40%, 30%, 20%, 10% (PRD Example Section 19)', () => {
      const splits = [
        { userId: 'Saurabh', percentage: 40 },
        { userId: 'Rahul', percentage: 30 },
        { userId: 'Amit', percentage: 20 },
        { userId: 'Neha', percentage: 10 },
      ];
      const result = validateAndCalculatePercentageSplit(2000, splits);
      expect(result.map((r) => r.amount)).toEqual([800, 600, 400, 200]);
      expect(result.reduce((acc, r) => acc + r.amount, 0)).toBe(2000);
    });

    it('handles fractional cents in percentage splits with zero loss', () => {
      const splits = [
        { userId: 'U1', percentage: 33.33 },
        { userId: 'U2', percentage: 33.33 },
        { userId: 'U3', percentage: 33.34 },
      ];
      const result = validateAndCalculatePercentageSplit(100, splits);
      const sum = result.reduce((acc, r) => acc + r.amount, 0);
      expect(sum).toBe(100);
    });

    it('throws error if percentage sum != 100%', () => {
      const splits = [
        { userId: 'U1', percentage: 50 },
        { userId: 'U2', percentage: 40 },
      ];
      expect(() => validateAndCalculatePercentageSplit(100, splits)).toThrow(
        /Total percentage must equal 100%/
      );
    });
  });

  describe('Share-Based Split Algorithm', () => {
    it('splits ₹2,000 by 2:1:1 shares (PRD Example Section 20)', () => {
      const splits = [
        { userId: 'Saurabh', shares: 2 },
        { userId: 'Rahul', shares: 1 },
        { userId: 'Amit', shares: 1 },
      ];
      const result = validateAndCalculateSharesSplit(2000, splits);
      expect(result.map((r) => r.amount)).toEqual([1000, 500, 500]);
      expect(result.reduce((acc, r) => acc + r.amount, 0)).toBe(2000);
    });

    it('splits ₹100 by 1:1:1 shares with zero cent loss', () => {
      const splits = [
        { userId: 'U1', shares: 1 },
        { userId: 'U2', shares: 1 },
        { userId: 'U3', shares: 1 },
      ];
      const result = validateAndCalculateSharesSplit(100, splits);
      const sum = result.reduce((acc, r) => acc + r.amount, 0);
      expect(sum).toBe(100);
    });
  });

  describe('Debt Simplification Engine ("Who Owes Whom")', () => {
    it('simplifies net balances (PRD Section 29)', () => {
      const netBalances = {
        Saurabh: 1000,
        Rahul: -600,
        Amit: -400,
      };
      const settlements = simplifyDebts(netBalances);

      expect(settlements).toHaveLength(2);
      expect(settlements).toContainEqual({
        from: 'Rahul',
        to: 'Saurabh',
        amount: 600,
      });
      expect(settlements).toContainEqual({
        from: 'Amit',
        to: 'Saurabh',
        amount: 400,
      });
    });

    it('simplifies Goa Trip full scenario (PRD Section 1 & 71)', () => {
      // Total ₹5000, ₹1250 each
      // Saurabh paid 3000 -> net +1750
      // Rahul paid 1000 -> net -250
      // Amit paid 500 -> net -750
      // Neha paid 500 -> net -750
      const netBalances = {
        Saurabh: 1750,
        Rahul: -250,
        Amit: -750,
        Neha: -750,
      };

      const settlements = simplifyDebts(netBalances);

      // Total money transferred should exactly equal Saurabh's +1750
      const totalTransferred = settlements.reduce((sum, s) => sum + s.amount, 0);
      expect(totalTransferred).toBe(1750);

      // All settlements must go to Saurabh
      for (const s of settlements) {
        expect(s.to).toBe('Saurabh');
      }

      // Amit, Neha and Rahul are settled
      expect(settlements.find((s) => s.from === 'Amit')?.amount).toBe(750);
      expect(settlements.find((s) => s.from === 'Neha')?.amount).toBe(750);
      expect(settlements.find((s) => s.from === 'Rahul')?.amount).toBe(250);
    });

    it('simplifies Ganpati Darshan 6-member scenario with exact precision', () => {
      // Dinner: ₹700 by Sakshi (Sakshi, Om, sneha, saurabh, vedika) -> 140 each
      // tea: ₹60 by vaibhav (Sakshi, Om, sneha, saurabh, vedika, vaibhav) -> 10 each
      // Soda: ₹60 by Om (Sakshi, Om, sneha, saurabh, vedika) -> 12 each
      // Net:
      // Sakshi: 700 - 162 = +538
      // vaibhav: 60 - 10 = +50
      // sneha: 0 - 162 = -162
      // saurabh: 0 - 162 = -162
      // vedika: 0 - 162 = -162
      // Om: 60 - 162 = -102
      const netBalances = {
        Sakshi: 538,
        vaibhav: 50,
        sneha: -162,
        saurabh: -162,
        vedika: -162,
        Om: -102,
      };

      const settlements = simplifyDebts(netBalances);

      const totalTransferred = settlements.reduce((sum, s) => sum + s.amount, 0);
      expect(totalTransferred).toBe(588);

      // sneha, saurabh, vedika pay Sakshi 162 each (total 486)
      expect(settlements.find((s) => s.from === 'sneha' && s.to === 'Sakshi')?.amount).toBe(162);
      expect(settlements.find((s) => s.from === 'saurabh' && s.to === 'Sakshi')?.amount).toBe(162);
      expect(settlements.find((s) => s.from === 'vedika' && s.to === 'Sakshi')?.amount).toBe(162);

      // Om pays remaining Sakshi balance (538 - 486 = 52)
      expect(settlements.find((s) => s.from === 'Om' && s.to === 'Sakshi')?.amount).toBe(52);

      // Om pays vaibhav (50)
      expect(settlements.find((s) => s.from === 'Om' && s.to === 'vaibhav')?.amount).toBe(50);
    });

    it('returns empty array if all balances are zero', () => {
      const netBalances = {
        User1: 0,
        User2: 0,
      };
      expect(simplifyDebts(netBalances)).toEqual([]);
    });
  });

  describe('Direct Pairwise Debt Engine (Option B: Itemized Payer-to-Participant)', () => {
    it('calculates direct itemized debts between participants accurately', () => {
      // Expense 1: ₹1,000 paid by vaibhav, split 4 ways (₹250 each)
      // Expense 2: ₹600 paid by saurabh, split 4 ways (₹150 each)
      const expenses = [
        {
          payerId: 'vaibhav',
          splits: [
            { userId: 'vaibhav', amount: 250 },
            { userId: 'saurabh', amount: 250 },
            { userId: 'vipin', amount: 250 },
            { userId: 'ajay', amount: 250 },
          ],
        },
        {
          payerId: 'saurabh',
          splits: [
            { userId: 'vaibhav', amount: 150 },
            { userId: 'saurabh', amount: 150 },
            { userId: 'vipin', amount: 150 },
            { userId: 'ajay', amount: 150 },
          ],
        },
      ];

      const debts = calculateDirectDebts(expenses);

      // vipin owes vaibhav 250, owes saurabh 150
      expect(debts.find((d) => d.from === 'vipin' && d.to === 'vaibhav')?.amount).toBe(250);
      expect(debts.find((d) => d.from === 'vipin' && d.to === 'saurabh')?.amount).toBe(150);

      // ajay owes vaibhav 250, owes saurabh 150
      expect(debts.find((d) => d.from === 'ajay' && d.to === 'vaibhav')?.amount).toBe(250);
      expect(debts.find((d) => d.from === 'ajay' && d.to === 'saurabh')?.amount).toBe(150);

      // saurabh owes vaibhav 250, but vaibhav owes saurabh 150 -> net saurabh owes vaibhav 100
      expect(debts.find((d) => d.from === 'saurabh' && d.to === 'vaibhav')?.amount).toBe(100);

      // Total money to be settled
      const total = debts.reduce((sum, d) => sum + d.amount, 0);
      expect(total).toBe(900);
    });

    it('settlements reduce direct pairwise debts correctly', () => {
      const expenses = [
        {
          payerId: 'vaibhav',
          splits: [
            { userId: 'vaibhav', amount: 250 },
            { userId: 'vipin', amount: 250 },
          ],
        },
      ];
      const settlements = [
        {
          payerId: 'vipin',
          receiverId: 'vaibhav',
          amount: 100,
        },
      ];

      const debts = calculateDirectDebts(expenses, settlements);
      expect(debts).toHaveLength(1);
      expect(debts[0]).toEqual({
        from: 'vipin',
        to: 'vaibhav',
        amount: 150,
      });
    });
  });
});
