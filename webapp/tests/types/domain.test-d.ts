import { localDateSchema } from "@/features/calendar";
import { deriveOccurrenceId } from "@/features/quests";
import {
  accountIdSchema,
  definitionIdSchema,
  type AccountId,
} from "@/lib/validation/ids";
import { revisionSchema } from "@/lib/validation/revisions";
import type { createBrowserAuthClient } from "@/lib/supabase/browser";

export function checkDomainTypes(
  _client: ReturnType<typeof createBrowserAuthClient>,
) {
  const accountId = accountIdSchema.parse(
    "fda923dc-3ebd-489e-a655-37e04fef3163",
  );
  const definitionId = definitionIdSchema.parse(
    "fda923dc-3ebd-489e-a655-37e04fef3163",
  );
  const date = localDateSchema.parse("2026-10-14");
  deriveOccurrenceId(definitionId, date);
  // @ts-expect-error Account identity cannot substitute for a definition identity.
  deriveOccurrenceId(accountId, date);
  // @ts-expect-error Unvalidated raw strings cannot become domain account IDs.
  const rawId: AccountId = "fda923dc-3ebd-489e-a655-37e04fef3163";
  // @ts-expect-error A revision cannot substitute for an account identity.
  const wrongId: AccountId = revisionSchema.parse("9007199254740993");
  type HasTableAccess = "from" extends keyof typeof _client ? true : false;
  type HasRpcAccess = "rpc" extends keyof typeof _client ? true : false;
  // @ts-expect-error The Auth facade must not expose table access before generated schema types.
  const tableAccess: HasTableAccess = true;
  // @ts-expect-error The Auth facade must not expose RPC access before generated schema types.
  const rpcAccess: HasRpcAccess = true;
  return { rawId, wrongId, tableAccess, rpcAccess };
}
