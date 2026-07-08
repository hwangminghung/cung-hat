#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# verify_payments_local.sh - Harness verify HMAC self-signed cho dot Maps+Payments
# -----------------------------------------------------------------------------
# MUC DICH
#   Kiem tra REAL crypto (cung thuat toan HMAC-SHA256 nhu gateway that) voi
#   secret DUMMY doc tu supabase/functions/.env. Ky IPN/callback ngay trong
#   script bang openssl, ban vao edge runtime local, doi chieu HTTP status +
#   trang thai row trong venue_bookings. KHONG bao gio gia mao 1 check de pass:
#   check nao fail thi debug CODE hoac tinh dung cua CHECK, roi bao cao that.
#
# PHAM VI CHECK (24 check() calls, gom 13 nhom):
#   1  momo IPN co chu ky        -> 204
#   2  booking -> paid + hoa hong 10% (2 check)
#   3  momo IPN replay           -> 204, state/commission KHONG doi (2 check)
#   4  momo IPN sua amount        -> 401 (chu ky vo hieu), state van paid (2 check)
#   4b momo IPN KY DUNG nhung amount lech DB -> 204 (ack de MoMo ngung retry —
#      mismatch la terminal), row initiated -> failed, commission van 0 (3 check)
#   5  zalopay callback co chu ky -> return_code 1 + booking paid (2 check)
#   6  zalopay sai mac            -> return_code -1, row van initiated (2 check)
#   7  webhook gateway la         -> 400
#   8  validate-iap khong JWT     -> 401
#   9  validate-iap JWT + receipt rac -> 503 (fail-closed khi thieu creds store)
#   10 create-venue-payment khong JWT -> 401; JWT + plan bao   -> 403 (2 check)
#   11 ingest-places anon-JWT khong secret -> 403
#   12 send-sms khong chu ky        -> 401 (Standard Webhooks gate)
#   13 send-sms tu ky dung          -> 503 (qua chu ky -> provider gate fail-closed)
#   14 send-sms tamper body         -> 401 (chu ky vo hieu)
#   15 push-fanout: env thieu -> 503 (fail-closed); env co -> sai secret -> 403
#
# YEU CAU TRUOC KHI CHAY
#   - Supabase local stack DANG CHAY (docker: supabase_db_cung-hat + edge runtime).
#   - supabase/functions/.env co MOMO_ACCESS_KEY, MOMO_SECRET_KEY, ZALOPAY_KEY2
#     (dummy) VA da duoc nap vao container. Nap env = `npx supabase stop &&
#     npx supabase start` sau khi ghi .env. `docker restart` chi nap lai CODE,
#     KHONG nap lai ENV -> neu preflight tra 503 la env chua vao container.
#   - Chay tren Git Bash (can openssl + curl).
#
# CHAY
#   bash scripts/verify_payments_local.sh
#   Ket qua cuoi: dong "PASS=n FAIL=m". Exit != 0 neu co bat ky FAIL nao.
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/supabase/functions/.env"
DEV_JSON="$REPO_ROOT/env/dev.json"
DB_CONTAINER="supabase_db_cung-hat"
BASE="http://127.0.0.1:54321/functions/v1"
AUTH_BASE="http://127.0.0.1:54321/auth/v1"
TEST_PHONE="+84900000001"
TEST_OTP="123456"

PASS_N=0
FAIL_N=0
RUN="verify-$(date +%s)-$$"

# --- helpers ----------------------------------------------------------------
die() { echo "ERROR: $*" >&2; exit 2; }

PSQL() { docker exec "$DB_CONTAINER" psql -U postgres -d postgres -t -A -c "$1"; }

# escape backslash roi dau nháy kép de nhung 1 chuoi JSON vao trong JSON khac
jesc() { local s=${1//\\/\\\\}; printf '%s' "${s//\"/\\\"}"; }

# lay return_code tu JSON body cua zalopay callback
rc_of() { printf '%s' "$1" | grep -o '"return_code":[-0-9]*' | head -1 | cut -d: -f2 || true; }

check() {
  local name="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    PASS_N=$((PASS_N + 1))
    printf 'PASS  %-46s want=%-6s got=%s\n' "$name" "$want" "$got"
  else
    FAIL_N=$((FAIL_N + 1))
    printf 'FAIL  %-46s want=%-6s got=%s\n' "$name" "$want" "$got"
  fi
}

http_code() { # http_code URL [extra curl args...]
  local url="$1"; shift
  curl -s -o /dev/null -w '%{http_code}' "$url" "$@"
}

cleanup() {
  docker exec "$DB_CONTAINER" psql -U postgres -d postgres -c \
    "delete from venue_bookings where gateway_ref like '${RUN}-%';" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# --- preflight --------------------------------------------------------------
command -v openssl >/dev/null 2>&1 || die "openssl khong co tren PATH (can Git Bash)."
command -v curl    >/dev/null 2>&1 || die "curl khong co tren PATH."
command -v xxd     >/dev/null 2>&1 || die "xxd khong co tren PATH (can Git Bash; can cho check send-sms)."
[ -f "$ENV_FILE" ] || die "Khong thay $ENV_FILE."
[ -f "$DEV_JSON" ] || die "Khong thay $DEV_JSON."
docker exec "$DB_CONTAINER" true 2>/dev/null || die "Container $DB_CONTAINER khong chay. Chay: npx supabase start"

read_env() { grep -E "^$1=" "$ENV_FILE" | head -1 | cut -d= -f2- || true; }
MOMO_ACCESS_KEY="$(read_env MOMO_ACCESS_KEY)"
MOMO_SECRET_KEY="$(read_env MOMO_SECRET_KEY)"
ZALOPAY_KEY2="$(read_env ZALOPAY_KEY2)"
SMS_SECRET_RAW="$(read_env SEND_SMS_HOOK_SECRET)"
[ -n "$MOMO_ACCESS_KEY" ] || die "Thieu MOMO_ACCESS_KEY trong $ENV_FILE. Them dummy roi: npx supabase stop && npx supabase start"
[ -n "$MOMO_SECRET_KEY" ] || die "Thieu MOMO_SECRET_KEY trong $ENV_FILE. Them dummy roi: npx supabase stop && npx supabase start"
[ -n "$ZALOPAY_KEY2" ]    || die "Thieu ZALOPAY_KEY2 trong $ENV_FILE. Them dummy roi: npx supabase stop && npx supabase start"
[ -n "$SMS_SECRET_RAW" ]  || die "Thieu SEND_SMS_HOOK_SECRET trong $ENV_FILE. Them dummy (whsec_<base64>) roi: npx supabase stop && npx supabase start"

ANON="$(grep -o '"SUPABASE_ANON_KEY"[[:space:]]*:[[:space:]]*"[^"]*"' "$DEV_JSON" | head -1 | cut -d'"' -f4 || true)"
[ -n "$ANON" ] || die "Khong doc duoc SUPABASE_ANON_KEY tu $DEV_JSON."

# env da nap vao container? momo webhook body rong: thieu secret -> 503, co secret -> 401.
PF_MOMO="$(http_code "$BASE/payments-webhook?gateway=momo" -X POST -H "apikey: $ANON" -H "Content-Type: application/json" -d '{}')"
[ "$PF_MOMO" != "503" ] || die "MOMO secrets chua nap vao edge runtime (503). Sau khi ghi .env phai: npx supabase stop && npx supabase start (docker restart KHONG nap env)."
PF_ZP="$(http_code "$BASE/payments-webhook?gateway=zalopay" -X POST -H "apikey: $ANON" -H "Content-Type: application/json" -d '{}')"
[ "$PF_ZP" != "503" ] || die "ZALOPAY_KEY2 chua nap vao edge runtime (503). Sau khi ghi .env phai: npx supabase stop && npx supabase start."

# JWT that qua GoTrue OTP flow
curl -s -o /dev/null -X POST "$AUTH_BASE/otp" -H "apikey: $ANON" -H "Content-Type: application/json" -d "{\"phone\":\"$TEST_PHONE\"}"
TOKEN="$(curl -s -X POST "$AUTH_BASE/verify" -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d "{\"type\":\"sms\",\"phone\":\"$TEST_PHONE\",\"token\":\"$TEST_OTP\"}" \
  | grep -o '"access_token":"[^"]*"' | head -1 | cut -d'"' -f4 || true)"
[ -n "$TOKEN" ] || die "Khong lay duoc access_token qua GoTrue (kiem tra auth container + test OTP)."

VENUE="$(PSQL "select id from venues where is_active=true limit 1;")"
[ -n "$VENUE" ] || die "Khong co venue is_active=true de seed booking / test create-venue-payment."

echo "=== verify_payments_local: run=$RUN venue=$VENUE ==="

# ---------------------------------------------------------------------------
# 1-4  MoMo IPN (1 booking, chay tuan tu tren cung 1 row)
# ---------------------------------------------------------------------------
REF_MOMO="${RUN}-momo"
PSQL "insert into venue_bookings (venue_id, amount_minor, gateway, gateway_ref, state) values ('$VENUE', 200000, 'momo', '$REF_MOMO', 'initiated');" >/dev/null
AMT="$(PSQL "select amount_minor from venue_bookings where gateway_ref='$REF_MOMO';")"

momo_sig() { # momo_sig <amount> -> chu ky HMAC theo chuoi ky IPN v2 (thu tu alphabet)
  local amt="$1"
  local raw="accessKey=${MOMO_ACCESS_KEY}&amount=${amt}&extraData=&message=Success&orderId=${REF_MOMO}&orderInfo=test&orderType=momo_wallet&partnerCode=PC&payType=qr&requestId=r1&responseTime=1&resultCode=0&transId=99"
  printf '%s' "$raw" | openssl dgst -sha256 -hmac "$MOMO_SECRET_KEY" -r | cut -d' ' -f1
}
momo_body() { # momo_body <amount> <signature>
  printf '{"amount":%s,"extraData":"","message":"Success","orderId":"%s","orderInfo":"test","orderType":"momo_wallet","partnerCode":"PC","payType":"qr","requestId":"r1","responseTime":1,"resultCode":0,"transId":99,"signature":"%s"}' "$1" "$REF_MOMO" "$2"
}

SIG="$(momo_sig "$AMT")"
BODY="$(momo_body "$AMT" "$SIG")"

# 1) IPN co chu ky -> 204
C="$(http_code "$BASE/payments-webhook?gateway=momo" -X POST -H "apikey: $ANON" -H "Content-Type: application/json" -d "$BODY")"
check "momo ipn signed -> 204" "204" "$C"

# 2) booking -> paid + hoa hong 10%
ST="$(PSQL "select state from venue_bookings where gateway_ref='$REF_MOMO';")"
COMM="$(PSQL "select coalesce(commission_minor,-1) from venue_bookings where gateway_ref='$REF_MOMO';")"
check "momo booking -> paid" "paid" "$ST"
check "momo commission 10%" "$((AMT / 10))" "$COMM"

# 3) replay -> 204 + state/commission KHONG doi
SNAP="$(PSQL "select state||'/'||coalesce(commission_minor::text,'null') from venue_bookings where gateway_ref='$REF_MOMO';")"
C="$(http_code "$BASE/payments-webhook?gateway=momo" -X POST -H "apikey: $ANON" -H "Content-Type: application/json" -d "$BODY")"
check "momo ipn replay -> 204" "204" "$C"
SNAP2="$(PSQL "select state||'/'||coalesce(commission_minor::text,'null') from venue_bookings where gateway_ref='$REF_MOMO';")"
check "momo replay state unchanged" "$SNAP" "$SNAP2"

# 4) sua amount, giu nguyen chu ky -> chu ky vo hieu -> 401 + state van paid
BODY_TAMPER="$(momo_body "$((AMT + 1))" "$SIG")"
C="$(http_code "$BASE/payments-webhook?gateway=momo" -X POST -H "apikey: $ANON" -H "Content-Type: application/json" -d "$BODY_TAMPER")"
check "momo ipn tampered amount -> 401" "401" "$C"
ST="$(PSQL "select state from venue_bookings where gateway_ref='$REF_MOMO';")"
check "momo tampered state still paid" "paid" "$ST"

# ---------------------------------------------------------------------------
# 4b  MoMo IPN KY DUNG nhung amount LECH so voi booking (reconciliation path):
#     chu ky verify OK (raw string dung amount lech) -> settle() phat hien
#     amount_mismatch -> row initiated -> failed, KHONG cap paid/commission.
#     HTTP van 204: theo contract MoMo, mismatch la terminal -> ack de MoMo
#     ngung retry (retry cung khong sua duoc lech tien).
# ---------------------------------------------------------------------------
REF_MM="${RUN}-momo-mm"
PSQL "insert into venue_bookings (venue_id, amount_minor, gateway, gateway_ref, state) values ('$VENUE', 200000, 'momo', '$REF_MM', 'initiated');" >/dev/null
AMT_MM="$(PSQL "select amount_minor from venue_bookings where gateway_ref='$REF_MM';")"
BAD_AMT="$((AMT_MM + 1))"
RAW_MM="accessKey=${MOMO_ACCESS_KEY}&amount=${BAD_AMT}&extraData=&message=Success&orderId=${REF_MM}&orderInfo=test&orderType=momo_wallet&partnerCode=PC&payType=qr&requestId=r1&responseTime=1&resultCode=0&transId=99"
SIG_MM="$(printf '%s' "$RAW_MM" | openssl dgst -sha256 -hmac "$MOMO_SECRET_KEY" -r | cut -d' ' -f1)"
BODY_MM="$(printf '{"amount":%s,"extraData":"","message":"Success","orderId":"%s","orderInfo":"test","orderType":"momo_wallet","partnerCode":"PC","payType":"qr","requestId":"r1","responseTime":1,"resultCode":0,"transId":99,"signature":"%s"}' "$BAD_AMT" "$REF_MM" "$SIG_MM")"
C="$(http_code "$BASE/payments-webhook?gateway=momo" -X POST -H "apikey: $ANON" -H "Content-Type: application/json" -d "$BODY_MM")"
check "momo signed amount-mismatch -> 204" "204" "$C"
ST="$(PSQL "select state from venue_bookings where gateway_ref='$REF_MM';")"
check "momo mismatch booking -> failed" "failed" "$ST"
COMM_MM="$(PSQL "select coalesce(commission_minor,-1) from venue_bookings where gateway_ref='$REF_MM';")"
check "momo mismatch commission stays 0" "0" "$COMM_MM"

# ---------------------------------------------------------------------------
# 5  ZaloPay callback co chu ky -> return_code 1 + paid
# ---------------------------------------------------------------------------
REF_ZP1="${RUN}-zp1"
PSQL "insert into venue_bookings (venue_id, amount_minor, gateway, gateway_ref, state) values ('$VENUE', 200000, 'zalopay', '$REF_ZP1', 'initiated');" >/dev/null
AMT2="$(PSQL "select amount_minor from venue_bookings where gateway_ref='$REF_ZP1';")"
DATA="$(printf '{"app_trans_id":"%s","amount":%s,"app_id":1}' "$REF_ZP1" "$AMT2")"
MAC="$(printf '%s' "$DATA" | openssl dgst -sha256 -hmac "$ZALOPAY_KEY2" -r | cut -d' ' -f1)"
BODY="$(printf '{"data":"%s","mac":"%s","type":1}' "$(jesc "$DATA")" "$MAC")"
RESP="$(curl -s -X POST "$BASE/payments-webhook?gateway=zalopay" -H "apikey: $ANON" -H "Content-Type: application/json" -d "$BODY")"
check "zalopay callback signed -> return_code 1" "1" "$(rc_of "$RESP")"
ST="$(PSQL "select state from venue_bookings where gateway_ref='$REF_ZP1';")"
check "zalopay booking -> paid" "paid" "$ST"

# ---------------------------------------------------------------------------
# 6  ZaloPay sai mac -> return_code -1, row van initiated
# ---------------------------------------------------------------------------
REF_ZP2="${RUN}-zp2"
PSQL "insert into venue_bookings (venue_id, amount_minor, gateway, gateway_ref, state) values ('$VENUE', 200000, 'zalopay', '$REF_ZP2', 'initiated');" >/dev/null
AMT3="$(PSQL "select amount_minor from venue_bookings where gateway_ref='$REF_ZP2';")"
DATA3="$(printf '{"app_trans_id":"%s","amount":%s,"app_id":1}' "$REF_ZP2" "$AMT3")"
BODY3="$(printf '{"data":"%s","mac":"%s","type":1}' "$(jesc "$DATA3")" "deadbeefbadmac0000")"
RESP="$(curl -s -X POST "$BASE/payments-webhook?gateway=zalopay" -H "apikey: $ANON" -H "Content-Type: application/json" -d "$BODY3")"
check "zalopay bad mac -> return_code -1" "-1" "$(rc_of "$RESP")"
ST="$(PSQL "select state from venue_bookings where gateway_ref='$REF_ZP2';")"
check "zalopay bad mac row stays initiated" "initiated" "$ST"

# ---------------------------------------------------------------------------
# 7  webhook gateway la -> 400
# ---------------------------------------------------------------------------
C="$(http_code "$BASE/payments-webhook?gateway=nope" -X POST -H "apikey: $ANON" -H "Content-Type: application/json" -d '{}')"
check "webhook unknown gateway -> 400" "400" "$C"

# ---------------------------------------------------------------------------
# 8-9  validate-iap
# ---------------------------------------------------------------------------
C="$(http_code "$BASE/validate-iap" -X POST -H "apikey: $ANON" -H "Content-Type: application/json" -d '{}')"
check "validate-iap no jwt -> 401" "401" "$C"

C="$(http_code "$BASE/validate-iap" -X POST -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"platform":"android","store_product_id":"boost","store_txn_id":"t1","receipt":"garbage"}')"
check "validate-iap jwt+garbage -> 503" "503" "$C"

# ---------------------------------------------------------------------------
# 10  create-venue-payment
# ---------------------------------------------------------------------------
C="$(http_code "$BASE/create-venue-payment" -X POST -H "apikey: $ANON" -H "Content-Type: application/json" -d '{}')"
check "create-venue-payment no jwt -> 401" "401" "$C"

# plan_id la UUID hop le NHUNG user test khong phai thanh vien keo nao -> RLS
# plans_member_read tra 0 row -> not_a_plan_member (403). venue_id la venue that.
BOGUS_PLAN="deadbeef-1111-4000-8000-000000000000"
C="$(http_code "$BASE/create-venue-payment" -X POST -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"plan_id\":\"$BOGUS_PLAN\",\"venue_id\":\"$VENUE\",\"gateway\":\"momo\"}")"
check "create-venue-payment jwt+bogus plan -> 403" "403" "$C"

# ---------------------------------------------------------------------------
# 11  ingest-places anon-jwt khong secret -> 403
# ---------------------------------------------------------------------------
C="$(http_code "$BASE/ingest-places-venues" -X POST -H "apikey: $ANON" -H "Authorization: Bearer $ANON" -H "Content-Type: application/json" -d '{}')"
check "ingest-places anon-jwt no secret -> 403" "403" "$C"

# ---------------------------------------------------------------------------
# 12  send-sms Standard Webhooks (AH-T8) + push-fanout fail-closed
#     send-sms verify_jwt=false: GoTrue goi khong kem JWT. Xac thuc = Standard
#     Webhooks signature. Chung minh verify chay: signed -> qua gate chu ky ->
#     503 (SMS_API_KEY absent local). unsigned/tampered -> 401.
# ---------------------------------------------------------------------------
# khong chu ky -> 401 (toi duoc function, gate chu ky chan)
check "send-sms unsigned -> 401" "401" "$(http_code "$BASE/send-sms" -X POST -H "Content-Type: application/json" -d '{}')"

# tu ky dung thuat toan Standard Webhooks: base64(HMAC-SHA256(id.ts.body, decode(secret)))
# SMS_SECRET_RAW da duoc die-gate o preflight; chap nhan ca 3 dang secret nhu function:
# v1,whsec_<b64> / whsec_<b64> / <b64> tran
SMS_SECRET_B64="${SMS_SECRET_RAW#v1,}"; SMS_SECRET_B64="${SMS_SECRET_B64#whsec_}"
KEYHEX="$(printf '%s' "$SMS_SECRET_B64" | base64 -d | xxd -p -c 256 | tr -d '\n')"
WID="msg_$(date +%s)"; WTS="$(date +%s)"
WBODY='{"user":{"phone":"+84900000009"},"sms":{"otp":"000000"}}'
WSIG="$(printf '%s' "${WID}.${WTS}.${WBODY}" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$KEYHEX" -binary | base64)"
C="$(http_code "$BASE/send-sms" -X POST -H "Content-Type: application/json" -H "webhook-id: $WID" -H "webhook-timestamp: $WTS" -H "webhook-signature: v1,$WSIG" -d "$WBODY")"
check "send-sms signed -> 503 (qua chu ky, provider gate)" "503" "$C"

# tamper body, giu nguyen chu ky -> 401 (chu ky vo hieu)
C="$(http_code "$BASE/send-sms" -X POST -H "Content-Type: application/json" -H "webhook-id: $WID" -H "webhook-timestamp: $WTS" -H "webhook-signature: v1,$WSIG" -d '{"user":{"phone":"+84999999999"},"sms":{"otp":"111111"}}')"
check "send-sms tampered -> 401" "401" "$C"

# push-fanout fail-closed: check HANH VI theo env that trong .env —
# thieu/rong PUSH_FANOUT_SECRET -> 503; co secret -> gui sai secret -> 403.
FANOUT_SECRET="$(read_env PUSH_FANOUT_SECRET)"
if [ -z "$FANOUT_SECRET" ]; then
  check "push-fanout thieu env -> 503" "503" "$(http_code "$BASE/push-fanout" -X POST -H "apikey: $ANON" -H "Authorization: Bearer $ANON" -H "Content-Type: application/json" -d '{}')"
else
  check "push-fanout sai secret -> 403" "403" "$(http_code "$BASE/push-fanout" -X POST -H "apikey: $ANON" -H "Authorization: Bearer $ANON" -H "x-fanout-secret: wrong-$RUN" -H "Content-Type: application/json" -d '{}')"
fi

# --- summary ----------------------------------------------------------------
cleanup
trap - EXIT
echo "----------------------------------------------------------------------"
echo "PASS=$PASS_N FAIL=$FAIL_N"
[ "$FAIL_N" -eq 0 ]
