import { Temporal } from "@js-temporal/polyfill";
import type { Result } from "@/lib/result";
import {
  localDateSchema,
  utcInstantSchema,
  wallTimeSchema,
  type LocalDate,
  type TimeZone,
  type UtcInstant,
  type WallTime,
} from "./values";

type WallTimeInput = {
  readonly date: LocalDate;
  readonly time: WallTime;
  readonly zone: TimeZone;
} & (
  | { readonly kind: "routine" }
  | {
      readonly kind: "appointment";
      readonly ambiguity: "earlier" | "later" | null;
    }
);

type TimeFailure = {
  readonly code: "nonexistent_wall_time" | "ambiguous_wall_time";
};

export function resolveWallTime(
  input: WallTimeInput,
): Result<UtcInstant, TimeFailure> {
  const wall = Temporal.PlainDate.from(input.date).toPlainDateTime(input.time);
  const earlier = wall.toZonedDateTime(input.zone, {
    disambiguation: "earlier",
  });
  const later = wall.toZonedDateTime(input.zone, { disambiguation: "later" });
  if (earlier.epochNanoseconds === later.epochNanoseconds) {
    return {
      ok: true,
      value: utcInstantSchema.parse(earlier.toInstant().toString()),
    };
  }
  const isFold =
    earlier.toPlainDateTime().equals(wall) &&
    later.toPlainDateTime().equals(wall);
  if (input.kind === "appointment") {
    if (!isFold) return { ok: false, error: { code: "nonexistent_wall_time" } };
    if (input.ambiguity === null)
      return { ok: false, error: { code: "ambiguous_wall_time" } };
    const chosen = input.ambiguity === "earlier" ? earlier : later;
    return {
      ok: true,
      value: utcInstantSchema.parse(chosen.toInstant().toString()),
    };
  }
  // Routines choose the earlier fold; gaps shift forward by the actual offset change.
  const chosen = isFold ? earlier : later;
  return {
    ok: true,
    value: utcInstantSchema.parse(chosen.toInstant().toString()),
  };
}

export function addCalendarDays(date: LocalDate, days: number): LocalDate {
  if (!Number.isSafeInteger(days))
    throw new RangeError("Calendar days must be a safe integer");
  return localDateSchema.parse(
    Temporal.PlainDate.from(date).add({ days }).toString(),
  );
}

export function allDayDeadline(date: LocalDate, zone: TimeZone): UtcInstant {
  const nextDate = Temporal.PlainDate.from(addCalendarDays(date, 1));
  // Date-only conversion starts at the first valid instant, including midnight gaps.
  return utcInstantSchema.parse(
    nextDate.toZonedDateTime(zone).toInstant().toString(),
  );
}

export function localClockAt(instant: UtcInstant, zone: TimeZone) {
  const zoned = Temporal.Instant.from(instant).toZonedDateTimeISO(zone);
  return {
    date: localDateSchema.parse(zoned.toPlainDate().toString()),
    time: wallTimeSchema.parse(
      zoned.toPlainTime().toString({ smallestUnit: "second" }),
    ),
  };
}
