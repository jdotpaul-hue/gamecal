import { describe, expect, it } from "vitest";
import { commandSuccessResponseSchema } from "@/lib/api/contracts/commands";
import {
  getProfileResponseSchema,
  operationResultResponseSchema,
} from "@/lib/api/contracts/reads";

describe("read/command response contracts", () => {
  it("accepts a profile read envelope", () => {
    const raw = {
      ok: true,
      contract_version: 1,
      data: {
        scope: { kind: "profile" },
        bootstrap_needed: false,
        records: [
          {
            entity: "profile",
            record: {
              id: "11111111-1111-4111-8111-111111111111",
              display_name: "Alice",
              planning_timezone: "UTC",
              revision: "1",
              account_data_revision: "1",
              sync_epoch: "22222222-2222-4222-8222-222222222222",
            },
          },
        ],
        snapshot_token: "{}",
        next_cursor: null,
        page_set_complete: true,
        coverage: { generation_complete: true },
        summary: { as_of: "2026-11-01T00:00:00.000Z" },
      },
    };

    expect(getProfileResponseSchema.parse(raw)).toEqual(raw);
  });

  it("accepts an operation receipt lookup", () => {
    const raw = {
      ok: true,
      contract_version: 1,
      data: {
        status: "accepted",
        acknowledgment: {
          operation_id: "c3000000-0000-4000-8000-000000000003",
          command_name: "complete_occurrence",
          accepted_at: "2026-11-01T12:00:00.000Z",
          outcome: { occurrence_id: "0a8f3101-1700-521b-bffe-423311e7b732" },
        },
      },
    };

    expect(operationResultResponseSchema.parse(raw)).toEqual(raw);
  });

  it("accepts a command success envelope with progression", () => {
    const raw = {
      ok: true,
      contract_version: 1,
      acknowledgment: {
        operation_id: "c3000000-0000-4000-8000-000000000003",
        command_name: "complete_occurrence",
        replayed: false,
        accepted_at: "2026-11-01T12:00:00.000Z",
        outcome: { occurrence_id: "0a8f3101-1700-521b-bffe-423311e7b732" },
      },
      canonical: {
        sync_epoch: "22222222-2222-4222-8222-222222222222",
        account_data_revision: "2",
        records: [],
        progression: {
          entity: "progression",
          record: { total_xp: "20", level: "1" },
        },
      },
      invalidations: [{ scope: "calendar" }],
    };

    expect(commandSuccessResponseSchema.parse(raw)).toEqual(raw);
  });
});
