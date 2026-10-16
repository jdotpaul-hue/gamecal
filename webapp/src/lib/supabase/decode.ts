import type { z } from "zod";
import type { Result } from "@/lib/result";

export type InvalidResponse = {
  readonly code: "invalid_response";
};

// Decoding is separate from acknowledging a command: failure leaves acceptance unknown.
export function decodeRpcResponse<Value>(
  schema: z.ZodType<Value>,
  raw: unknown,
): Result<Value, InvalidResponse> {
  const parsed = schema.safeParse(raw);
  return parsed.success
    ? { ok: true, value: parsed.data }
    : { ok: false, error: { code: "invalid_response" } };
}
