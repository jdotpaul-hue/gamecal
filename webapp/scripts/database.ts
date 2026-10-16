import { spawnSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  writeFileSync,
} from "node:fs";
import { dirname, resolve } from "node:path";

const mode = process.argv[2];
const destination = resolve("src/types/database.generated.ts");
const migrations = resolve("supabase/migrations");

if (
  !existsSync(migrations) ||
  !readdirSync(migrations).some((name) => name.endsWith(".sql"))
) {
  console.error(
    "Database checks are not ready: no application migrations exist. Implement and prove the local schema/RLS slice first; no remote project is required.",
  );
  process.exit(1);
}

if (mode === "test") {
  if (
    !existsSync("supabase/tests") ||
    !readdirSync("supabase/tests", { recursive: true }).some(
      (name) => typeof name === "string" && name.endsWith(".sql"),
    )
  ) {
    console.error(
      "No SQL behavior/RLS tests exist yet; the database check cannot pass without them.",
    );
    process.exit(1);
  }
  const run = spawnSync("pnpm", ["exec", "supabase", "test", "db"], {
    stdio: "inherit",
  });
  process.exit(run.status ?? 1);
}

if (mode !== "generate" && mode !== "check") {
  console.error("Expected generate, check, or test.");
  process.exit(1);
}

const run = spawnSync(
  "pnpm",
  [
    "exec",
    "supabase",
    "gen",
    "types",
    "typescript",
    "--local",
    "--schema",
    "public",
  ],
  { encoding: "utf8" },
);
if (run.error || run.status !== 0 || !run.stdout.trim()) {
  console.error(
    "Local type generation failed. Start the disposable Supabase stack and apply local migrations; the existing generated file was preserved.",
  );
  process.exit(1);
}

if (mode === "check") {
  if (
    !existsSync(destination) ||
    readFileSync(destination, "utf8") !== run.stdout
  ) {
    console.error(
      "Generated database types are missing or stale. Run pnpm db:types against the migrated local stack.",
    );
    process.exit(1);
  }
} else {
  mkdirSync(dirname(destination), { recursive: true });
  writeFileSync(destination, run.stdout);
}
