import "server-only";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { SupabaseClient } from "@supabase/supabase-js";
import { getPublicEnv } from "@/lib/env/public";
import type { Database } from "@/types/database.generated";

// Use in Route Handlers/Server Actions where response cookies may be written.
// Session-refresh Proxy and authenticated Server Component reads belong to the Auth slice.
export async function createServerSupabaseClient(): Promise<
  SupabaseClient<Database>
> {
  const env = getPublicEnv();
  const store = await cookies();
  return createServerClient<Database>(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    {
      cookies: {
        getAll: () => store.getAll(),
        setAll: (updates) => {
          for (const { name, value, options } of updates) {
            store.set(name, value, options);
          }
        },
      },
    },
  );
}

export async function createServerAuthClient() {
  const client = await createServerSupabaseClient();
  return { auth: client.auth, client };
}
