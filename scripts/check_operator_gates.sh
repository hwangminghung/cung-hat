#!/usr/bin/env bash
# Kiem tra trang thai cac operator gate (xem docs/superpowers/plans/2026-07-26-operator-gates.md).
#
# TRA LOI DUOC: "cai gi da duoc CAM DAY, cai gi chua" — doc file/manifest/env.
# KHONG TRA LOI DUOC: "key co that su hoat dong khong" — cai do phai chay phep
# thu end-to-end trong plan (mua sandbox, nhan push, nhan SMS). Script nay chi
# loai bo nhom loi "tuong da cau hinh roi".
#
# Dung:
#   bash scripts/check_operator_gates.sh                 # chi doc repo
#   ENV_FILE=supabase/functions/.env bash scripts/...    # doc them secret da cam
#
# Exit 0 luon luon: day la bao cao trang thai, khong phai cong CI.

set -uo pipefail
cd "$(dirname "$0")/.."

ENV_FILE="${ENV_FILE:-supabase/functions/.env}"

pass() { printf '  \033[32mOK\033[0m    %s\n' "$1"; }
miss() { printf '  \033[33m--\033[0m    %s\n' "$1"; }
warn() { printf '  \033[31mSAI\033[0m   %s\n' "$1"; }
head2() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# Doc bien tu ENV_FILE (khong source de tranh chay code la trong file env).
envval() {
  [ -f "$ENV_FILE" ] || return 1
  local v
  v=$(grep -E "^$1=" "$ENV_FILE" | tail -1 | cut -d= -f2-)
  [ -n "$v" ] && printf '%s' "$v"
}

envcheck() { # ten_bien "mo ta"
  if envval "$1" >/dev/null; then pass "$1 — $2"; else miss "$1 — $2"; fi
}

printf '\033[1mTrang thai operator gates\033[0m  (env: %s)\n' \
  "$([ -f "$ENV_FILE" ] && echo "$ENV_FILE" || echo 'KHONG CO — chi kiem tra phan trong repo')"

head2 'G1 — SMS that (chan moi thu)'
if grep -qE '^\s*\[auth\.sms\.test_otp\]' supabase/config.toml 2>/dev/null &&
   grep -qE '^\s*8490[0-9]+\s*=' supabase/config.toml 2>/dev/null; then
  warn "test_otp con bat trong config.toml — chi so hard-code moi dang nhap duoc"
else
  pass 'test_otp da tat'
fi
if grep -qE '^\s*enabled\s*=\s*true' <(sed -n '/\[auth.hook.send_sms\]/,/^\[/p' supabase/config.toml 2>/dev/null); then
  pass 'hook send_sms da bat'
else
  miss 'hook send_sms chua bat (config.toml)'
fi
envcheck SEND_SMS_HOOK_SECRET 'chu ky Standard Webhooks tu GoTrue'
envcheck SMS_PROVIDER "ten provider ('esms' | 'twilio')"
envcheck SMS_API_KEY 'api key provider'
case "$(envval SMS_PROVIDER || true)" in
  esms)   envcheck ESMS_SECRET_KEY 'eSMS secret'; envcheck SMS_BRANDNAME 'brandname DA DUOC DUYET' ;;
  twilio) envcheck TWILIO_ACCOUNT_SID 'twilio sid'; envcheck TWILIO_FROM 'so gui' ;;
esac

head2 'G2/G3 — Store + IAP'
appid=$(grep -oE 'applicationId\s*=\s*"[^"]+"' android/app/build.gradle.kts 2>/dev/null | head -1 | cut -d'"' -f2)
if [ -n "${appid:-}" ]; then
  case "$appid" in
    dev.*|*.dev|com.example.*) warn "applicationId van la id DEV: $appid — chot id that TRUOC khi tao app record (Play khong cho doi sau khi publish)" ;;
    *) pass "applicationId: $appid" ;;
  esac
fi
envcheck APP_BUNDLE_ID 'bundle id iOS'
envcheck ANDROID_PACKAGE_NAME 'package name Android'
envcheck APPLE_SHARED_SECRET 'App-Specific Shared Secret'
envcheck GOOGLE_PLAY_SA_JSON 'service account Play'
appleenv=$(envval APPLE_ENVIRONMENT || echo '')
if [ "$appleenv" = "Production" ] && ! envval APPLE_APP_APPLE_ID >/dev/null; then
  warn 'APPLE_ENVIRONMENT=Production nhung thieu APPLE_APP_APPLE_ID (validate-iap se tu choi)'
fi

head2 'G4 — FCM push / Analytics'
[ -f android/app/google-services.json ] && pass 'android/app/google-services.json' \
  || miss 'android/app/google-services.json (thieu -> push VA analytics deu no-op)'
[ -f ios/Runner/GoogleService-Info.plist ] && pass 'ios/Runner/GoogleService-Info.plist' \
  || miss 'ios/Runner/GoogleService-Info.plist'
envcheck GOOGLE_FCM_SA_JSON 'service account FCM (thieu -> push-fanout chay dry-run)'
envcheck PUSH_FANOUT_SECRET 'secret goi push-fanout'

head2 'G5 — Google Maps'
grep -q 'MAPS_API_KEY' android/app/src/main/AndroidManifest.xml 2>/dev/null \
  && pass 'manifest da co placeholder MAPS_API_KEY' || warn 'manifest thieu MAPS_API_KEY'
if grep -qE '^\s*MAPS_API_KEY=' android/local.properties 2>/dev/null; then
  pass 'MAPS_API_KEY trong android/local.properties'
else
  miss 'MAPS_API_KEY chua cam (local.properties / gradle property / env)'
fi
envcheck GOOGLE_PLACES_API_KEY 'key Places API (New), can BAT BILLING'
printf '  \033[36mi\033[0m     GOOGLE_MAPS_ENABLED la dart-define luc build — map that CHUA TUNG chay:\n'
printf '        flutter build apk --dart-define=GOOGLE_MAPS_ENABLED=true\n'

head2 'G6 — Deep link cunghat://'
grep -q 'android:scheme="cunghat"' android/app/src/main/AndroidManifest.xml 2>/dev/null \
  && pass 'AndroidManifest co intent-filter cunghat' || warn 'AndroidManifest THIEU intent-filter -> link share khong mo duoc app'
grep -q 'CFBundleURLSchemes' ios/Runner/Info.plist 2>/dev/null \
  && pass 'Info.plist co CFBundleURLTypes' || warn 'Info.plist THIEU CFBundleURLTypes'
grep -q 'singleTop' android/app/src/main/AndroidManifest.xml 2>/dev/null \
  && pass 'launchMode=singleTop (link toi khi app dang chay khong nhan ban activity)' \
  || warn 'thieu singleTop — link warm path se dung them ban sao man hinh'

head2 'G7 — MoMo/ZaloPay  (HOAN, khong thuoc v1)'
printf '  \033[36mi\033[0m     Theo QD payments-v1: hang so bat buoc IAP, coc quan hoan v1.5.\n'
printf '        Khong can cam gi o dot nay.\n'

head2 'Cong pre-submission (STORE_SUBMISSION §11)'
printf '  Chay tay khi chuan bi release:\n'
printf '    npx supabase db reset && npx supabase test db\n'
printf '    flutter analyze && flutter test\n'
printf '    deno check supabase/functions/*/index.ts && deno test supabase/functions/_shared/\n'

printf '\n\033[1mNho:\033[0m "cam day" chua phai "chay duoc". Moi gate co phep thu\n'
printf 'end-to-end rieng trong docs/superpowers/plans/2026-07-26-operator-gates.md\n'
