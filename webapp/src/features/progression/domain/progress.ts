import { z } from "zod";

const totalXpSchema = z
  .number()
  .int()
  .nonnegative()
  .max(Number.MAX_SAFE_INTEGER);

// Presentation only: accepted totals come from canonical rewards; this never awards XP.
export function progressFromAcceptedXp(acceptedXp: number) {
  const totalXp = totalXpSchema.parse(acceptedXp);
  const xpInLevel = totalXp % 100;
  return {
    totalXp,
    level: 1 + Math.floor(totalXp / 100),
    xpInLevel,
    xpToNextLevel: 100 - xpInLevel,
  };
}
