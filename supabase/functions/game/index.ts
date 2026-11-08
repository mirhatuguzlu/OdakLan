// The only writer of game state. Runs the shared Dart rules (core.js, built by
// packages/odaklan_core/tool/build_server.sh) with the SERVER clock:
// POST {action, tzOffsetMinutes} with the user's JWT → GameResult JSON.
import "./core.js";

const handle = (globalThis as unknown as {
  odaklanHandle: (req: string) => string;
}).odaklanHandle;

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
// Service role stays inside this function; game_states has no client grants.
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TABLE = `${SUPABASE_URL}/rest/v1/game_states`;
const service = {
  apikey: SERVICE_KEY,
  Authorization: `Bearer ${SERVICE_KEY}`,
  "Content-Type": "application/json",
};
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

function reply(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

async function userId(req: Request): Promise<string | null> {
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) return null;
  const r = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { apikey: SERVICE_KEY, Authorization: auth },
  });
  if (!r.ok) return null;
  const id = (await r.json())?.id;
  return typeof id === "string" && UUID.test(id) ? id : null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return reply({ error: "methodNotAllowed" }, 405);
  const id = await userId(req);
  if (!id) return reply({ error: "unauthorized" }, 401);

  const text = await req.text();
  if (text.length > 2048) return reply({ error: "badRequest" }, 413);
  let body: { action?: unknown; tzOffsetMinutes?: unknown };
  try {
    body = JSON.parse(text);
  } catch {
    return reply({ error: "badRequest" }, 400);
  }

  // Optimistic concurrency: two devices acting at once never lose a write.
  for (let attempt = 0; attempt < 3; attempt++) {
    const r = await fetch(`${TABLE}?user_id=eq.${id}&select=state,version`, {
      headers: service,
    });
    if (!r.ok) return reply({ error: "server" }, 500);
    const row = (await r.json())[0] as
      | { state: unknown; version: number }
      | undefined;

    const out = JSON.parse(handle(JSON.stringify({
      state: row?.state ?? null,
      action: body.action,
      nowUtcMs: Date.now(),
      tzOffsetMinutes: body.tzOffsetMinutes,
    })));
    if (!out.state) return reply(out, 400);

    const saved = row
      ? await fetch(`${TABLE}?user_id=eq.${id}&version=eq.${row.version}`, {
        method: "PATCH",
        headers: { ...service, Prefer: "return=representation" },
        body: JSON.stringify({
          state: out.state,
          version: row.version + 1,
          updated_at: new Date().toISOString(),
        }),
      })
      : await fetch(TABLE, {
        method: "POST",
        headers: { ...service, Prefer: "return=representation" },
        body: JSON.stringify({ user_id: id, state: out.state, version: 1 }),
      });
    if (saved.status === 409) continue; // another device created the row
    if (!saved.ok) return reply({ error: "server" }, 500);
    if (((await saved.json()) as unknown[]).length === 1) return reply(out);
    // 0 rows patched: the version moved on; re-read and re-apply.
  }
  return reply({ error: "conflict" }, 409);
});
