/**
 * Financial calculation & split allocation utilities.
 * Handles integer-cent arithmetic to guarantee zero loss or gain of money due to floating-point rounding.
 */

export interface SplitInput {
  userId: string;
  amount?: number;
  percentage?: number;
  shares?: number;
}

export interface SplitResult {
  userId: string;
  amount: number;
  percentage?: number;
  shares?: number;
}

export interface DebtItem {
  from: string;
  to: string;
  amount: number;
}

/**
 * Rounds a number to 2 decimal places safely.
 */
export function roundTo2Decimals(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

/**
 * Converts a floating amount to integer cents (or paise).
 */
export function toCents(amount: number): number {
  return Math.round((amount + Number.EPSILON) * 100);
}

/**
 * Converts integer cents (or paise) to standard 2-decimal currency amount.
 */
export function fromCents(cents: number): number {
  return cents / 100;
}

/**
 * Calculates equal splits for a total amount among participants.
 * Guarantees that the sum of splits EXACTLY equals totalAmount by distributing
 * remainder cents (paise) one-by-one to the first k participants.
 */
export function calculateEqualSplit(totalAmount: number, userIds: string[]): SplitResult[] {
  if (userIds.length === 0) {
    throw new Error('At least one participant is required to split an expense.');
  }
  if (totalAmount <= 0) {
    throw new Error('Expense amount must be greater than zero.');
  }

  const totalCents = toCents(totalAmount);
  const n = userIds.length;
  const baseCents = Math.floor(totalCents / n);
  const remainderCents = totalCents % n;

  return userIds.map((userId, index) => {
    // Distribute 1 extra cent to the first 'remainderCents' participants
    const shareCents = baseCents + (index < remainderCents ? 1 : 0);
    return {
      userId,
      amount: fromCents(shareCents),
    };
  });
}

/**
 * Validates and normalizes exact splits.
 * Checks that the sum of exact amounts equals totalAmount.
 */
export function validateAndCalculateExactSplit(
  totalAmount: number,
  splits: Array<{ userId: string; amount: number }>
): SplitResult[] {
  if (!splits || splits.length === 0) {
    throw new Error('Participants and exact amounts must be specified.');
  }
  if (totalAmount <= 0) {
    throw new Error('Expense amount must be greater than zero.');
  }

  let sumCents = 0;
  const results: SplitResult[] = [];

  for (const s of splits) {
    if (s.amount < 0) {
      throw new Error('Split amount cannot be negative.');
    }
    const cents = toCents(s.amount);
    sumCents += cents;
    results.push({
      userId: s.userId,
      amount: fromCents(cents),
    });
  }

  const expectedCents = toCents(totalAmount);
  if (sumCents !== expectedCents) {
    const diff = fromCents(Math.abs(expectedCents - sumCents));
    throw new Error(
      `Sum of exact splits (₹${fromCents(sumCents).toFixed(2)}) must equal total expense amount (₹${fromCents(expectedCents).toFixed(2)}). Difference: ₹${diff.toFixed(2)}`
    );
  }

  return results;
}

/**
 * Validates and calculates percentage splits.
 * Validates that total percentage is 100%.
 * Allocates remainder cents to the participant with the largest percentage.
 */
export function validateAndCalculatePercentageSplit(
  totalAmount: number,
  splits: Array<{ userId: string; percentage: number }>
): SplitResult[] {
  if (!splits || splits.length === 0) {
    throw new Error('Participants and percentages must be specified.');
  }
  if (totalAmount <= 0) {
    throw new Error('Expense amount must be greater than zero.');
  }

  // Validate percentage sum
  const totalPercentage = splits.reduce((acc, s) => acc + s.percentage, 0);
  const roundedPercentage = Math.round(totalPercentage * 100) / 100;
  if (Math.abs(roundedPercentage - 100) > 0.01) {
    throw new Error(`Total percentage must equal 100%. Current sum: ${roundedPercentage}%`);
  }

  const totalCents = toCents(totalAmount);
  let allocatedCents = 0;
  let maxIndex = 0;
  let maxPercentage = -1;

  const rawSplits = splits.map((s, index) => {
    if (s.percentage < 0) {
      throw new Error('Percentage cannot be negative.');
    }
    if (s.percentage > maxPercentage) {
      maxPercentage = s.percentage;
      maxIndex = index;
    }
    const cents = Math.floor((totalCents * s.percentage) / 100);
    allocatedCents += cents;
    return {
      userId: s.userId,
      cents,
      percentage: s.percentage,
    };
  });

  // Distribute any remainder cents to the highest percentage holder
  const remainderCents = totalCents - allocatedCents;
  rawSplits[maxIndex].cents += remainderCents;

  return rawSplits.map((s) => ({
    userId: s.userId,
    amount: fromCents(s.cents),
    percentage: s.percentage,
  }));
}

/**
 * Validates and calculates share-based splits.
 * Allocates remainder cents to the participant with the highest share.
 */
export function validateAndCalculateSharesSplit(
  totalAmount: number,
  splits: Array<{ userId: string; shares: number }>
): SplitResult[] {
  if (!splits || splits.length === 0) {
    throw new Error('Participants and shares must be specified.');
  }
  if (totalAmount <= 0) {
    throw new Error('Expense amount must be greater than zero.');
  }

  const totalShares = splits.reduce((acc, s) => acc + s.shares, 0);
  if (totalShares <= 0) {
    throw new Error('Total shares must be greater than zero.');
  }

  const totalCents = toCents(totalAmount);
  let allocatedCents = 0;
  let maxIndex = 0;
  let maxShares = -1;

  const rawSplits = splits.map((s, index) => {
    if (s.shares < 0) {
      throw new Error('Shares cannot be negative.');
    }
    if (s.shares > maxShares) {
      maxShares = s.shares;
      maxIndex = index;
    }
    const cents = Math.floor((totalCents * s.shares) / totalShares);
    allocatedCents += cents;
    return {
      userId: s.userId,
      cents,
      shares: s.shares,
    };
  });

  // Distribute any remainder cents to the highest share holder
  const remainderCents = totalCents - allocatedCents;
  rawSplits[maxIndex].cents += remainderCents;

  return rawSplits.map((s) => ({
    userId: s.userId,
    amount: fromCents(s.cents),
    shares: s.shares,
  }));
}

/**
 * Debt Simplification Algorithm.
 * Given a map of user net balances (positive = should receive money, negative = owes money),
 * calculates the minimum number of transactions needed to settle all debts.
 */
export function simplifyDebts(netBalances: Record<string, number>): DebtItem[] {
  // Convert to integer cents to eliminate floating-point comparison errors
  const creditors: Array<{ userId: string; cents: number }> = [];
  const debtors: Array<{ userId: string; cents: number }> = [];

  for (const [userId, balance] of Object.entries(netBalances)) {
    const cents = toCents(balance);
    if (cents > 0) {
      creditors.push({ userId, cents });
    } else if (cents < 0) {
      debtors.push({ userId, cents: -cents }); // store positive amount owed
    }
  }

  // Sort descending to match largest debtor with largest creditor (greedy optimal heuristic)
  creditors.sort((a, b) => b.cents - a.cents);
  debtors.sort((a, b) => b.cents - a.cents);

  const debts: DebtItem[] = [];

  let creditorIdx = 0;
  let debtorIdx = 0;

  while (creditorIdx < creditors.length && debtorIdx < debtors.length) {
    const creditor = creditors[creditorIdx];
    const debtor = debtors[debtorIdx];

    const settleCents = Math.min(creditor.cents, debtor.cents);

    if (settleCents > 0) {
      debts.push({
        from: debtor.userId,
        to: creditor.userId,
        amount: fromCents(settleCents),
      });

      creditor.cents -= settleCents;
      debtor.cents -= settleCents;
    }

    if (creditor.cents === 0) {
      creditorIdx++;
    }
    if (debtor.cents === 0) {
      debtorIdx++;
    }
  }

  return debts;
}
