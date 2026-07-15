#!/usr/bin/env python3
"""
count_music_box_density.py — Đếm mật độ "music box" (phòng hát mini tự phục vụ)
theo từng quận/khu bằng Google Places API (New), để chọn POCKET LAUNCH #1 cho Cùng Hát.

Bối cảnh: research market-fit (docs/research/2026-07-07-market-fit-research.md) chốt
launch 1 pocket dày music box trước, KHÔNG rải 3 thành phố. Script này biến việc "đoán"
thành dữ liệu thật, tái dùng đúng Places (New) mà edge function ingest-places-venues dùng.

⚠️ Music box KHÁC karaoke truyền thống → dùng TEXT SEARCH các cụm từ "music box"/"karaoke box"/
"phòng hát mini" (không phải chỉ type "karaoke", sẽ lẫn KTV to). Vẫn đếm thêm tổng "karaoke"
làm nền so sánh. Có heuristic lọc theo tên + gợi ý lọc thủ công (vụ "karaoke đội lốt music box").

CÁCH CHẠY (cần key Google Maps có BẬT BILLING + Places API New):
    # PowerShell:  $env:GOOGLE_PLACES_API_KEY="AIza..."; python scripts/count_music_box_density.py
    # bash:        GOOGLE_PLACES_API_KEY="AIza..." python scripts/count_music_box_density.py

Chỉ dùng stdlib (urllib) — không cần pip install.
"""

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

# ---------------------------------------------------------------------------
# CẤU HÌNH — sửa danh sách khu ứng viên ở đây (tên, tâm lat/lng, bán kính mét).
# Toạ độ gần đúng tâm quận; bán kính ~3.5km phủ 1 quận nội đô.
# ---------------------------------------------------------------------------
AREAS = [
    # Hà Nội — quận sinh viên (music box cụm ở đây, vd Cầu Giấy)
    {"name": "Cầu Giấy (HN)",   "lat": 21.0313, "lng": 105.7969, "radius_m": 3500},
    {"name": "Thanh Xuân (HN)", "lat": 20.9955, "lng": 105.8047, "radius_m": 3500},
    {"name": "Đống Đa (HN)",    "lat": 21.0182, "lng": 105.8272, "radius_m": 3500},
    # TP.HCM — quận trẻ/sinh viên
    {"name": "Thủ Đức (HCM)",   "lat": 10.8494, "lng": 106.7537, "radius_m": 4500},
    {"name": "Gò Vấp (HCM)",    "lat": 10.8386, "lng": 106.6655, "radius_m": 3500},
    {"name": "Quận 10 (HCM)",   "lat": 10.7731, "lng": 106.6672, "radius_m": 2500},
    # Phương án B — ao trẻ gọn (Samsung 33k + đại học)
    {"name": "TP Thái Nguyên",  "lat": 21.5928, "lng": 105.8442, "radius_m": 5000},
]

# Truy vấn text tìm music box (union kết quả, dedupe theo place id)
MUSIC_BOX_QUERIES = ["music box", "karaoke box", "phòng hát mini", "musicbox"]

# Heuristic: tên phải khớp 1 trong các pattern này mới tính là "music box"
# (giảm nhiễu KTV truyền thống lọt vào kết quả text search).
MUSIC_BOX_NAME_RE = re.compile(
    r"music\s*box|karaoke\s*box|phòng hát mini|mini\s*karaoke|\bbox\b",
    re.IGNORECASE,
)

FIELD_MASK = (
    "places.id,places.displayName,places.formattedAddress,"
    "places.location,places.userRatingCount,nextPageToken"
)
SEARCH_TEXT_URL = "https://places.googleapis.com/v1/places:searchText"
PAGE_SIZE = 20          # tối đa 20/trang (Places New)
MAX_PAGES = 3           # tối đa 60 kết quả/truy vấn
OUT_JSON = Path(__file__).resolve().parent.parent / "docs" / "research" / "music_box_density.json"


def _post(api_key: str, body: dict) -> dict:
    req = urllib.request.Request(
        SEARCH_TEXT_URL,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "X-Goog-Api-Key": api_key,
            "X-Goog-FieldMask": FIELD_MASK,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")[:400]
        raise SystemExit(f"[Places HTTP {e.code}] {detail}")


def search_text(api_key: str, query: str, area: dict) -> list[dict]:
    """Text search có locationBias theo khu, phân trang tới MAX_PAGES."""
    out, page_token = [], None
    for _ in range(MAX_PAGES):
        body = {
            "textQuery": query,
            "pageSize": PAGE_SIZE,
            "locationBias": {
                "circle": {
                    "center": {"latitude": area["lat"], "longitude": area["lng"]},
                    "radius": float(area["radius_m"]),
                }
            },
        }
        if page_token:
            body["pageToken"] = page_token
        data = _post(api_key, body)
        out.extend(data.get("places", []) or [])
        page_token = data.get("nextPageToken")
        if not page_token:
            break
        time.sleep(1.2)  # token cần 1 nhịp để hợp lệ + tránh rate limit
    return out


def collect_area(api_key: str, area: dict) -> dict:
    seen: dict[str, dict] = {}      # id -> place (dedupe qua các query)
    for q in MUSIC_BOX_QUERIES:
        for p in search_text(api_key, q, area):
            pid = p.get("id")
            if pid and pid not in seen:
                seen[pid] = p
        time.sleep(0.4)

    # Lọc theo tên để loại KTV truyền thống lọt vào
    music_boxes = []
    for p in seen.values():
        name = (p.get("displayName", {}) or {}).get("text", "")
        if MUSIC_BOX_NAME_RE.search(name):
            music_boxes.append({
                "name": name,
                "address": p.get("formattedAddress", ""),
                "ratings": p.get("userRatingCount", 0),
            })

    music_boxes.sort(key=lambda x: x["ratings"], reverse=True)
    return {
        "area": area["name"],
        "raw_hits": len(seen),          # tổng kết quả text search (trước lọc tên)
        "music_box_count": len(music_boxes),
        "venues": music_boxes,
    }


def main() -> None:
    api_key = os.environ.get("GOOGLE_PLACES_API_KEY")
    if not api_key:
        sys.exit("Thiếu GOOGLE_PLACES_API_KEY (key Google Maps có bật billing + Places API New).")

    results = []
    for area in AREAS:
        print(f"→ Đang quét: {area['name']} ...", flush=True)
        try:
            results.append(collect_area(api_key, area))
        except SystemExit as e:
            print(f"  !! {e}", flush=True)
            raise

    results.sort(key=lambda r: r["music_box_count"], reverse=True)

    print("\n===== XẾP HẠNG MẬT ĐỘ MUSIC BOX (đã lọc tên) =====")
    print(f"{'Khu':<20}{'music_box':>10}{'raw_hits':>10}")
    for r in results:
        print(f"{r['area']:<20}{r['music_box_count']:>10}{r['raw_hits']:>10}")
    if results:
        top = results[0]
        print(f"\n>>> POCKET #1 gợi ý: {top['area']} ({top['music_box_count']} music box)")
        print("    (Kiểm mắt danh sách trong JSON — lọc thủ công vụ 'karaoke đội lốt music box'.)")

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nĐã ghi chi tiết: {OUT_JSON}")


if __name__ == "__main__":
    main()
