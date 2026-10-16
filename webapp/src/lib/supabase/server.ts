import "server-only";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { getPublicEnv } from "@/lib/env/public";

// Use in Route Handlers/Server Actions where response cookies may be written.
// Session-refresh Proxy and authenticated Server Component reads belong to the Auth slice.
export async function createServerAuthClient() {
  const env = getPublicEnv();
  const store = await cookies();
  const client = createServerClient<never>(
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
  return { auth: client.auth };
}
