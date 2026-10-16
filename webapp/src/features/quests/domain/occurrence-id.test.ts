import { describe, expect, it } from "vitest";
import { localDateSchema } from "@/features/calendar";
import { definitionIdSchema } from "@/lib/validation/ids";
import { deriveOccurrenceId } from "./occurrence-id";

describe("permanent occurrence identities", () => {
  it.each([
    [
      "fda923dc-3ebd-489e-a655-37e04fef3163",
      "2026-10-14",
      "55a014c9-4d95-5e15-9d2b-aac1953f81b8",
    ],
    [
      "fda923dc-3ebd-489e-a655-37e04fef3163",
      "2026-10-15",
      "5c75f0b0-ae34-5364-8804-247171556ce0",
    ],
    [
      "84915f93-ef45-4617-a753-0b072ab89ccd",
      "2026-11-01",
      "0a8f3101-1700-521b-bffe-423311e7b732",
    ],
  ])(
    "matches the shared UUID vector for %s on %s",
    (definition, date, expected) => {
      expect(
        deriveOccurrenceId(
          definitionIdSchema.parse(definition),
          localDateSchema.parse(date),
        ),
      ).toBe(expected);
    },
  );
});
