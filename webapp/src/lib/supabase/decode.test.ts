import { describe, expect, it } from "vitest";
import { z } from "zod";
import { revisionSchema } from "@/lib/validation/revisions";
import { decodeRpcResponse } from "./decode";

// Fixture contract only: not an implemented calendar endpoint.
const fixtureResponse = z.strictObject({
  ok: z.literal(true),
  contract_version: z.literal(1),
  revision: revisionSchema,
});

describe("RPC response boundary", () => {
  it("returns only validated data without mutating the raw response", () => {
    const raw = { ok: true, contract_version: 1, revision: "9007199254740993" };
    expect(decodeRpcResponse(fixtureResponse, raw)).toEqual({
      ok: true,
      value: raw,
    });
    expect(raw.revision).toBe("9007199254740993");
  });

  it.each([
    null,
    { ok: true, contract_version: 2, revision: "1" },
    { ok: true, contract_version: 1, revision: 4 },
    { ok: true, contract_version: 1 },
    { ok: true, contract_version: 1, revision: "1", unexpected: "field" },
  ])("fails closed on malformed/version-unsupported JSON: %j", (input) => {
    expect(decodeRpcResponse(fixtureResponse, input)).toEqual({
      ok: false,
      error: { code: "invalid_response" },
    });
  });
});
