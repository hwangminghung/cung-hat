// Verify purchase Android qua Google Play Developer API (service account JWT RS256).
function b64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  return btoa(String.fromCharCode(...bytes))
    .replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

// Uint8Array<ArrayBuffer> (khong phai ArrayBufferLike): lib type Deno 2.9+
// yeu cau BufferSource khong-shared cho crypto.subtle.importKey.
function pemToDer(pem: string): Uint8Array<ArrayBuffer> {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

export async function verifyGooglePurchase(opts: {
  saJson: string; packageName: string; productId: string; purchaseToken: string;
}): Promise<{ ok: boolean; reason?: string; orderId?: string; consumptionState?: number }> {
  let sa: { client_email: string; private_key: string; token_uri: string };
  try { sa = JSON.parse(opts.saJson); } catch { return { ok: false, reason: "bad_sa_json" }; }

  // Fail-closed: moi loi bat ngo (private key hong, mat mang, JSON hong) -> ok:false,
  // KHONG de exception thoat ra thanh 500 khong kiem soat.
  try {
    const now = Math.floor(Date.now() / 1000);
    const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
    const claims = b64url(JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: sa.token_uri, iat: now, exp: now + 3600,
    }));
    const key = await crypto.subtle.importKey(
      "pkcs8", pemToDer(sa.private_key),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
    const sig = new Uint8Array(await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`)));
    const jwt = `${header}.${claims}.${b64url(sig)}`;

    const tokenRes = await fetch(sa.token_uri, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `grant_type=${encodeURIComponent("urn:ietf:params:oauth:grant-type:jwt-bearer")}&assertion=${jwt}`,
    });
    const { access_token } = await tokenRes.json().catch(() => ({}));
    if (!access_token) return { ok: false, reason: "token_exchange_failed" };

    const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
      `${opts.packageName}/purchases/products/${encodeURIComponent(opts.productId)}` +
      `/tokens/${encodeURIComponent(opts.purchaseToken)}`;
    const res = await fetch(url, { headers: { Authorization: `Bearer ${access_token}` } });
    if (!res.ok) return { ok: false, reason: `play_api_${res.status}` };
    const purchase = await res.json();
    if (purchase.purchaseState !== 0) return { ok: false, reason: "not_purchased" };
    if (purchase.acknowledgementState === 0) {
      await fetch(`${url}:acknowledge`, {
        method: "POST",
        headers: { Authorization: `Bearer ${access_token}`, "Content-Type": "application/json" },
        body: "{}",
      });
    }
    // orderId/consumptionState lay tu response DA verify — caller dung orderId lam
    // txn id authoritative (KHONG tin store_txn_id client) va chan boost da consume.
    return {
      ok: true,
      orderId: typeof purchase.orderId === "string" && purchase.orderId !== ""
        ? purchase.orderId : undefined,
      consumptionState: typeof purchase.consumptionState === "number"
        ? purchase.consumptionState : undefined,
    };
  } catch (e) {
    return { ok: false, reason: `google_verify_error:${(e as Error).message}` };
  }
}
