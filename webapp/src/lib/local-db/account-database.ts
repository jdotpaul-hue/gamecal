import "client-only";
import Dexie from "dexie";
import { z } from "zod";
import type { Result } from "@/lib/result";
import { accountIdSchema, type AccountId } from "@/lib/validation/ids";

const metadataSchema = z.strictObject({
  key: z.literal("schema"),
  local_schema_version: z.literal(1),
  account_id: accountIdSchema,
});

type Metadata = z.infer<typeof metadataSchema>;
type MetadataFailure = { readonly code: "invalid_local_metadata" };

// The verified Auth owner must supply this ID; a parsed UUID is not authentication.
export function openAccountDatabase(accountId: AccountId) {
  const validatedAccountId = accountIdSchema.parse(accountId);
  const database = new Dexie(`gamecal:${validatedAccountId}`);
  database.version(1).stores({ sync_meta: "key" });
  const metadata = database.table<Metadata, Metadata["key"]>("sync_meta");

  return {
    async initialize(): Promise<Result<Metadata, MetadataFailure>> {
      return database.transaction("rw", metadata, async () => {
        const existing: unknown = await metadata.get("schema");
        if (existing !== undefined) {
          const decoded = metadataSchema.safeParse(existing);
          if (
            !decoded.success ||
            decoded.data.account_id !== validatedAccountId
          ) {
            return { ok: false, error: { code: "invalid_local_metadata" } };
          }
          return { ok: true, value: decoded.data };
        }
        const record: Metadata = {
          key: "schema",
          local_schema_version: 1,
          account_id: validatedAccountId,
        };
        await metadata.add(record);
        return { ok: true, value: record };
      });
    },
    close() {
      database.close();
    },
  };
}
