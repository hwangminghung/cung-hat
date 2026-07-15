// GoTrue Send-SMS hook. XAC THUC = Standard Webhooks signature (GoTrue ky moi request)
// — verify_jwt=false trong config.toml vi GoTrue KHONG gui JWT; thieu chu ky/secret -> chan.
// KHONG BAO GIO log OTP/phone. Provider VN chua chon -> fail-closed 501 sau khi verify.
import { json, safeEqual } from "../_shared/hmac.ts";

// Uint8Array<ArrayBuffer> (khong phai ArrayBufferLike): lib type Deno 2.9+
// yeu cau BufferSource khong-shared cho crypto.subtle.importKey.
function b64ToBytes(b64: string): Uint8Array<ArrayBuffer> {
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}
async function hmacSha256B64(key: Uint8Array<ArrayBuffer>, msg: string): Promise<string> {
  const k = await crypto.subtle.importKey("raw", key, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(msg));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

Deno.serve(async (req) => {
  const secretEnv = Deno.env.get("SEND_SMS_HOOK_SECRET");
  if (!secretEnv) return json(503, { error: "sms_hook_not_configured" });

  const id = req.headers.get("webhook-id");
  const ts = req.headers.get("webhook-timestamp");
  const sigHeader = req.headers.get("webhook-signature");
  if (!id || !ts || !sigHeader) return new Response("missing signature headers", { status: 401 });
  const tsNum = Number(ts);
  if (!Number.isFinite(tsNum) || Math.abs(Date.now() / 1000 - tsNum) > 300) {
    return new Response("stale timestamp", { status: 401 }); // chong replay 5 phut
  }

  const raw = await req.text();
  const secretB64 = secretEnv.startsWith("v1,whsec_") ? secretEnv.slice(9)
    : secretEnv.startsWith("whsec_") ? secretEnv.slice(6) : secretEnv;
  let expected: string;
  try {
    expected = await hmacSha256B64(b64ToBytes(secretB64), `${id}.${ts}.${raw}`);
  } catch {
    return json(503, { error: "sms_hook_secret_invalid" });
  }
  const ok = sigHeader.split(" ").some((part) => {
    const [ver, sig] = part.split(",");
    return ver === "v1" && typeof sig === "string" && safeEqual(sig, expected);
  });
  if (!ok) return new Response("bad signature", { status: 401 });

  let parsed: { user?: { phone?: string }; sms?: { phone?: string; otp?: string } };
  try { parsed = JSON.parse(raw); } catch { return json(400, { error: "bad payload" }); }
  const phone = parsed.user?.phone ?? parsed.sms?.phone;
  const otp = parsed.sms?.otp;
  if (!phone || !otp) return json(400, { error: "missing phone/otp" });

  if (!Deno.env.get("SMS_API_KEY")) return json(503, { error: "sms_provider_not_configured" });
  // TODO(prod): goi provider SMS VN voi SMS_API_KEY. Toi khi chon provider: fail-closed.
  return json(501, { error: "sms_provider_not_implemented" });
});
