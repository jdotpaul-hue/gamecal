import "server-only";
import { z } from "zod";

const serverEnvSchema = z.strictObject({
  NODE_ENV: z.enum(["development", "test", "production"]),
});

export function getServerEnv() {
  return serverEnvSchema.parse({ NODE_ENV: process.env.NODE_ENV });
}
