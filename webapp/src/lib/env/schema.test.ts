import { describe, expect, it } from "vitest";
import { EnvironmentConfigurationError, parsePublicEnv } from "./schema";

describe("public environment boundary", () => {
  it("accepts explicit public configuration", () => {
    const input = {
      NEXT_PUBLIC_SUPABASE_URL: "http://127.0.0.1:54321",
      NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_test_key",
    };
    expect(parsePublicEnv(input)).toEqual(input);
  });

  it.each([
    "sb_secret_do_not_leak",
    "",
    "eyJhbGciOiJIUzI1NiJ9.legacy.signature",
  ])(
    "rejects unsupported or privileged keys without including values in errors",
    (key) => {
      expect(() =>
        parsePublicEnv({
          NEXT_PUBLIC_SUPABASE_URL: "https://example.supabase.co",
          NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: key,
        }),
      ).toThrow(EnvironmentConfigurationError);
      try {
        parsePublicEnv({
          NEXT_PUBLIC_SUPABASE_URL: "invalid",
          NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: key,
        });
      } catch (error: unknown) {
        expect(error).toBeInstanceOf(EnvironmentConfigurationError);
        if (error instanceof Error && key.length > 0)
          expect(error.message).not.toContain(key);
      }
    },
  );
});
