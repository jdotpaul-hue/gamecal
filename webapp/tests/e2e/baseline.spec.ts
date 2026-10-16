import { expect, test } from "@playwright/test";

test("serves the baseline shell and a non-sensitive health response", async ({
  page,
  request,
}) => {
  const health = await request.get("/api/health");
  expect(health.status()).toBe(200);
  const body: unknown = await health.json();
  expect(body).toEqual({ status: "ok" });
  expect(health.headers()["cache-control"]).toBe("no-store");
  await page.goto("/");
  await expect(page).toHaveTitle("Gamecal");
  await expect(page.getByRole("main")).toContainText(
    "Gamecal application foundation.",
  );
});
