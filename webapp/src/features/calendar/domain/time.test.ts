import { describe, expect, it } from "vitest";
import {
  addCalendarDays,
  allDayDeadline,
  localClockAt,
  resolveWallTime,
} from "./time";
import {
  localDateSchema,
  timeZoneSchema,
  utcInstantSchema,
  wallTimeSchema,
} from "./values";

const newYork = timeZoneSchema.parse("America/New_York");

describe("explicit calendar time policy", () => {
  it("requires a fold choice for a booked appointment", () => {
    const input = {
      date: localDateSchema.parse("2026-11-01"),
      time: wallTimeSchema.parse("01:30:00"),
      zone: newYork,
      kind: "appointment",
    } as const;
    expect(resolveWallTime({ ...input, ambiguity: null })).toEqual({
      ok: false,
      error: { code: "ambiguous_wall_time" },
    });
    expect(resolveWallTime({ ...input, ambiguity: "earlier" })).toEqual({
      ok: true,
      value: "2026-11-01T05:30:00Z",
    });
    expect(resolveWallTime({ ...input, ambiguity: "later" })).toEqual({
      ok: true,
      value: "2026-11-01T06:30:00Z",
    });
  });

  it("rejects booked gaps and shifts routines by the actual gap", () => {
    const input = {
      date: localDateSchema.parse("2026-03-08"),
      time: wallTimeSchema.parse("02:30:00"),
      zone: newYork,
    };
    expect(
      resolveWallTime({ ...input, kind: "appointment", ambiguity: null }),
    ).toEqual({ ok: false, error: { code: "nonexistent_wall_time" } });
    expect(resolveWallTime({ ...input, kind: "routine" })).toEqual({
      ok: true,
      value: "2026-03-08T07:30:00Z",
    });
    expect(
      resolveWallTime({
        date: localDateSchema.parse("2026-10-04"),
        time: wallTimeSchema.parse("02:15:00"),
        zone: timeZoneSchema.parse("Australia/Lord_Howe"),
        kind: "routine",
      }),
    ).toEqual({ ok: true, value: "2026-10-03T15:45:00Z" });
  });

  it("uses the earlier routine fold", () => {
    expect(
      resolveWallTime({
        date: localDateSchema.parse("2026-11-01"),
        time: wallTimeSchema.parse("01:30:00"),
        zone: newYork,
        kind: "routine",
      }),
    ).toEqual({ ok: true, value: "2026-11-01T05:30:00Z" });
  });

  it.each([
    ["2026-03-08", "2026-03-09T04:00:00Z"],
    ["2026-11-01", "2026-11-02T05:00:00Z"],
  ])(
    "resolves all-day due boundaries without assuming 24 hours",
    (date, expected) => {
      expect(allDayDeadline(localDateSchema.parse(date), newYork)).toBe(
        expected,
      );
    },
  );

  it("handles non-existent midnight at the first valid instant", () => {
    expect(
      allDayDeadline(
        localDateSchema.parse("2018-11-03"),
        timeZoneSchema.parse("America/Sao_Paulo"),
      ),
    ).toBe("2018-11-04T03:00:00Z");
  });

  it("adds calendar days and applies explicit day boundaries", () => {
    expect(addCalendarDays(localDateSchema.parse("2028-02-28"), 1)).toBe(
      "2028-02-29",
    );
    expect(addCalendarDays(localDateSchema.parse("2026-01-01"), -1)).toBe(
      "2025-12-31",
    );
    expect(() =>
      addCalendarDays(localDateSchema.parse("2026-01-01"), 0.5),
    ).toThrow(RangeError);
    expect(
      localClockAt(
        utcInstantSchema.parse("2026-10-14T17:00:00Z"),
        timeZoneSchema.parse("Asia/Singapore"),
      ),
    ).toEqual({ date: "2026-10-15", time: "01:00:00" });
  });

  it.each(["2026-02-30", "2026-2-03", "0000-01-01", "invalid"])(
    "rejects invalid dates: %s",
    (input) => {
      expect(localDateSchema.safeParse(input).success).toBe(false);
    },
  );

  it("rejects unsupported zones, local offsets and noncanonical clock values", () => {
    for (const input of ["Mars/Olympus", "+08:00", ""])
      expect(timeZoneSchema.safeParse(input).success).toBe(false);
    for (const input of ["24:00:00", "12:60:00", "9:30", "12:30:60"])
      expect(wallTimeSchema.safeParse(input).success).toBe(false);
    expect(
      utcInstantSchema.safeParse("2026-10-14T09:30:00+08:00").success,
    ).toBe(false);
  });

  it.each([
    "2026-10-14T09:30Z",
    "2026-10-14t09:30:00z",
    "2026-02-30T09:30:00Z",
    "2026-10-14T09:30:00+08:00",
  ])("rejects a noncanonical/invalid UTC instant: %s", (input) => {
    expect(utcInstantSchema.safeParse(input).success).toBe(false);
  });
});
