import { z } from "zod";

export const publicEnvSchema = z.strictObject({
  NEXT_PUBLIC_SUPABASE_URL: z.url({ protocol: /^https?$/ }),
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: z
    .string()
    .regex(/^sb_publishable_[A-Za-z0-9_-]+$/),
});

export type PublicEnv = z.infer<typeof publicEnvSchema>;

export class EnvironmentConfigurationError extends Error {
  constructor() {
    super(
      "Supabase configuration is missing or invalid. Check .env.local against .env.example.",
    );
    this.name = "EnvironmentConfigurationError";
  }
}

export function parsePublicEnv(input: unknown): PublicEnv {
  const parsed = publicEnvSchema.safeParse(input);
  if (!parsed.success) throw new EnvironmentConfigurationError();
  return parsed.data;
}
