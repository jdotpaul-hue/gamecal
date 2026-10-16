import "client-only";
import { createBrowserSupabaseClient } from "@/lib/supabase/client";

export function createBrowserAuthClient() {
  const client = createBrowserSupabaseClient();
  return { auth: client.auth, client };
}
