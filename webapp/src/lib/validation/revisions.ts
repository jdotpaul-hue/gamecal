import { z } from "zod";

const decimalPattern = /^(0|[1-9][0-9]{0,18})$/;
const maxSignedBigint = 9_223_372_036_854_775_807n;

const counterValueSchema = z
  .string()
  .refine(
    (value) => decimalPattern.test(value) && BigInt(value) <= maxSignedBigint,
    "Expected an unsigned canonical decimal string within PostgreSQL bigint bounds",
  );

export const accountCounterSchema =
  counterValueSchema.brand<"AccountCounter">();
export const revisionSchema = counterValueSchema
  .refine((value) => value !== "0", "A record revision starts at one")
  .brand<"Revision">();

export type AccountCounter = z.infer<typeof accountCounterSchema>;
export type Revision = z.infer<typeof revisionSchema>;
