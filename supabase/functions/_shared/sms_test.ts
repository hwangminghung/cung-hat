import { assertEquals, assertStringIncludes } from "jsr:@std/assert@1";
import { sendOtpSms, type SmsDeps } from "./sms.ts";

const OTP = "123456";
const PHONE = "+84900000001";

function envOf(map: Record<string, string>): SmsDeps["env"] {
  return (k) => map[k];
}

Deno.test("chua chon provider -> fail-closed 503, khong goi mang", async () => {
  let called = false;
  const res = await sendOtpSms(PHONE, OTP, {
    env: envOf({}),
    fetchImpl: () => {
      called = true;
      return Promise.resolve(new Response("{}"));
    },
  });
  assertEquals(res, { ok: false, status: 503, error: "sms_provider_not_configured" });
  assertEquals(called, false);
});

Deno.test("ten provider la -> fail-closed, khong doan", async () => {
  const res = await sendOtpSms(PHONE, OTP, {
    env: envOf({ SMS_PROVIDER: "vinaphone-gi-do" }),
  });
  assertEquals(res, { ok: false, status: 503, error: "sms_provider_unknown" });
});

Deno.test("esms thieu credential -> 503 truoc khi goi mang", async () => {
  let called = false;
  const res = await sendOtpSms(PHONE, OTP, {
    env: envOf({ SMS_PROVIDER: "esms", SMS_API_KEY: "k" }),
    fetchImpl: () => {
      called = true;
      return Promise.resolve(new Response("{}"));
    },
  });
  assertEquals(res.ok, false);
  assertEquals(called, false);
});

Deno.test("esms thanh cong (CodeResult 100) -> ok", async () => {
  const res = await sendOtpSms(PHONE, OTP, {
    env: envOf({
      SMS_PROVIDER: "esms",
      SMS_API_KEY: "k",
      ESMS_SECRET_KEY: "s",
      SMS_BRANDNAME: "CUNGHAT",
    }),
    fetchImpl: () =>
      Promise.resolve(
        new Response(JSON.stringify({ CodeResult: "100" }), { status: 200 }),
      ),
  });
  assertEquals(res, { ok: true });
});

// eSMS tra HTTP 200 KE CA khi that bai — chi CodeResult moi noi that.
Deno.test("esms HTTP 200 nhung CodeResult != 100 -> KHONG coi la gui duoc", async () => {
  const res = await sendOtpSms(PHONE, OTP, {
    env: envOf({
      SMS_PROVIDER: "esms",
      SMS_API_KEY: "k",
      ESMS_SECRET_KEY: "s",
      SMS_BRANDNAME: "CUNGHAT",
    }),
    fetchImpl: () =>
      Promise.resolve(
        new Response(JSON.stringify({ CodeResult: "104" }), { status: 200 }),
      ),
  });
  assertEquals(res, { ok: false, status: 502, error: "esms_code_104" });
});

Deno.test("provider treo -> tu ngat 504, khong cho vo han", async () => {
  const res = await sendOtpSms(PHONE, OTP, {
    env: envOf({
      SMS_PROVIDER: "esms",
      SMS_API_KEY: "k",
      ESMS_SECRET_KEY: "s",
      SMS_BRANDNAME: "CUNGHAT",
    }),
    timeoutMs: 20,
    // Khong bao gio hoan thanh — tru khi bi abort.
    fetchImpl: (_url, init) =>
      new Promise((_resolve, reject) => {
        init?.signal?.addEventListener("abort", () =>
          reject(new DOMException("aborted", "AbortError")));
      }),
  });
  assertEquals(res, { ok: false, status: 504, error: "sms_provider_timeout" });
});

Deno.test("loi mang -> 502, KHONG lo phone/otp ra message", async () => {
  const res = await sendOtpSms(PHONE, OTP, {
    env: envOf({
      SMS_PROVIDER: "esms",
      SMS_API_KEY: "k",
      ESMS_SECRET_KEY: "s",
      SMS_BRANDNAME: "CUNGHAT",
    }),
    fetchImpl: () => Promise.reject(new TypeError("dns boom")),
  });
  assertEquals(res, { ok: false, status: 502, error: "sms_provider_unreachable" });
});

Deno.test("noi dung tin nhan dien OTP va theo template env", async () => {
  let sentBody = "";
  await sendOtpSms(PHONE, OTP, {
    env: envOf({
      SMS_PROVIDER: "esms",
      SMS_API_KEY: "k",
      ESMS_SECRET_KEY: "s",
      SMS_BRANDNAME: "CUNGHAT",
      SMS_TEMPLATE: "Ma {otp} nhe",
    }),
    fetchImpl: (_url, init) => {
      sentBody = String(init?.body ?? "");
      return Promise.resolve(
        new Response(JSON.stringify({ CodeResult: "100" }), { status: 200 }),
      );
    },
  });
  assertStringIncludes(sentBody, "Ma 123456 nhe");
  // SmsType 2 = CSKH/OTP. "8" la quang cao, gui OTP bang loai do se bi tu choi.
  assertStringIncludes(sentBody, '"SmsType":"2"');
});
