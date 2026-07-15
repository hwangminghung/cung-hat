#!/usr/bin/env python3
"""
count_music_box_density_osm.py — Đếm mật độ music box / karaoke theo quận bằng
OpenStreetMap Overpass API (MIỄN PHÍ, không cần API key / billing).

Bản thay thế cho count_music_box_density.py (Google Places) khi không muốn/không thể
set up Google Maps billing (vd tài khoản vướng luật Maps-billing-riêng của India).

⚠️ HẠN CHẾ: OSM ở VN map thưa hơn Google — nhiều music box nhỏ CHƯA được đánh dấu.
Con số tuyệt đối sẽ THẤP hơn thực tế; dùng để xếp hạng TƯƠNG ĐỐI giữa các quận, không
phải kiểm kê đầy đủ. Muốn số chính xác + tên quán thật → dùng bản Google Places.

CHẠY (không cần gì thêm, chỉ stdlib):
    python scripts/count_music_box_density_osm.py
"""

import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

# Cùng danh sách khu với bản Google để so sánh được.
AREAS = [
    {"name": "Cầu Giấy (HN)",   "lat": 21.0313, "lng": 105.7969, "radius_m": 3500},
    {"name": "Thanh Xuân (HN)", "lat": 20.9955, "lng": 105.8047, "radius_m": 3500},
    {"name": "Đống Đa (HN)",    "lat": 21.0182, "lng": 105.8272, "radius_m": 3500},
    {"name": "Thủ Đức (HCM)",   "lat": 10.8494, "lng": 106.7537, "radius_m": 4500},
    {"name": "Gò Vấp (HCM)",    "lat": 10.8386, "lng": 106.6655, "radius_m": 3500},
    {"name": "Quận 10 (HCM)",   "lat": 10.7731, "lng": 106.6672, "radius_m": 2500},
    {"name": "TP Thái Nguyên",  "lat": 21.5928, "lng": 105.8442, "radius_m": 5000},
]

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
# Tên chứa 1 trong các từ này thì coi là điểm hát (karaoke/music box/KTV)
NAME_FILTER = "music.?box|karaoke|ktv|phòng hát"
# Trong số đó, tên khớp cái này thì tính là "music box" (kiểu mini/tự phục vụ)
MUSIC_BOX_RE = re.compile(r"music\s*box|karaoke\s*box|\bbox\b|mini", re.IGNORECASE)
OUT_JSON = Path(__file__).resolve().parent.parent / "docs" / "research" / "music_box_density_osm.json"


def query_area(area: dict) -> list[dict]:
    q = (
        f'[out:json][timeout:60];'
        f'nwr(around:{area["radius_m"]},{area["lat"]},{area["lng"]})'
        f'["name"~"{NAME_FILTER}",i];'
        f'out center tags;'
    )
    body = urllib.parse.urlencode({"data": q}).encode("utf-8")
    req = urllib.request.Request(
        OVERPASS_URL, data=body,
        headers={"User-Agent": "cunghat-density-research/1.0"},
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read().decode("utf-8")).get("elements", [])


def collect(area: dict) -> dict:
    elements = query_area(area)
    seen, all_hits, music_boxes = set(), [], []
    for el in elements:
        name = (el.get("tags") or {}).get("name")
        if not name:
            continue
        key = name.strip().lower()
        if key in seen:          # dedupe node/way trùng tên
            continue
        seen.add(key)
        all_hits.append(name)
        if MUSIC_BOX_RE.search(name):
            music_boxes.append(name)
    return {
        "area": area["name"],
        "karaoke_total": len(all_hits),
        "music_box_count": len(music_boxes),
        "music_box_names": sorted(music_boxes),
        "all_names": sorted(all_hits),
    }


def main() -> None:
    results = []
    for area in AREAS:
        print(f"→ Đang quét (OSM): {area['name']} ...", flush=True)
        try:
            results.append(collect(area))
        except Exception as e:
            print(f"  !! lỗi {area['name']}: {e}", flush=True)
            results.append({"area": area["name"], "karaoke_total": -1, "music_box_count": -1,
                            "music_box_names": [], "all_names": []})
        time.sleep(2)  # lịch sự với Overpass public

    ranked = sorted(results, key=lambda r: (r["music_box_count"], r["karaoke_total"]), reverse=True)
    print("\n===== XẾP HẠNG (OSM — tương đối, dữ liệu thưa) =====")
    print(f"{'Khu':<20}{'music_box':>10}{'karaoke_tổng':>14}")
    for r in ranked:
        print(f"{r['area']:<20}{r['music_box_count']:>10}{r['karaoke_total']:>14}")

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(ranked, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nĐã ghi: {OUT_JSON}")
    print("Lưu ý: OSM map thưa — coi đây là xếp hạng tương đối, không phải kiểm kê đủ.")


if __name__ == "__main__":
    main()
