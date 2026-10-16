import { describe, expect, it } from "vitest";
import { progressFromAcceptedXp } from "./progress";

describe("presentation of accepted XP", () => {
  it.each([
    [0, 1, 100],
    [20, 1, 80],
    [80, 1, 20],
    [100, 2, 100],
    [200, 3, 100],
  ])("maps %i accepted XP to level %i", (xp, level, remaining) => {
    expect(progressFromAcceptedXp(xp)).toMatchObject({
      totalXp: xp,
      level,
      xpToNextLevel: remaining,
    });
  });
  it.each([-1, 1.5, NaN, Infinity, Number.MAX_SAFE_INTEGER + 1])(
    "rejects invalid accepted totals: %s",
    (xp) => {
      expect(() => progressFromAcceptedXp(xp)).toThrow();
    },
  );
});
