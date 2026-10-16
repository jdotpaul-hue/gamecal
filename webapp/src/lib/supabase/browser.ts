import "client-only";
import { createBrowserClient } from "@supabase/ssr";
import { getPublicEnv } from "@/lib/env/public";

export function createBrowserAuthClient() {
  const env = getPublicEnv();
  const client = createBrowserClient<never>(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  );
  // Expose only Auth until Database types can be generated from real local migrations.
  return { auth: client.auth };
}
