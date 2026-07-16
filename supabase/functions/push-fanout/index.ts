import { createClient } from "jsr:@supabase/supabase-js@2";
import { safeEqual } from "../_shared/hmac.ts";

// Invoked (by DB trigger via pg_net, or directly) with {user_ids, title, body, data}.
// `title`/`body` from notify_push are the raw EVENT KEY (no PII) — map to VI copy
// here. Sends via FCM HTTP v1 using GOOGLE_FCM_SA_JSON (service account); when
// that env is absent (local/dev, external gate) we log-and-count only.
const COPY: Record<string, { title: string; body: string }> = {
  new_message: { title: "Cùng Hát", body: "Bạn có tin nhắn mới 🎵" },
  keo_join_request: { title: "Cùng Hát", body: "Có người xin vào kèo của bạn" },
  plan_proposed: { title: "Cùng Hát", body: "Kèo của bạn có kế hoạch mới — vào xác nhận nhé" },
  keo_tonight: { title: "Cùng Hát", body: "Kèo của bạn diễn ra tối nay — hẹn gặp ở phòng hát 🎤" },
  new_singers: { title: "Cùng Hát", body: "Có người hát mới hợp gu quanh bạn — vào xem thử nhé" },
};

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
};

// Access-token cache: edge isolate co the phuc vu nhieu request lien tiep,
// token OAuth song 1h — khong xin lai moi lan fanout.
let cachedToken: { token: string; exp: number } | null = null;

function b64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

async function fcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp - 60 > now) return cachedToken.token;
  const tokenUri = sa.token_uri ?? "https://oauth2.googleapis.com/token";
  const enc = new TextEncoder();
  const header = b64url(enc.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claims = b64url(enc.encode(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: tokenUri,
    iat: now,
    exp: now + 3600,
  })));
  const unsigned = `${header}.${claims}`;
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8", der.buffer as ArrayBuffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const sig = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, enc.encode(unsigned)));
  const jwt = `${unsigned}.${b64url(sig)}`;
  const res = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`fcm oauth failed: ${res.status}`);
  const json = await res.json();
  cachedToken = { token: json.access_token, exp: now + (json.expires_in ?? 3600) };
  return cachedToken.token;
}

Deno.serve(async (req) => {
  const secret = Deno.env.get("PUSH_FANOUT_SECRET");
  if (!secret) return new Response(JSON.stringify({ error: "fanout_not_configured" }), { status: 503, headers: { "Content-Type": "application/json" } });
  const got = req.headers.get("x-fanout-secret");
  if (!got || !safeEqual(got, secret)) return new Response("forbidden", { status: 403 });
  const { user_ids, title, data } = await req.json();
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: tokens } = await admin.from("device_tokens")
    .select("fcm_token").in("user_id", user_ids ?? []);
  const tokenList: string[] = (tokens ?? []).map((t: { fcm_token: string }) => t.fcm_token);

  // External gate: chua co service account -> dem-va-log nhu truoc, khong fail.
  const saRaw = Deno.env.get("GOOGLE_FCM_SA_JSON");
  if (!saRaw) {
    console.log(`[push-fanout] DRY-RUN (no SA): ${(user_ids ?? []).length} users, ${tokenList.length} tokens`);
    return new Response(JSON.stringify({ sent: tokenList.length, delivered: 0, dry_run: true }), { headers: { "Content-Type": "application/json" } });
  }

  const sa: ServiceAccount = JSON.parse(saRaw);
  const event = String(title ?? "");
  const copy = COPY[event] ?? { title: "Cùng Hát", body: "Bạn có thông báo mới" };
  // FCM data values PHAI la string; giu event key de client route khi tap.
  const dataStr: Record<string, string> = { event };
  for (const [k, v] of Object.entries((data ?? {}) as Record<string, unknown>)) {
    dataStr[k] = String(v);
  }

  const accessToken = await fcmAccessToken(sa);
  const sendUrl = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;
  let delivered = 0;
  const dead: string[] = [];
  await Promise.all(tokenList.map(async (fcmToken) => {
    const res = await fetch(sendUrl, {
      method: "POST",
      headers: { "Authorization": `Bearer ${accessToken}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title: copy.title, body: copy.body },
          data: dataStr,
        },
      }),
    });
    if (res.ok) {
      delivered++;
      return;
    }
    // 404 UNREGISTERED / 400 invalid -> token chet, don khoi bang de fanout
    // sau khong ban vao token rac.
    if (res.status === 404 || res.status === 400) dead.push(fcmToken);
    // KHONG log body loi (co the chua token) — chi status.
    console.log(`[push-fanout] send failed: ${res.status}`);
    await res.body?.cancel();
  }));
  if (dead.length > 0) {
    await admin.from("device_tokens").delete().in("fcm_token", dead);
  }
  // KHONG log title/body/data (PII noi dung thong bao) — chi so luong.
  console.log(`[push-fanout] fanout ${event}: ${(user_ids ?? []).length} users, ${tokenList.length} tokens, ${delivered} delivered, ${dead.length} pruned`);
  return new Response(JSON.stringify({ sent: tokenList.length, delivered }), { headers: { "Content-Type": "application/json" } });
});
