// Gui OTP qua provider SMS. Tach khoi send-sms/index.ts de test duoc ma khong
// can dung toi phan verify chu ky Standard Webhooks.
//
// BAT BIEN: khong bao gio dua so dien thoai hoac OTP vao message loi / log.
// Loi tra ve chi noi ve PHIA PROVIDER (status, ma loi cua ho).
//
// Chon provider bang env `SMS_PROVIDER`. Chua chon (hoac ten la) -> fail-closed,
// KHONG bao gio im lang coi nhu da gui.

export type SmsResult =
  | { ok: true }
  | { ok: false; status: number; error: string };

export interface SmsDeps {
  env: (key: string) => string | undefined;
  fetchImpl?: typeof fetch;
  /// Kong/provider treo thi request khong bao gio ve — GoTrue se cho het
  /// timeout cua no va user bam gui lai lien tuc. Tu ngat de tra loi ro rang.
  timeoutMs?: number;
}

const DEFAULT_TIMEOUT_MS = 10_000;

/// Noi dung tin nhan. Brandname VN phai dang ky truoc TEMPLATE voi nha mang,
/// nen cho phep override qua env; `{otp}` la cho dien ma.
function buildContent(env: SmsDeps["env"], otp: string): string {
  const template = env("SMS_TEMPLATE") ??
    "{otp} la ma xac thuc Cung Hat cua ban. Ma co hieu luc 5 phut.";
  return template.replaceAll("{otp}", otp);
}

async function postWithTimeout(
  url: string,
  init: RequestInit,
  deps: SmsDeps,
): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(
    () => controller.abort(),
    deps.timeoutMs ?? DEFAULT_TIMEOUT_MS,
  );
  try {
    const f = deps.fetchImpl ?? fetch;
    return await f(url, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

/// eSMS.vn — SendMultipleMessage_V4. SmsType "2" = brandname CSKH (loai dung
/// cho OTP; SmsType "8" la quang cao, KHONG dung cho OTP).
async function sendViaEsms(
  phone: string,
  otp: string,
  deps: SmsDeps,
): Promise<SmsResult> {
  const apiKey = deps.env("SMS_API_KEY");
  const secretKey = deps.env("ESMS_SECRET_KEY");
  const brandname = deps.env("SMS_BRANDNAME");
  if (!apiKey || !secretKey || !brandname) {
    return { ok: false, status: 503, error: "esms_missing_credentials" };
  }
  const res = await postWithTimeout(
    "https://rest.esms.vn/MainService.svc/json/SendMultipleMessage_V4_post_json/",
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        ApiKey: apiKey,
        SecretKey: secretKey,
        Brandname: brandname,
        SmsType: "2",
        Phone: phone,
        Content: buildContent(deps.env, otp),
      }),
    },
    deps,
  );
  if (!res.ok) {
    return { ok: false, status: 502, error: `esms_http_${res.status}` };
  }
  // eSMS tra HTTP 200 KE CA khi that bai — CodeResult "100" moi la thanh cong.
  let body: { CodeResult?: string; ErrorMessage?: string };
  try {
    body = await res.json();
  } catch {
    return { ok: false, status: 502, error: "esms_bad_json" };
  }
  if (body.CodeResult !== "100") {
    return {
      ok: false,
      status: 502,
      error: `esms_code_${body.CodeResult ?? "unknown"}`,
    };
  }
  return { ok: true };
}

/// Twilio — de test/du phong. Gui ve dau so VN qua Twilio hay bi chan
/// brandname, xem plan operator-gates G1.
async function sendViaTwilio(
  phone: string,
  otp: string,
  deps: SmsDeps,
): Promise<SmsResult> {
  const sid = deps.env("TWILIO_ACCOUNT_SID");
  const token = deps.env("SMS_API_KEY");
  const from = deps.env("TWILIO_FROM");
  if (!sid || !token || !from) {
    return { ok: false, status: 503, error: "twilio_missing_credentials" };
  }
  const res = await postWithTimeout(
    `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
    {
      method: "POST",
      headers: {
        "content-type": "application/x-www-form-urlencoded",
        authorization: `Basic ${btoa(`${sid}:${token}`)}`,
      },
      body: new URLSearchParams({
        To: phone,
        From: from,
        Body: buildContent(deps.env, otp),
      }),
    },
    deps,
  );
  if (!res.ok) {
    return { ok: false, status: 502, error: `twilio_http_${res.status}` };
  }
  return { ok: true };
}

/// Gui OTP. Tra ve ket qua thay vi throw de caller quyet dinh status tra cho
/// GoTrue; timeout/loi mang cung thanh SmsResult chu khong lam no function.
export async function sendOtpSms(
  phone: string,
  otp: string,
  deps: SmsDeps,
): Promise<SmsResult> {
  const provider = (deps.env("SMS_PROVIDER") ?? "").toLowerCase();
  if (!provider) {
    return { ok: false, status: 503, error: "sms_provider_not_configured" };
  }
  try {
    switch (provider) {
      case "esms":
        return await sendViaEsms(phone, otp, deps);
      case "twilio":
        return await sendViaTwilio(phone, otp, deps);
      default:
        // Ten provider la = cau hinh sai. Fail-closed, dung doan.
        return { ok: false, status: 503, error: "sms_provider_unknown" };
    }
  } catch (e) {
    // AbortError = het timeout. Moi loi khac coi la loi mang phia provider.
    // KHONG dua e.message vao response: co the chua URL kem query nhay cam.
    const timedOut = e instanceof DOMException && e.name === "AbortError";
    return {
      ok: false,
      status: timedOut ? 504 : 502,
      error: timedOut ? "sms_provider_timeout" : "sms_provider_unreachable",
    };
  }
}
