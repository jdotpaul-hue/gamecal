import { z } from "zod";

const uuidSchema = z
  .uuid()
  .regex(/^[0-9a-f-]+$/, "Use a canonical lowercase UUID");

export const accountIdSchema = uuidSchema.brand<"AccountId">();
export const definitionIdSchema = uuidSchema.brand<"DefinitionId">();
export const occurrenceIdSchema = uuidSchema.brand<"OccurrenceId">();
export const operationIdSchema = uuidSchema.brand<"OperationId">();
export const syncEpochSchema = uuidSchema.brand<"SyncEpoch">();

export type AccountId = z.infer<typeof accountIdSchema>;
export type DefinitionId = z.infer<typeof definitionIdSchema>;
export type OccurrenceId = z.infer<typeof occurrenceIdSchema>;
export type OperationId = z.infer<typeof operationIdSchema>;
export type SyncEpoch = z.infer<typeof syncEpochSchema>;

export function createOperationId(): OperationId {
  return operationIdSchema.parse(crypto.randomUUID());
}
