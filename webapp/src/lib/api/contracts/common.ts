import { z } from "zod";
import { operationIdSchema } from "@/lib/validation/ids";
import { revisionSchema } from "@/lib/validation/revisions";

export const contractVersionSchema = z.literal(1);

export const readRequestEnvelopeSchema = z.strictObject({
  contract_version: contractVersionSchema,
  data: z.record(z.string(), z.unknown()),
});

export const taggedRecordSchema = z.strictObject({
  entity: z.string(),
  record: z.record(z.string(), z.unknown()),
});

export const progressionRecordSchema = z.strictObject({
  entity: z.literal("progression"),
  record: z.strictObject({
    total_xp: revisionSchema,
    level: revisionSchema,
  }),
});

export const invalidationSchema = z.strictObject({
  scope: z.string(),
});

export const commandAcknowledgmentSchema = z.strictObject({
  operation_id: operationIdSchema,
  command_name: z.string(),
  replayed: z.boolean(),
  accepted_at: z.string(),
  outcome: z.record(z.string(), z.unknown()),
});
