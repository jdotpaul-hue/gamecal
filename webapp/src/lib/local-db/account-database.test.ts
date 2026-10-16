import "fake-indexeddb/auto";
import Dexie from "dexie";
import { describe, expect, it } from "vitest";
import { accountIdSchema } from "@/lib/validation/ids";
import { openAccountDatabase } from "./account-database";

describe("account-scoped IndexedDB foundation", () => {
  it("keeps separate account metadata and reopens persisted state", async () => {
    const firstId = accountIdSchema.parse(crypto.randomUUID());
    const secondId = accountIdSchema.parse(crypto.randomUUID());
    const first = openAccountDatabase(firstId);
    const second = openAccountDatabase(secondId);
    try {
      expect(await first.initialize()).toMatchObject({
        ok: true,
        value: { account_id: firstId },
      });
      expect(await second.initialize()).toMatchObject({
        ok: true,
        value: { account_id: secondId },
      });
      first.close();
      const reopened = openAccountDatabase(firstId);
      try {
        expect(await reopened.initialize()).toMatchObject({
          ok: true,
          value: { account_id: firstId },
        });
      } finally {
        reopened.close();
      }
    } finally {
      first.close();
      second.close();
      await Dexie.delete(`gamecal:${firstId}`);
      await Dexie.delete(`gamecal:${secondId}`);
    }
  });

  it("preserves unsupported persisted data instead of overwriting it", async () => {
    const id = accountIdSchema.parse(crypto.randomUUID());
    const raw = new Dexie(`gamecal:${id}`);
    raw.version(1).stores({ sync_meta: "key" });
    const record = { key: "schema", local_schema_version: 99, account_id: id };
    await raw.table<unknown, string>("sync_meta").put(record, undefined);
    raw.close();
    const account = openAccountDatabase(id);
    try {
      expect(await account.initialize()).toEqual({
        ok: false,
        error: { code: "invalid_local_metadata" },
      });
      const inspection = new Dexie(`gamecal:${id}`);
      try {
        await inspection.open();
        const stored: unknown = await inspection
          .table("sync_meta")
          .get("schema");
        expect(stored).toEqual(record);
      } finally {
        inspection.close();
      }
    } finally {
      account.close();
      await Dexie.delete(`gamecal:${id}`);
    }
  });
});
