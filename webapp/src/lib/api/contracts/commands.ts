import { z } from "zod";
import { syncEpochSchema } from "@/lib/validation/ids";
import { revisionSchema } from "@/lib/validation/revisions";
import {
  commandAcknowledgmentSchema,
  contractVersionSchema,
  invalidationSchema,
  progressionRecordSchema,
  taggedRecordSchema,
} from "./common";

export const commandSuccessResponseSchema = z.strictObject({
  ok: z.literal(true),
  contract_version: contractVersionSchema,
  acknowledgment: commandAcknowledgmentSchema,
  canonical: z.strictObject({
    sync_epoch: syncEpochSchema,
    account_data_revision: revisionSchema,
    records: z.array(taggedRecordSchema),
    progression: progressionRecordSchema.optional(),
  }),
  invalidations: z.array(invalidationSchema),
});

export type CommandSuccessResponse = z.infer<
  typeof commandSuccessResponseSchema
>;
