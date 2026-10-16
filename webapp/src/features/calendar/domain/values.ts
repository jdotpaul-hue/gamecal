import { Temporal } from "@js-temporal/polyfill";
import { z } from "zod";

export const localDateSchema = z
  .string()
  .regex(/^(?!0000)\d{4}-\d{2}-\d{2}$/)
  .refine((value) => {
    try {
      return Temporal.PlainDate.from(value).toString() === value;
    } catch {
      return false;
    }
  }, "Expected a valid ISO calendar date")
  .brand<"LocalDate">();

export const wallTimeSchema = z
  .string()
  .regex(/^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d$/)
  .brand<"WallTime">();

export const timeZoneSchema = z
  .string()
  .refine((value) => {
    if (/^[+-]/.test(value)) return false;
    try {
      Temporal.ZonedDateTime.from({
        timeZone: value,
        year: 2000,
        month: 1,
        day: 1,
      });
      return true;
    } catch {
      return false;
    }
  }, "Expected a supported IANA timezone")
  .brand<"TimeZone">();

export const utcInstantSchema = z
  .string()
  .regex(
    /^(?!0000)\d{4}-\d{2}-\d{2}T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,9})?Z$/,
  )
  .refine((value) => {
    if (!value.endsWith("Z")) return false;
    try {
      Temporal.Instant.from(value);
      return true;
    } catch {
      return false;
    }
  }, "Expected an RFC 3339 UTC instant ending in Z")
  .brand<"UtcInstant">();

export type LocalDate = z.infer<typeof localDateSchema>;
export type WallTime = z.infer<typeof wallTimeSchema>;
export type TimeZone = z.infer<typeof timeZoneSchema>;
export type UtcInstant = z.infer<typeof utcInstantSchema>;
