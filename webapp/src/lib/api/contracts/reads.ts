import { z } from "zod";
import { operationIdSchema } from "@/lib/validation/ids";
import {
  contractVersionSchema,
  progressionRecordSchema,
  taggedRecordSchema,
} from "./common";

const localDateSchema = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

export const scopeReadDataSchema = z.strictObject({
  scope: z.strictObject({
    kind: z.string(),
  }),
  snapshot_token: z.string().nullable(),
  records: z.array(taggedRecordSchema),
  next_cursor: z.string().nullable(),
  page_set_complete: z.boolean(),
  coverage: z.record(z.string(), z.unknown()),
  summary: z.record(z.string(), z.unknown()).nullable(),
});

export const readSuccessResponseSchema = z.strictObject({
  ok: z.literal(true),
  contract_version: contractVersionSchema,
  data: scopeReadDataSchema,
});

export const profileReadDataSchema = scopeReadDataSchema.extend({
  bootstrap_needed: z.boolean(),
});

export const getProfileResponseSchema = z.strictObject({
  ok: z.literal(true),
  contract_version: contractVersionSchema,
  data: profileReadDataSchema,
});

export const getCalendarScopeRequestDataSchema = z.strictObject({
  from_date: localDateSchema,
  until_date: localDateSchema,
  display_timezone: z.string().min(1).max(64),
  page_size: z.number().int().min(1).max(100).optional(),
  snapshot_token: z.string().nullable().optional(),
  cursor: z.string().nullable().optional(),
});

export const getCalendarScopeResponseSchema = readSuccessResponseSchema.extend({
  data: scopeReadDataSchema.extend({
    scope: z.strictObject({
      kind: z.literal("calendar"),
      from_date: localDateSchema,
      until_date: localDateSchema,
      display_timezone: z.string(),
    }),
  }),
});

export const getProgressionResponseSchema = readSuccessResponseSchema.extend({
  data: scopeReadDataSchema.extend({
    scope: z.strictObject({ kind: z.literal("progression") }),
    summary: z.strictObject({
      as_of: z.string(),
      progression: progressionRecordSchema,
    }),
  }),
});

export const operationResultResponseSchema = z.strictObject({
  ok: z.literal(true),
  contract_version: contractVersionSchema,
  data: z.discriminatedUnion("status", [
    z.strictObject({ status: z.literal("not_seen") }),
    z.strictObject({
      status: z.literal("accepted"),
      acknowledgment: z.strictObject({
        operation_id: operationIdSchema,
        command_name: z.string(),
        accepted_at: z.string(),
        outcome: z.record(z.string(), z.unknown()),
        canonical_records: z.array(taggedRecordSchema).optional(),
      }),
    }),
  ]),
});

export type GetProfileResponse = z.infer<typeof getProfileResponseSchema>;
export type GetCalendarScopeResponse = z.infer<
  typeof getCalendarScopeResponseSchema
>;
export type GetProgressionResponse = z.infer<
  typeof getProgressionResponseSchema
>;
export type OperationResultResponse = z.infer<
  typeof operationResultResponseSchema
>;
