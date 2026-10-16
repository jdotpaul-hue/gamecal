import { v5 } from "uuid";
import type { LocalDate } from "@/features/calendar";
import {
  occurrenceIdSchema,
  type DefinitionId,
  type OccurrenceId,
} from "@/lib/validation/ids";

const occurrenceNamespace = "bf67d23d-270f-5606-bdb9-a90a143ad12d";

export function deriveOccurrenceId(
  definitionId: DefinitionId,
  originalDate: LocalDate,
): OccurrenceId {
  return occurrenceIdSchema.parse(
    v5(`${definitionId}:${originalDate}`, occurrenceNamespace),
  );
}
