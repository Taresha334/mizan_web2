// filepath: supabase/functions/_shared/pricing-engine.ts

export const calculateProRata = (
  amountPaid: number,
  requiredAmount: number,
  unitPrice: number,
  requestedDuration: number
) => {
  if (amountPaid < requiredAmount) {
    return {
      isValid: false,
      totalDuration: 0,
      bonusDuration: 0,
    };
  }

  const surplus = Math.max(0, amountPaid - requiredAmount);
  const bonus = Math.floor(surplus / unitPrice);

  return {
    isValid: true,
    totalDuration: requestedDuration + bonus,
    bonusDuration: bonus,
  };
};