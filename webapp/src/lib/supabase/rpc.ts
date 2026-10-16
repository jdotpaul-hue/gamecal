import type { SupabaseClient } from "@supabase/supabase-js";
import type { z } from "zod";
import { readRequestEnvelopeSchema } from "@/lib/api/contracts/common";
import { commandSuccessResponseSchema } from "@/lib/api/contracts/commands";
import {
  getCalendarScopeRequestDataSchema,
  getCalendarScopeResponseSchema,
  getProfileResponseSchema,
  getProgressionResponseSchema,
  operationResultResponseSchema,
  type GetCalendarScopeResponse,
  type GetProfileResponse,
  type GetProgressionResponse,
  type OperationResultResponse,
} from "@/lib/api/contracts/reads";
import { decodeRpcResponse } from "@/lib/supabase/decode";
import type { Result } from "@/lib/result";
import type { InvalidResponse } from "@/lib/supabase/decode";
import type { Database, Json } from "@/types/database.generated";
import type { OperationId } from "@/lib/validation/ids";

type RpcClient = SupabaseClient<Database>;
type RpcDecodeError = InvalidResponse | { code: "rpc_error"; message: string };

function buildReadRequest(data: Record<string, unknown>): { request: Json } {
  return {
    request: readRequestEnvelopeSchema.parse({
      contract_version: 1,
      data,
    }) as Json,
  };
}

async function callReadRpc<Schema extends z.ZodTypeAny>(
  client: RpcClient,
  functionName: keyof Database["public"]["Functions"],
  data: Record<string, unknown>,
  schema: Schema,
): Promise<Result<z.infer<Schema>, RpcDecodeError>> {
  const { data: raw, error } = await client.rpc(
    functionName,
    buildReadRequest(data),
  );

  if (error) {
    return { ok: false, error: { code: "rpc_error", message: error.message } };
  }

  return decodeRpcResponse(schema, raw);
}

export async function getProfile(
  client: RpcClient,
): Promise<Result<GetProfileResponse, RpcDecodeError>> {
  return callReadRpc(client, "get_profile", {}, getProfileResponseSchema);
}

export async function getProgression(
  client: RpcClient,
): Promise<Result<GetProgressionResponse, RpcDecodeError>> {
  return callReadRpc(
    client,
    "get_progression",
    {},
    getProgressionResponseSchema,
  );
}

export async function getCalendarScope(
  client: RpcClient,
  input: z.input<typeof getCalendarScopeRequestDataSchema>,
): Promise<Result<GetCalendarScopeResponse, RpcDecodeError>> {
  const data = getCalendarScopeRequestDataSchema.parse(input);
  return callReadRpc(
    client,
    "get_calendar_scope",
    data,
    getCalendarScopeResponseSchema,
  );
}

export async function getOwnOperationResult(
  client: RpcClient,
  operationId: OperationId,
): Promise<Result<OperationResultResponse, RpcDecodeError>> {
  return callReadRpc(
    client,
    "get_own_operation_result",
    { operation_id: operationId },
    operationResultResponseSchema,
  );
}

export async function invokeCommand(
  client: RpcClient,
  functionName:
    | "ensure_profile"
    | "create_quest"
    | "complete_occurrence"
    | "undo_occurrence"
    | "skip_occurrence"
    | "unskip_occurrence",
  request: Json,
): Promise<
  Result<z.infer<typeof commandSuccessResponseSchema>, RpcDecodeError>
> {
  const { data: raw, error } = await client.rpc(functionName, { request });

  if (error) {
    return { ok: false, error: { code: "rpc_error", message: error.message } };
  }

  return decodeRpcResponse(commandSuccessResponseSchema, raw);
}
