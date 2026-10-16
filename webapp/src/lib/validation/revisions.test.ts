import { describe, expect, it } from "vitest";
import { accountCounterSchema, revisionSchema } from "./revisions";

describe("database decimal counters", () => {
  it("preserves integers beyond JavaScript number precision", () => {
    expect(revisionSchema.parse("9007199254740993")).toBe("9007199254740993");
    expect(revisionSchema.parse("9223372036854775807")).toBe(
      "9223372036854775807",
    );
    expect(accountCounterSchema.parse("0")).toBe("0");
    expect(revisionSchema.safeParse("0").success).toBe(false);
  });

  it.each([
    "",
    "01",
    "+1",
    "-1",
    "1.0",
    " 1",
    "1e3",
    "9223372036854775808",
    "1".repeat(5000),
    4,
    null,
  ])("rejects an invalid wire counter: %j", (input) => {
    expect(accountCounterSchema.safeParse(input).success).toBe(false);
    expect(revisionSchema.safeParse(input).success).toBe(false);
  });
});
