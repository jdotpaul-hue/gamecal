import type { z } from "zod";
import type { Result } from "@/lib/result";

export type InvalidResponse = {
  readonly code: "invalid_response";
};

// Decoding is separate from acknowledging a command: failure leaves acceptance unknown.
export function decodeRpcResponse<Schema extends z.ZodTypeAny>(
  schema: Schema,
  raw: unknown,
): Result<z.infer<Schema>, InvalidResponse> {
  const parsed = schema.safeParse(raw);
  return parsed.success
    ? { ok: true, value: parsed.data }
    : { ok: false, error: { code: "invalid_response" } };
}
