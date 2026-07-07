// Verify receipt iOS: JWS StoreKit2 (chuoi x5c ve Apple Root, thu vien chinh chu Apple)
// hoac base64 legacy qua verifyReceipt + shared secret. Fail-closed o moi nhanh loi.
import { SignedDataVerifier, Environment } from "npm:@apple/app-store-server-library@1.4.0";
import { Buffer } from "node:buffer";

const APPLE_ROOT_URLS = [
  "https://www.apple.com/appleca/AppleIncRootCertificate.cer",
  "https://www.apple.com/certificateauthority/AppleRootCA-G3.cer",
];
let cachedRoots: Buffer[] | null = null;

async function appleRoots(): Promise<Buffer[]> {
  if (cachedRoots) return cachedRoots;
  const bufs: Buffer[] = [];
  for (const u of APPLE_ROOT_URLS) {
    const res = await fetch(u);
    if (!res.ok) throw new Error(`apple_root_fetch_${res.status}`);
    bufs.push(Buffer.from(await res.arrayBuffer()));
  }
  cachedRoots = bufs;
  return bufs;
}

export async function verifyAppleReceipt(opts: {
  receipt: string; bundleId: string; environment: string;
  sharedSecret: string | undefined; expectedTxnId: string; expectedProductId: string;
}): Promise<{ ok: boolean; reason?: string }> {
  const isJws = opts.receipt.split(".").length === 3;
  if (isJws) {
    try {
      const roots = await appleRoots();
      const env = opts.environment === "Production"
        ? Environment.PRODUCTION : Environment.SANDBOX;
      const verifier = new SignedDataVerifier(roots, false, env, opts.bundleId);
      const txn = await verifier.verifyAndDecodeTransaction(opts.receipt);
      if (String(txn.transactionId) !== opts.expectedTxnId) {
        return { ok: false, reason: "txn_mismatch" };
      }
      if (txn.productId !== opts.expectedProductId) {
        return { ok: false, reason: "product_mismatch" };
      }
      return { ok: true };
    } catch (e) {
      return { ok: false, reason: `jws_verify_failed:${(e as Error).message}` };
    }
  }
  // Legacy StoreKit1 base64 receipt -> verifyReceipt (prod truoc, 21007 -> sandbox).
  if (!opts.sharedSecret) return { ok: false, reason: "shared_secret_missing" };
  async function call(host: string) {
    const res = await fetch(`https://${host}/verifyReceipt`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ "receipt-data": opts.receipt, password: opts.sharedSecret }),
    });
    return res.json().catch(() => null);
  }
  let data = await call("buy.itunes.apple.com");
  if (data?.status === 21007) data = await call("sandbox.itunes.apple.com");
  if (!data || data.status !== 0) return { ok: false, reason: `verify_receipt_${data?.status}` };
  const txns = [...(data.latest_receipt_info ?? []), ...(data.receipt?.in_app ?? [])];
  const hit = txns.find((t: Record<string, string>) =>
    t.transaction_id === opts.expectedTxnId && t.product_id === opts.expectedProductId);
  if (!hit) return { ok: false, reason: "txn_not_in_receipt" };
  return { ok: true };
}
