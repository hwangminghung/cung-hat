# Maps + Payments Real Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thay mọi placeholder Maps/Payments bằng tích hợp thật: midpoint pin + iOS key wiring cho Google Maps, verify receipt IAP thật (Apple/Google), create-order + webhook HMAC thật (MoMo/ZaloPay), server quyết tiền cọc — tất cả fail-closed khi thiếu credential.

**Architecture:** DB trước (RPC midpoint, cột deposit, RPC catalog) → Flutter (map pin, booking sheet, IAP catalog) → Edge functions (crypto thật, module `_shared/`) → harness verify self-signed. Spec: `docs/superpowers/specs/2026-07-07-maps-payments-design.md`.

**Tech Stack:** Flutter 3.44/Riverpod 3.3 (manual providers, KHÔNG codegen), Supabase (Postgres+PostGIS, pgTAP, Deno edge functions), google_maps_flutter 2.17, Web Crypto HMAC/RS256, npm:@apple/app-store-server-library.

---

## MÔI TRƯỜNG (đọc trước khi làm bất kỳ task nào)

- Làm trong worktree `C:\Users\Hwang Ming Hung\cung-hat-photos-wt`, nhánh `feat/maps-payments`. KHÔNG đụng root checkout.
- Flutter: `C:\Users\Public\flutter\bin\flutter.bat` (home path có space). Test: `flutter.bat test`, analyze: `flutter.bat analyze`.
- Supabase: `npx supabase migration up` (TUYỆT ĐỐI KHÔNG `db reset`). pgTAP: `npx supabase test db` — PHẢI 100% pass (không còn fail "pre-existing").
- psql: `docker exec supabase_db_cung-hat psql -U postgres -d postgres -c "..."`. SQL có tiếng Việt: nạp qua STDIN `docker exec -i -e PGCLIENTENCODING=UTF8 supabase_db_cung-hat psql -U postgres -d postgres < file.sql` (KHÔNG docker cp).
- Edge runtime local hay DOWN → `npx supabase start` bật lại. Trước khi start: `$env:SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN='localdummytoken'` (PowerShell) hoặc `export SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN=localdummytoken` (Bash). Edge functions được stack local serve ở `http://127.0.0.1:54321/functions/v1/<name>`, env đọc từ `supabase/functions/.env` (git-ignored); đổi env → `docker restart supabase_edge_runtime_cung-hat`.
- pgTAP `throws_ok` tham số 2 = SQLSTATE 5 ký tự (`'23514'`), KHÔNG phải tên lỗi.
- Dưới `search_path=''` mọi hàm PostGIS phải qualify `public.*`; KHÔNG dùng operator KNN `<->`.
- Mock harness Flutter: `test/support/supabase_mocks.dart` — `rpcOk(value)` cho `client.rpc`, KHÔNG `thenAnswer((_) async => ...)` cho builder. Riverpod dùng provider THỦ CÔNG.
- Widget test cho screen đụng Supabase: override provider trong ProviderScope.
- Commit: subject ASCII, kết thúc body bằng `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- KHÔNG chạy build_runner trừ khi task cần codegen; `git checkout --` file .freezed/.g nếu chỉ đổi line-ending.

---

### Task 1: RPC `get_keo_midpoint` (DB)

**Files:**
- Create: `supabase/migrations/20260707180000_keo_midpoint.sql`
- Test: `supabase/tests/keo_midpoint_test.sql`

- [ ] **Step 1: Viết pgTAP test (fail trước)**

```sql
-- supabase/tests/keo_midpoint_test.sql
-- Run with: supabase test db
-- Proves migration 20260707180000: get_keo_midpoint — in_keo gate, snap 3 decimals,
-- empty set when members have no locations. Seed pattern copied from plans_test.sql.
begin;
select plan(5);

select ok(exists(select 1 from pg_proc where proname='get_keo_midpoint'), 'get_keo_midpoint exists');

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000e1'),  -- host
  ('00000000-0000-0000-0000-0000000000e2'),  -- member
  ('00000000-0000-0000-0000-0000000000e3')   -- outsider
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000e1', 'Mid Host', '1990-01-01'),
  ('00000000-0000-0000-0000-0000000000e2', 'Mid Member', '1991-01-01'),
  ('00000000-0000-0000-0000-0000000000e3', 'Mid Outsider', '1992-01-01')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000e1', 'pro', 'promo')
  on conflict do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
create temp table _mid_keo (id uuid);
insert into _mid_keo
select public.create_keo(
  'Midpoint KEO', 21.028000, 105.854000, 'HN',
  now() + interval '1 day', now() + interval '1 day 2 hours',
  4, null, null, array[]::text[], 'approval');

-- 1) chua ai co vi tri -> tra 0 dong (khong loi).
select is(
  (select count(*) from public.get_keo_midpoint((select id from _mid_keo)))::int,
  0, 'khong co vi tri thanh vien -> 0 dong');

-- seed vi tri: ca 2 thanh vien CUNG toa do -> median = chinh toa do do (deterministic).
set local role postgres;
insert into public.keo_members (keo_id, user_id, join_status, confirmed) values
  ((select id from _mid_keo), '00000000-0000-0000-0000-0000000000e2', 'approved', true)
  on conflict do nothing;
insert into public.user_locations (user_id, location) values
  ('00000000-0000-0000-0000-0000000000e1', ST_SetSRID(ST_MakePoint(105.854, 21.028), 4326)::geography),
  ('00000000-0000-0000-0000-0000000000e2', ST_SetSRID(ST_MakePoint(105.854, 21.028), 4326)::geography)
  on conflict (user_id) do update set location = excluded.location;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;

-- 2) midpoint = toa do chung, da round 3 chu so le.
select results_eq(
  $$ select lat, lng from public.get_keo_midpoint((select id from _mid_keo)) $$,
  $$ values (21.028::double precision, 105.854::double precision) $$,
  'midpoint = toa do chung, round 3 decimals');

-- 3) khong lo toa do tho: round(,3) cua gia tri tra ve phai bang chinh no
-- (so sanh qua numeric de ne floating-point, KHONG dung floor(x*1000)).
select ok(
  (select round(lat::numeric, 3)::double precision = lat
      and round(lng::numeric, 3)::double precision = lng
     from public.get_keo_midpoint((select id from _mid_keo))),
  'lat/lng snap luoi 0.001');

-- 4) nguoi ngoai keo -> check_violation.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e3"}';
select throws_ok(
  $$ select * from public.get_keo_midpoint((select id from _mid_keo)) $$,
  '23514', 'not_in_keo', 'outsider bi chan boi in_keo gate');

select * from finish();
rollback;
```

- [ ] **Step 2: Chạy để thấy fail**

Run: `npx supabase test db`
Expected: `keo_midpoint_test` FAIL ("get_keo_midpoint exists" not ok).

- [ ] **Step 3: Viết migration**

```sql
-- supabase/migrations/20260707180000_keo_midpoint.sql
-- Midpoint da tinh cua nhom (ST_GeometricMedian) cho map PlanScreen.
-- RIENG TU: chi tra diem giua da snap round(,3) ~110m — cung muc snap voi
-- user_locations luc ghi; KHONG BAO GIO tra vi tri tung thanh vien.
create or replace function public.get_keo_midpoint(p_keo uuid)
returns table (lat double precision, lng double precision)
language plpgsql
security definer
set search_path=''
as $$
declare
  mid public.geometry;
begin
  if not app_private.in_keo(p_keo) then
    raise exception 'not_in_keo' using errcode='check_violation';
  end if;

  select public.ST_GeometricMedian(public.ST_Collect(ul.location::public.geometry))
    into mid
  from public.keo_members m
  join public.user_locations ul on ul.user_id = m.user_id
  where m.keo_id = p_keo
    and m.join_status = 'approved'
    and m.confirmed;

  if mid is null then
    return;
  end if;

  return query select
    round(public.ST_Y(mid)::numeric, 3)::double precision,
    round(public.ST_X(mid)::numeric, 3)::double precision;
end;
$$;
```

- [ ] **Step 4: Apply migration + test pass**

Run: `npx supabase migration up` rồi `npx supabase test db`
Expected: tất cả pgTAP PASS (kể cả 5/5 của keo_midpoint_test).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260707180000_keo_midpoint.sql supabase/tests/keo_midpoint_test.sql
git commit -m "feat(plan): RPC get_keo_midpoint - diem giua nhom da snap cho map"
```

---

### Task 2: `PlanRepository.getKeoMidpoint` + provider

**Files:**
- Modify: `lib/features/plan/data/plan_repository.dart` (thêm class MapPoint + method)
- Modify: `lib/features/plan/application/plan_providers.dart`
- Test: `test/features/plan/plan_repository_test.dart` (thêm group)

- [ ] **Step 1: Viết test fail**

Thêm vào `test/features/plan/plan_repository_test.dart` (theo pattern rpcOk sẵn trong file):

```dart
group('getKeoMidpoint', () {
  test('tra MapPoint khi RPC co dong', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_keo_midpoint', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk([
              {'lat': 21.028, 'lng': 105.854}
            ]));
    final mid = await PlanRepository(client).getKeoMidpoint('k1');
    expect(mid, isNotNull);
    expect(mid!.lat, 21.028);
    expect(mid.lng, 105.854);
  });

  test('tra null khi RPC rong (chua ai co vi tri)', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_keo_midpoint', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk(<dynamic>[]));
    expect(await PlanRepository(client).getKeoMidpoint('k1'), isNull);
  });
});
```

- [ ] **Step 2: Chạy fail**

Run: `flutter.bat test test/features/plan/plan_repository_test.dart`
Expected: COMPILE ERROR (getKeoMidpoint chưa tồn tại).

- [ ] **Step 3: Implement**

Trong `plan_repository.dart`, thêm (cạnh class Plan plain-class sẵn có):

```dart
/// Diem giua nhom da duoc server tinh va snap (~110m). KHONG phai vi tri thanh vien.
class MapPoint {
  const MapPoint({required this.lat, required this.lng});
  final double lat;
  final double lng;
}
```

và method trong `PlanRepository`:

```dart
Future<MapPoint?> getKeoMidpoint(String keoId) async {
  final rows =
      await _client.rpc('get_keo_midpoint', params: {'p_keo': keoId}) as List<dynamic>;
  if (rows.isEmpty) return null;
  final m = rows.first as Map<String, dynamic>;
  final lat = (m['lat'] as num?)?.toDouble();
  final lng = (m['lng'] as num?)?.toDouble();
  if (lat == null || lng == null) return null;
  return MapPoint(lat: lat, lng: lng);
}
```

Trong `plan_providers.dart` thêm:

```dart
final keoMidpointProvider = FutureProvider.family<MapPoint?, String>(
    (ref, keoId) => ref.watch(planRepositoryProvider).getKeoMidpoint(keoId));
```

- [ ] **Step 4: Test pass + analyze**

Run: `flutter.bat test test/features/plan/plan_repository_test.dart && flutter.bat analyze`
Expected: PASS, analyze sạch.

- [ ] **Step 5: Commit**

```bash
git add lib/features/plan/data/plan_repository.dart lib/features/plan/application/plan_providers.dart test/features/plan/plan_repository_test.dart
git commit -m "feat(plan): getKeoMidpoint repository + keoMidpointProvider"
```

---

### Task 3: Midpoint pin trên `VenueMapSurface` + wiring PlanScreen

**Files:**
- Modify: `lib/features/plan/presentation/venue_map_surface.dart`
- Modify: `lib/features/plan/presentation/plan_screen.dart`
- Modify: `test/features/plan/plan_screen_test.dart` (override provider mới)
- Test: Create `test/features/plan/venue_map_surface_test.dart`

- [ ] **Step 1: Viết widget test fail**

```dart
// test/features/plan/venue_map_surface_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/domain/venue_suggestion.dart';
import 'package:cung_hat/features/plan/presentation/venue_map_surface.dart';

VenueSuggestion _venue(String id, double lat, double lng) => VenueSuggestion(
    id: id, name: 'V$id', address: 'A', styleTag: 'k_style',
    photos: const [], distanceBand: '<1', lat: lat, lng: lng);

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('fallback ve pin midpoint khi co midpoint', (tester) async {
    await tester.pumpWidget(wrap(VenueMapSurface(
      venues: [_venue('v1', 21.02, 105.85), _venue('v2', 21.04, 105.86)],
      midpoint: const MapPoint(lat: 21.03, lng: 105.855),
      useNativeMap: false,
      onVenueSelected: (_) {},
    )));
    expect(find.byKey(const Key('midpoint_marker')), findsOneWidget);
    expect(find.byKey(const Key('venue_marker_v1')), findsOneWidget);
  });

  testWidgets('khong co midpoint -> khong co pin midpoint', (tester) async {
    await tester.pumpWidget(wrap(VenueMapSurface(
      venues: [_venue('v1', 21.02, 105.85)],
      useNativeMap: false,
      onVenueSelected: (_) {},
    )));
    expect(find.byKey(const Key('midpoint_marker')), findsNothing);
  });

  testWidgets('venues rong + co midpoint -> van ve midpoint', (tester) async {
    await tester.pumpWidget(wrap(VenueMapSurface(
      venues: const [],
      midpoint: const MapPoint(lat: 21.03, lng: 105.855),
      useNativeMap: false,
      onVenueSelected: (_) {},
    )));
    expect(find.byKey(const Key('midpoint_marker')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy fail**

Run: `flutter.bat test test/features/plan/venue_map_surface_test.dart`
Expected: COMPILE ERROR (param `midpoint` chưa có).

- [ ] **Step 3: Implement `venue_map_surface.dart`**

Thay đổi chính (giữ nguyên phần không nhắc tới):

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/plan_repository.dart' show MapPoint;
import '../domain/venue_suggestion.dart';

const _googleMapsEnabled = bool.fromEnvironment('GOOGLE_MAPS_ENABLED');

class VenueMapSurface extends StatelessWidget {
  const VenueMapSurface({
    super.key,
    required this.venues,
    required this.onVenueSelected,
    this.midpoint,
    this.useNativeMap = true,
  });

  final List<VenueSuggestion> venues;
  final ValueChanged<VenueSuggestion> onVenueSelected;
  final MapPoint? midpoint;
  final bool useNativeMap;

  List<VenueSuggestion> get _mappable =>
      venues.where((v) => v.lat != null && v.lng != null).toList();

  @override
  Widget build(BuildContext context) {
    final mappable = _mappable;
    final hasAnything = mappable.isNotEmpty || midpoint != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          key: const Key('venue_map_surface'),
          height: 220,
          child: !hasAnything
              ? _MapFallback(
                  venues: const [], midpoint: null, onVenueSelected: onVenueSelected)
              : useNativeMap && _googleMapsEnabled
              ? _NativeVenueMap(
                  venues: mappable,
                  midpoint: midpoint,
                  onVenueSelected: onVenueSelected,
                )
              : _MapFallback(
                  venues: mappable,
                  midpoint: midpoint,
                  onVenueSelected: onVenueSelected,
                ),
        ),
      ),
    );
  }
}
```

`_NativeVenueMap` — thêm midpoint marker + fit bounds:

```dart
class _NativeVenueMap extends StatelessWidget {
  const _NativeVenueMap({
    required this.venues,
    required this.midpoint,
    required this.onVenueSelected,
  });

  final List<VenueSuggestion> venues;
  final MapPoint? midpoint;
  final ValueChanged<VenueSuggestion> onVenueSelected;

  List<LatLng> get _allPoints => [
        for (final v in venues) LatLng(v.lat!, v.lng!),
        if (midpoint != null) LatLng(midpoint!.lat, midpoint!.lng),
      ];

  LatLng get _center {
    final pts = _allPoints;
    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lng = pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return LatLng(lat, lng);
  }

  LatLngBounds _bounds(List<LatLng> pts) {
    var minLat = pts.first.latitude, maxLat = pts.first.latitude;
    var minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    return LatLngBounds(
        southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  @override
  Widget build(BuildContext context) {
    final pts = _allPoints;
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: pts.length == 1 ? 14 : 12,
      ),
      onMapCreated: (controller) {
        if (pts.length >= 2) {
          controller.animateCamera(
              CameraUpdate.newLatLngBounds(_bounds(pts), 44));
        }
      },
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: {
        for (final venue in venues)
          Marker(
            markerId: MarkerId(venue.id),
            position: LatLng(venue.lat!, venue.lng!),
            infoWindow: InfoWindow(title: venue.name, snippet: venue.address),
            onTap: () => onVenueSelected(venue),
          ),
        if (midpoint != null)
          Marker(
            markerId: const MarkerId('midpoint'),
            position: LatLng(midpoint!.lat, midpoint!.lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            infoWindow: const InfoWindow(title: 'Điểm giữa nhóm'),
          ),
      },
    );
  }
}
```

`_MapFallback` — tính bounds MỘT LẦN trên venues + midpoint, truyền xuống marker (bỏ recompute per-marker trong `_PositionedVenueMarker`), và vẽ chấm midpoint:

```dart
class _MapFallback extends StatelessWidget {
  const _MapFallback({
    required this.venues,
    required this.midpoint,
    required this.onVenueSelected,
  });

  final List<VenueSuggestion> venues;
  final MapPoint? midpoint;
  final ValueChanged<VenueSuggestion> onVenueSelected;

  @override
  Widget build(BuildContext context) {
    final mappable =
        venues.where((v) => v.lat != null && v.lng != null).toList();
    final lats = [
      for (final v in mappable) v.lat!,
      if (midpoint != null) midpoint!.lat,
    ];
    final lngs = [
      for (final v in mappable) v.lng!,
      if (midpoint != null) midpoint!.lng,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEAF5F0), Color(0xFFF8EFE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
              if (lats.isEmpty)
                const Center(
                  child: Icon(Icons.map_outlined, size: 44, color: Colors.black45),
                )
              else ...[
                for (final venue in mappable)
                  _PositionedVenueMarker(
                    venue: venue,
                    minLat: lats.reduce(math.min),
                    maxLat: lats.reduce(math.max),
                    minLng: lngs.reduce(math.min),
                    maxLng: lngs.reduce(math.max),
                    size: constraints.biggest,
                    onVenueSelected: onVenueSelected,
                  ),
                if (midpoint != null)
                  _MidpointDot(
                    midpoint: midpoint!,
                    minLat: lats.reduce(math.min),
                    maxLat: lats.reduce(math.max),
                    minLng: lngs.reduce(math.min),
                    maxLng: lngs.reduce(math.max),
                    size: constraints.biggest,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

double _scalePos(double value, double min, double max, double start, double end) {
  if ((max - min).abs() < 0.000001) return start + (end - start) / 2;
  return start + ((value - min) / (max - min)) * (end - start);
}

class _MidpointDot extends StatelessWidget {
  const _MidpointDot({
    required this.midpoint,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.size,
  });

  final MapPoint midpoint;
  final double minLat, maxLat, minLng, maxLng;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final x = _scalePos(midpoint.lng, minLng, maxLng, 28, size.width - 28);
    final y = _scalePos(midpoint.lat, maxLat, minLat, 28, size.height - 28);
    return Positioned(
      left: x - 14,
      top: y - 14,
      child: Container(
        key: const Key('midpoint_marker'),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.group, size: 14, color: Colors.white),
      ),
    );
  }
}
```

`_PositionedVenueMarker` đổi chữ ký: nhận `minLat/maxLat/minLng/maxLng` (double) thay vì `venues`, dùng `_scalePos` chung; giữ nguyên IconButton + Key `venue_marker_${venue.id}`.

- [ ] **Step 4: Wire PlanScreen**

Trong `plan_screen.dart`, phần `venuesAsync.when(data: ...)`:

```dart
data: (list) => VenueMapSurface(
  venues: list,
  midpoint: ref.watch(keoMidpointProvider(keoId)).asData?.value,
  useNativeMap: useNativeMap,
  onVenueSelected: isHost
      ? (venue) => _pickVenue(context, ref, venue)
      : (_) {},
),
```

Trong `test/features/plan/plan_screen_test.dart` thêm override vào (các) ProviderScope sẵn có:

```dart
keoMidpointProvider.overrideWith((ref, keoId) async => null),
```

(Riverpod 3 family override: nếu chữ ký trên không compile, dùng
`keoMidpointProvider(keoId).overrideWith((ref) async => null)` cho keoId cụ thể của test.)

- [ ] **Step 5: Full test + analyze**

Run: `flutter.bat test && flutter.bat analyze`
Expected: PASS toàn bộ, analyze sạch.

- [ ] **Step 6: Commit**

```bash
git add lib/features/plan/presentation/venue_map_surface.dart lib/features/plan/presentation/plan_screen.dart test/features/plan/venue_map_surface_test.dart test/features/plan/plan_screen_test.dart
git commit -m "feat(plan): pin midpoint nhom tren map + fit bounds camera"
```

---

### Task 4: iOS Maps key wiring + env plumbing + docs

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `ios/Runner/Info.plist`
- Modify: `env/dev.json`, `env/dev.emulator.json`, `env/dev.device.json`
- Modify: `docs/LAUNCH.md`

Không có test tự động (không build iOS được trên Windows) — gate = analyze + toàn bộ suite vẫn xanh + review kỹ.

- [ ] **Step 1: AppDelegate**

```swift
import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Maps key duoc inject qua Info.plist (GMapsAPIKey = $(MAPS_API_KEY)).
    // Khong co key -> khong provideAPIKey; native map van tat sau co GOOGLE_MAPS_ENABLED.
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMapsAPIKey") as? String,
       !key.isEmpty, !key.hasPrefix("$(") {
      GMSServices.provideAPIKey(key)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
```

- [ ] **Step 2: Info.plist** — thêm vào `<dict>` gốc:

```xml
	<key>GMapsAPIKey</key>
	<string>$(MAPS_API_KEY)</string>
```

- [ ] **Step 3: env files** — thêm `"GOOGLE_MAPS_ENABLED": false` vào `env/dev.json`, `env/dev.emulator.json`, `env/dev.device.json` (dev.example.json đã có).

- [ ] **Step 4: LAUNCH.md** — thêm mục:

```markdown
## Bật Google Maps (cần billing + key — operator gate)

1. Google Cloud: bật billing Maps Platform, tạo 2 key:
   - **Maps SDK key** (restrict: Maps SDK for Android + iOS, restrict theo package/bundle id).
   - **Places server key** (restrict: Places API (New); dùng cho edge `ingest-places-venues`).
2. Android: ghi `MAPS_API_KEY=<maps-sdk-key>` vào `android/local.properties` (KHÔNG commit).
3. iOS: truyền build setting `MAPS_API_KEY=<maps-sdk-key>` (xcconfig user-level, KHÔNG commit).
4. Lật `"GOOGLE_MAPS_ENABLED": true` trong file env dùng để build, rebuild app.
5. Edge: ghi `GOOGLE_PLACES_API_KEY` + `PLACES_INGEST_SECRET` vào `supabase/functions/.env`
   (local) / `supabase secrets set` (cloud), chạy `scripts/run_places_ingest.sh` per city.
```

- [ ] **Step 5: Gates + commit**

Run: `flutter.bat test && flutter.bat analyze`
Expected: xanh (không đổi Dart nào ngoài env JSON — suite phải vẫn xanh).

```bash
git add ios/Runner/AppDelegate.swift ios/Runner/Info.plist env/dev.json env/dev.emulator.json env/dev.device.json docs/LAUNCH.md
git commit -m "feat(maps): wiring GMSServices iOS + GOOGLE_MAPS_ENABLED env + runbook bat maps"
```

---

### Task 5: Cột `booking_deposit_minor` + server quyết tiền cọc (DB + Flutter)

**Files:**
- Create: `supabase/migrations/20260707190000_booking_deposit.sql`
- Test: `supabase/tests/booking_deposit_test.sql`
- Modify: `lib/features/plan/data/plan_repository.dart` (bỏ amountMinor khỏi startVenuePayment)
- Modify: `lib/features/plan/presentation/booking_button.dart` (bỏ amountMinor param — UI sheet làm ở Task 6)
- Modify: `test/features/plan/booking_test.dart`

- [ ] **Step 1: pgTAP test fail**

```sql
-- supabase/tests/booking_deposit_test.sql
-- Run with: supabase test db
-- Proves migration 20260707190000: venues.booking_deposit_minor (server-quyet tien coc).
begin;
select plan(3);
select has_column('public', 'venues', 'booking_deposit_minor', 'venues co cot booking_deposit_minor');
select ok(
  (select count(*) = 0 from public.venues where booking_deposit_minor is null),
  'moi venue deu co deposit');
select ok(
  (select bool_and(booking_deposit_minor > 0) from public.venues),
  'deposit luon duong (CHECK)');
select * from finish();
rollback;
```

- [ ] **Step 2: Chạy fail** — `npx supabase test db` → has_column FAIL.

- [ ] **Step 3: Migration**

```sql
-- supabase/migrations/20260707190000_booking_deposit.sql
-- Tien coc dat phong do SERVER quyet (dong hoa loi "client tu ra gia" cua P6).
-- VND khong co don vi le: minor = dong. Mac dinh 200k; chinh per-venue la viec BD sau.
alter table public.venues
  add column if not exists booking_deposit_minor int not null default 200000
  constraint venues_deposit_positive check (booking_deposit_minor > 0);
```

- [ ] **Step 4: Apply + pass** — `npx supabase migration up && npx supabase test db` → 100% PASS.

- [ ] **Step 5: Flutter — đổi chữ ký (test trước)**

`test/features/plan/booking_test.dart` — thay toàn bộ test hiện có bằng:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import '../../support/supabase_mocks.dart';

class _MockFunctions extends Mock implements FunctionsClient {}

void main() {
  test('startVenuePayment goi create-venue-payment KHONG gui amount (server quyet)', () async {
    final client = MockSupabaseClient();
    final fns = _MockFunctions();
    when(() => client.functions).thenReturn(fns);
    Map<String, dynamic>? sentBody;
    when(() => fns.invoke('create-venue-payment', body: any(named: 'body')))
        .thenAnswer((inv) async {
      sentBody = inv.namedArguments[#body] as Map<String, dynamic>;
      return FunctionResponse(data: {'pay_url': 'https://pay/x'}, status: 200);
    });
    final url = await PlanRepository(client)
        .startVenuePayment(planId: 'p1', venueId: 'v1', gateway: 'zalopay');
    expect(url, 'https://pay/x');
    expect(sentBody, {'plan_id': 'p1', 'venue_id': 'v1', 'gateway': 'zalopay'});
    expect(sentBody!.containsKey('amount_minor'), isFalse);
  });
}
```

Run fail (compile error do named param `amountMinor` vẫn required), rồi sửa `plan_repository.dart`:

```dart
Future<String> startVenuePayment({
  required String planId, required String venueId, required String gateway,
}) async {
  final res = await _client.functions.invoke('create-venue-payment', body: {
    'plan_id': planId, 'venue_id': venueId, 'gateway': gateway,
  });
  if (res.status >= 400) {
    throw Exception('create-venue-payment failed (${res.status}): ${res.data}');
  }
  return (res.data as Map)['pay_url'] as String;
}
```

`booking_button.dart`: xoá field/param `amountMinor` + chỗ truyền `amountMinor:` trong call; xoá luôn nơi PlanScreen truyền `amountMinor` nếu có (grep `amountMinor` toàn repo — phải về 0 kết quả ngoài git history).

- [ ] **Step 6: Gates + commit**

Run: `flutter.bat test && flutter.bat analyze && npx supabase test db` → xanh 100%.

```bash
git add supabase/migrations/20260707190000_booking_deposit.sql supabase/tests/booking_deposit_test.sql lib/features/plan/data/plan_repository.dart lib/features/plan/presentation/booking_button.dart test/features/plan/booking_test.dart
git commit -m "feat(payments): server quyet tien coc - venues.booking_deposit_minor, client het gui amount"
```

---

### Task 6: BookingButton — sheet chọn gateway MoMo/ZaloPay

**Files:**
- Modify: `lib/features/plan/presentation/booking_button.dart`
- Test: Create `test/features/plan/booking_button_test.dart`

- [ ] **Step 1: Widget test fail**

```dart
// test/features/plan/booking_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/presentation/booking_button.dart';

class _MockPlanRepository extends Mock implements PlanRepository {}

void main() {
  late _MockPlanRepository repo;

  Widget wrap() => ProviderScope(
        overrides: [planRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(body: BookingButton(planId: 'p1', venueId: 'v1')),
        ),
      );

  setUp(() {
    repo = _MockPlanRepository();
    when(() => repo.startVenuePayment(
            planId: any(named: 'planId'),
            venueId: any(named: 'venueId'),
            gateway: any(named: 'gateway')))
        .thenAnswer((_) async => 'https://pay/x');
  });

  testWidgets('tap nut -> sheet 2 gateway; chon MoMo -> goi voi momo', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('booking_gw_momo')), findsOneWidget);
    expect(find.byKey(const Key('booking_gw_zalopay')), findsOneWidget);
    await tester.tap(find.byKey(const Key('booking_gw_momo')));
    await tester.pumpAndSettle();
    verify(() => repo.startVenuePayment(planId: 'p1', venueId: 'v1', gateway: 'momo'))
        .called(1);
  });

  testWidgets('chon ZaloPay -> goi voi zalopay', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking_gw_zalopay')));
    await tester.pumpAndSettle();
    verify(() => repo.startVenuePayment(planId: 'p1', venueId: 'v1', gateway: 'zalopay'))
        .called(1);
  });

  testWidgets('loi not_configured -> SnackBar cau hinh', (tester) async {
    when(() => repo.startVenuePayment(
            planId: any(named: 'planId'),
            venueId: any(named: 'venueId'),
            gateway: any(named: 'gateway')))
        .thenThrow(Exception('create-venue-payment failed (503): {error: payment_gateway_not_configured}'));
    await tester.pumpWidget(wrap());
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking_gw_momo')));
    await tester.pumpAndSettle();
    expect(find.textContaining('chưa được cấu hình'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy fail** — `flutter.bat test test/features/plan/booking_button_test.dart` → FAIL (chưa có sheet).

- [ ] **Step 3: Implement**

```dart
// booking_button.dart — thay onPressed:
onPressed: () async {
  final gateway = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('booking_gw_momo'),
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('MoMo'),
            onTap: () => Navigator.pop(ctx, 'momo'),
          ),
          ListTile(
            key: const Key('booking_gw_zalopay'),
            leading: const Icon(Icons.payment),
            title: const Text('ZaloPay'),
            onTap: () => Navigator.pop(ctx, 'zalopay'),
          ),
        ],
      ),
    ),
  );
  if (gateway == null || !context.mounted) return;
  try {
    final url = await ref.read(planRepositoryProvider).startVenuePayment(
        planId: planId, venueId: venueId, gateway: gateway);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    if (context.mounted) {
      final msg = e.toString().contains('not_configured')
          ? 'Cổng thanh toán chưa được cấu hình'
          : 'Không tạo được thanh toán';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
},
```

Lưu ý: trong widget test, `canLaunchUrl` ném MissingPluginException → rơi vào catch → SnackBar "Không tạo được thanh toán" — verify() vẫn đếm được call; test 1-2 không assert SnackBar nên không sao.

- [ ] **Step 4: Gates** — `flutter.bat test && flutter.bat analyze` → xanh.

- [ ] **Step 5: Commit**

```bash
git add lib/features/plan/presentation/booking_button.dart test/features/plan/booking_button_test.dart
git commit -m "feat(payments): sheet chon gateway MoMo/ZaloPay o BookingButton"
```

---

### Task 7: `create-venue-payment` thật (MoMo + ZaloPay create-order, fail-closed)

**Files:**
- Create: `supabase/functions/_shared/hmac.ts`
- Modify: `supabase/functions/create-venue-payment/index.ts` (viết lại)
- Modify: `supabase/config.toml` (thêm `[functions.payments-webhook] verify_jwt = false` — dùng ở Task 8 nhưng thêm cùng lần sửa config)
- Modify: `supabase/functions/.env.example` (liệt kê env mới)

- [ ] **Step 1: `_shared/hmac.ts`**

```ts
// supabase/functions/_shared/hmac.ts
export async function hmacSha256Hex(secret: string, data: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(data));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status, headers: { "Content-Type": "application/json" },
  });
}
```

- [ ] **Step 2: Viết lại `create-venue-payment/index.ts`**

```ts
import { createClient } from "jsr:@supabase/supabase-js@2";
import { hmacSha256Hex, json } from "../_shared/hmac.ts";

// Dat coc phong hat (dich vu that -> MoMo/ZaloPay, KHONG IAP — store-policy split).
// So tien do SERVER quyet tu venues.booking_deposit_minor. Fail-closed khi thieu env.
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const { plan_id, venue_id, gateway } = await req.json().catch(() => ({}));
  if (!plan_id || !venue_id) return json(400, { error: "missing_payment_fields" });
  if (!["momo", "zalopay"].includes(gateway)) return json(400, { error: "bad_gateway" });

  const redirectUrl = Deno.env.get("PAYMENTS_REDIRECT_URL");
  const webhookBase = Deno.env.get("PAYMENTS_WEBHOOK_URL");
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  const { data: venue } = await admin.from("venues")
    .select("id,booking_deposit_minor,is_active").eq("id", venue_id).maybeSingle();
  if (!venue?.is_active) return json(400, { error: "unknown_venue" });
  const amount = venue.booking_deposit_minor as number;

  if (gateway === "momo") {
    const partnerCode = Deno.env.get("MOMO_PARTNER_CODE");
    const accessKey = Deno.env.get("MOMO_ACCESS_KEY");
    const secretKey = Deno.env.get("MOMO_SECRET_KEY");
    const endpoint = Deno.env.get("MOMO_ENDPOINT"); // sandbox: https://test-payment.momo.vn
    if (!partnerCode || !accessKey || !secretKey || !endpoint || !redirectUrl || !webhookBase) {
      return json(503, { error: "payment_gateway_not_configured" });
    }
    const orderId = crypto.randomUUID();
    const { error: insErr } = await admin.from("venue_bookings").insert({
      plan_id, venue_id, user_id: user.id, amount_minor: amount,
      gateway, gateway_ref: orderId, state: "initiated",
    });
    if (insErr) return json(400, { error: insErr.message });

    const requestId = orderId;
    const orderInfo = "Coc phong hat Cung Hat";
    const extraData = "";
    const ipnUrl = `${webhookBase}?gateway=momo`;
    // Chuoi ky create-order theo docs MoMo v2 (thu tu alphabet, HMAC-SHA256 secretKey).
    const raw =
      `accessKey=${accessKey}&amount=${amount}&extraData=${extraData}` +
      `&ipnUrl=${ipnUrl}&orderId=${orderId}&orderInfo=${orderInfo}` +
      `&partnerCode=${partnerCode}&redirectUrl=${redirectUrl}` +
      `&requestId=${requestId}&requestType=captureWallet`;
    const signature = await hmacSha256Hex(secretKey, raw);
    const res = await fetch(`${endpoint}/v2/gateway/api/create`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        partnerCode, requestId, amount, orderId, orderInfo,
        redirectUrl, ipnUrl, lang: "vi", extraData,
        requestType: "captureWallet", signature,
      }),
    }).catch(() => null);
    const data = res ? await res.json().catch(() => null) : null;
    if (!res?.ok || data?.resultCode !== 0 || !data?.payUrl) {
      await admin.from("venue_bookings").update({ state: "failed" })
        .eq("gateway_ref", orderId);
      return json(502, { error: "gateway_create_failed", detail: data?.message ?? null });
    }
    return json(200, { pay_url: data.payUrl, gateway_ref: orderId });
  }

  // zalopay
  const appId = Deno.env.get("ZALOPAY_APP_ID");
  const key1 = Deno.env.get("ZALOPAY_KEY1");
  const endpoint = Deno.env.get("ZALOPAY_ENDPOINT"); // sandbox: https://sb-openapi.zalopay.vn
  if (!appId || !key1 || !endpoint || !redirectUrl || !webhookBase) {
    return json(503, { error: "payment_gateway_not_configured" });
  }
  const now = new Date();
  const yy = String(now.getFullYear()).slice(2);
  const mm = String(now.getMonth() + 1).padStart(2, "0");
  const dd = String(now.getDate()).padStart(2, "0");
  const appTransId = `${yy}${mm}${dd}_${crypto.randomUUID().replaceAll("-", "").slice(0, 16)}`;
  const { error: insErr } = await admin.from("venue_bookings").insert({
    plan_id, venue_id, user_id: user.id, amount_minor: amount,
    gateway, gateway_ref: appTransId, state: "initiated",
  });
  if (insErr) return json(400, { error: insErr.message });

  const appTime = Date.now();
  const embedData = JSON.stringify({ redirecturl: redirectUrl });
  const item = "[]";
  // mac = HMAC(app_id|app_trans_id|app_user|amount|app_time|embed_data|item, key1)
  const macRaw = `${appId}|${appTransId}|${user.id}|${amount}|${appTime}|${embedData}|${item}`;
  const mac = await hmacSha256Hex(key1, macRaw);
  const form = new URLSearchParams({
    app_id: appId, app_user: user.id, app_time: String(appTime),
    amount: String(amount), app_trans_id: appTransId,
    embed_data: embedData, item, description: "Coc phong hat Cung Hat",
    bank_code: "", callback_url: `${webhookBase}?gateway=zalopay`, mac,
  });
  const res = await fetch(`${endpoint}/v2/create`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: form.toString(),
  }).catch(() => null);
  const data = res ? await res.json().catch(() => null) : null;
  if (!res?.ok || data?.return_code !== 1 || !data?.order_url) {
    await admin.from("venue_bookings").update({ state: "failed" })
      .eq("gateway_ref", appTransId);
    return json(502, { error: "gateway_create_failed", detail: data?.return_message ?? null });
  }
  return json(200, { pay_url: data.order_url, gateway_ref: appTransId });
});
```

- [ ] **Step 3: config.toml + .env.example**

`supabase/config.toml` — thêm cuối file:

```toml
[functions.payments-webhook]
verify_jwt = false
```

`supabase/functions/.env.example` — thêm:

```
# MoMo (sandbox endpoint: https://test-payment.momo.vn, prod: https://payment.momo.vn)
MOMO_PARTNER_CODE=
MOMO_ACCESS_KEY=
MOMO_SECRET_KEY=
MOMO_ENDPOINT=
# ZaloPay (sandbox endpoint: https://sb-openapi.zalopay.vn, prod: https://openapi.zalopay.vn)
ZALOPAY_APP_ID=
ZALOPAY_KEY1=
ZALOPAY_KEY2=
ZALOPAY_ENDPOINT=
# Chung
PAYMENTS_REDIRECT_URL=
PAYMENTS_WEBHOOK_URL=
# IAP
APP_BUNDLE_ID=
APPLE_ENVIRONMENT=Sandbox
APPLE_SHARED_SECRET=
ANDROID_PACKAGE_NAME=
GOOGLE_PLAY_SA_JSON=
```

- [ ] **Step 4: Smoke fail-closed (edge runtime local)**

Đảm bảo stack chạy (`npx supabase start` nếu cần), env local KHÔNG có MOMO_*:

```bash
docker restart supabase_edge_runtime_cung-hat && sleep 3
# khong JWT -> 401
curl -s -o /dev/null -w "%{http_code}" -X POST http://127.0.0.1:54321/functions/v1/create-venue-payment -H "Content-Type: application/json" -d '{}'
```
Expected: `401`. (503-check với JWT thật nằm ở Task 12 harness.)

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/_shared/hmac.ts supabase/functions/create-venue-payment/index.ts supabase/config.toml supabase/functions/.env.example
git commit -m "feat(payments): create-venue-payment that - MoMo/ZaloPay create-order + HMAC, fail-closed"
```

---

### Task 8: `payments-webhook` thật (verify HMAC + idempotent)

**Files:**
- Modify: `supabase/functions/payments-webhook/index.ts` (viết lại)

- [ ] **Step 1: Viết lại**

```ts
import { createClient } from "jsr:@supabase/supabase-js@2";
import { hmacSha256Hex, json } from "../_shared/hmac.ts";

// IPN/callback gateway. verify_jwt=false (config.toml) vi gateway khong co JWT Supabase —
// chu ky HMAC cua gateway CHINH LA lop xac thuc. Fail-closed khi thieu secret.
// Idempotent: chi chuyen initiated -> paid|failed; da paid thi bo qua.
Deno.serve(async (req) => {
  const gateway = new URL(req.url).searchParams.get("gateway");
  const body = await req.json().catch(() => ({}));
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  async function settle(gatewayRef: string, paid: boolean, ipnAmount: number) {
    const { data: booking } = await admin.from("venue_bookings")
      .select("id,amount_minor,state").eq("gateway_ref", gatewayRef).maybeSingle();
    if (!booking) return "not_found";
    if (booking.state === "paid") return "already_paid";
    if (paid && ipnAmount !== booking.amount_minor) {
      console.error(`[payments-webhook] amount mismatch ref=${gatewayRef} ipn=${ipnAmount} db=${booking.amount_minor}`);
      await admin.from("venue_bookings").update({ state: "failed" }).eq("id", booking.id);
      return "amount_mismatch";
    }
    if (paid) {
      const commission = Math.round(booking.amount_minor * 0.1); // hoa hong 10%
      await admin.from("venue_bookings")
        .update({ state: "paid", commission_minor: commission }).eq("id", booking.id);
      return "paid";
    }
    await admin.from("venue_bookings").update({ state: "failed" }).eq("id", booking.id);
    return "failed";
  }

  if (gateway === "momo") {
    const accessKey = Deno.env.get("MOMO_ACCESS_KEY");
    const secretKey = Deno.env.get("MOMO_SECRET_KEY");
    if (!accessKey || !secretKey) return json(503, { error: "payment_gateway_not_configured" });
    // Chuoi ky IPN v2 theo docs MoMo (thu tu alphabet co dinh).
    const raw =
      `accessKey=${accessKey}&amount=${body.amount}&extraData=${body.extraData ?? ""}` +
      `&message=${body.message}&orderId=${body.orderId}&orderInfo=${body.orderInfo}` +
      `&orderType=${body.orderType}&partnerCode=${body.partnerCode}&payType=${body.payType}` +
      `&requestId=${body.requestId}&responseTime=${body.responseTime}` +
      `&resultCode=${body.resultCode}&transId=${body.transId}`;
    const expected = await hmacSha256Hex(secretKey, raw);
    if (!body.signature || expected !== body.signature) {
      return new Response("bad signature", { status: 401 });
    }
    const outcome = await settle(String(body.orderId), body.resultCode === 0, Number(body.amount));
    if (outcome === "not_found") return new Response("not found", { status: 404 });
    return new Response(null, { status: 204 }); // MoMo yeu cau 204
  }

  if (gateway === "zalopay") {
    const key2 = Deno.env.get("ZALOPAY_KEY2");
    if (!key2) return json(503, { error: "payment_gateway_not_configured" });
    const { data, mac } = body;
    if (typeof data !== "string" || !mac) return json(200, { return_code: -1, return_message: "bad request" });
    const expected = await hmacSha256Hex(key2, data);
    if (expected !== mac) return json(200, { return_code: -1, return_message: "mac not equal" });
    let payload: Record<string, unknown>;
    try { payload = JSON.parse(data); } catch { return json(200, { return_code: -1, return_message: "bad data" }); }
    // ZaloPay chi callback khi thanh toan THANH CONG.
    const outcome = await settle(String(payload.app_trans_id), true, Number(payload.amount));
    if (outcome === "not_found") return json(200, { return_code: -1, return_message: "order not found" });
    return json(200, { return_code: 1, return_message: "success" });
  }

  return json(400, { error: "unknown_gateway" });
});
```

- [ ] **Step 2: Smoke self-signed (crypto thật, secret dummy)**

```bash
# 1) secret dummy vao env local + restart edge runtime
cd "/c/Users/Hwang Ming Hung/cung-hat-photos-wt"
printf 'MOMO_ACCESS_KEY=dummyaccess\nMOMO_SECRET_KEY=dummysecret\nZALOPAY_KEY2=dummykey2\n' >> supabase/functions/.env
docker restart supabase_edge_runtime_cung-hat && sleep 3

# 2) seed booking initiated
docker exec supabase_db_cung-hat psql -U postgres -d postgres -c "insert into public.venue_bookings (venue_id, amount_minor, gateway, gateway_ref, state) select id, booking_deposit_minor, 'momo', 'smoke-ref-1', 'initiated' from public.venues limit 1;"

# 3) ky IPN MoMo bang dung thuat toan + secret dummy -> phai duoc NHAN (204, state=paid)
RAW='accessKey=dummyaccess&amount=200000&extraData=&message=Success&orderId=smoke-ref-1&orderInfo=test&orderType=momo_wallet&partnerCode=PC&payType=qr&requestId=r1&responseTime=1&resultCode=0&transId=99'
SIG=$(printf '%s' "$RAW" | openssl dgst -sha256 -hmac dummysecret -r | cut -d' ' -f1)
curl -s -o /dev/null -w "%{http_code}\n" -X POST "http://127.0.0.1:54321/functions/v1/payments-webhook?gateway=momo" -H "Content-Type: application/json" -d "{\"partnerCode\":\"PC\",\"orderId\":\"smoke-ref-1\",\"requestId\":\"r1\",\"amount\":200000,\"orderInfo\":\"test\",\"orderType\":\"momo_wallet\",\"transId\":99,\"resultCode\":0,\"message\":\"Success\",\"payType\":\"qr\",\"responseTime\":1,\"extraData\":\"\",\"signature\":\"$SIG\"}"
docker exec supabase_db_cung-hat psql -U postgres -d postgres -t -c "select state, commission_minor from public.venue_bookings where gateway_ref='smoke-ref-1';"

# 4) tamper 1 truong -> 401, state khong doi
curl -s -o /dev/null -w "%{http_code}\n" -X POST "http://127.0.0.1:54321/functions/v1/payments-webhook?gateway=momo" -H "Content-Type: application/json" -d "{\"partnerCode\":\"PC\",\"orderId\":\"smoke-ref-1\",\"requestId\":\"r1\",\"amount\":999,\"orderInfo\":\"test\",\"orderType\":\"momo_wallet\",\"transId\":99,\"resultCode\":0,\"message\":\"Success\",\"payType\":\"qr\",\"responseTime\":1,\"extraData\":\"\",\"signature\":\"$SIG\"}"

# 5) don smoke row
docker exec supabase_db_cung-hat psql -U postgres -d postgres -c "delete from public.venue_bookings where gateway_ref='smoke-ref-1';"
```

Expected: bước 3 in `204` + `paid | 20000`; bước 4 in `401`.
(Task 12 sẽ script hoá toàn bộ; ở đây chạy tay xác nhận trước khi commit.)

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/payments-webhook/index.ts
git commit -m "feat(payments): webhook verify HMAC that MoMo/ZaloPay + idempotent + doi chieu amount"
```

---

### Task 9: `validate-iap` thật (Apple + Google, fail-closed)

**Files:**
- Create: `supabase/functions/_shared/google_play.ts`
- Create: `supabase/functions/_shared/apple_iap.ts`
- Modify: `supabase/functions/validate-iap/index.ts` (viết lại)

- [ ] **Step 1: `_shared/google_play.ts`**

```ts
// Verify purchase Android qua Google Play Developer API (service account JWT RS256).
function b64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  return btoa(String.fromCharCode(...bytes))
    .replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function pemToDer(pem: string): Uint8Array {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

export async function verifyGooglePurchase(opts: {
  saJson: string; packageName: string; productId: string; purchaseToken: string;
}): Promise<{ ok: boolean; reason?: string }> {
  let sa: { client_email: string; private_key: string; token_uri: string };
  try { sa = JSON.parse(opts.saJson); } catch { return { ok: false, reason: "bad_sa_json" }; }

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
  return { ok: true };
}
```

- [ ] **Step 2: `_shared/apple_iap.ts`**

```ts
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
```

- [ ] **Step 3: Viết lại `validate-iap/index.ts`**

```ts
import { createClient } from "jsr:@supabase/supabase-js@2";
import { json } from "../_shared/hmac.ts";
import { verifyGooglePurchase } from "../_shared/google_play.ts";
import { verifyAppleReceipt } from "../_shared/apple_iap.ts";

// Verify receipt THAT roi moi cap entitlement. Fail-closed khi thieu creds store.
// Client gui JWT; user resolve tu JWT (khong bao gio tin user_id trong body).
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const { platform, store_product_id, store_txn_id, receipt } =
    await req.json().catch(() => ({}));
  if (!platform || !store_product_id || !store_txn_id || !receipt) {
    return json(400, { error: "missing_purchase_fields" });
  }
  if (!["ios", "android"].includes(platform)) return json(400, { error: "bad_platform" });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: product } = await admin.from("products")
    .select("id,type").eq("store_product_id", store_product_id)
    .eq("platform", platform).maybeSingle();
  if (!product) return json(400, { error: "unknown_product" });

  if (platform === "android") {
    const saJson = Deno.env.get("GOOGLE_PLAY_SA_JSON");
    const packageName = Deno.env.get("ANDROID_PACKAGE_NAME");
    if (!saJson || !packageName) return json(503, { error: "iap_verifier_not_configured" });
    const v = await verifyGooglePurchase({
      saJson, packageName, productId: store_product_id, purchaseToken: receipt,
    });
    if (!v.ok) return json(400, { error: "invalid_receipt", reason: v.reason });
  } else {
    const bundleId = Deno.env.get("APP_BUNDLE_ID");
    if (!bundleId) return json(503, { error: "iap_verifier_not_configured" });
    const v = await verifyAppleReceipt({
      receipt, bundleId,
      environment: Deno.env.get("APPLE_ENVIRONMENT") ?? "Sandbox",
      sharedSecret: Deno.env.get("APPLE_SHARED_SECRET"),
      expectedTxnId: String(store_txn_id), expectedProductId: store_product_id,
    });
    if (!v.ok) return json(400, { error: "invalid_receipt", reason: v.reason });
  }

  await admin.from("purchases").upsert({
    user_id: user.id, product_id: product.id, platform,
    store_txn_id, receipt_ref: "stored", state: "validated",
  }, { onConflict: "platform,store_txn_id" });

  // boost = cua so 24h; con lai vinh vien (active_until null).
  const activeUntil = product.type === "boost"
    ? new Date(Date.now() + 24 * 3600 * 1000).toISOString() : null;
  await admin.from("entitlements").upsert({
    user_id: user.id, feature: product.type,
    source: platform === "ios" ? "ios_iap" : "play_billing", active_until: activeUntil,
  }, { onConflict: "user_id,feature" });

  return json(200, { ok: true, feature: product.type });
});
```

- [ ] **Step 4: Smoke fail-closed**

```bash
docker restart supabase_edge_runtime_cung-hat && sleep 3
# khong JWT -> 401
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://127.0.0.1:54321/functions/v1/validate-iap -H "Content-Type: application/json" -d '{}'
```
Expected: `401`. (503/400 với JWT thật ở Task 12.)

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/_shared/google_play.ts supabase/functions/_shared/apple_iap.ts supabase/functions/validate-iap/index.ts
git commit -m "feat(billing): validate-iap verify receipt that Apple JWS/legacy + Google Play API, fail-closed"
```

---

### Task 10: IAP catalog từ bảng `products` (RPC + Flutter)

**Files:**
- Create: `supabase/migrations/20260707200000_store_products_rpc.sql`
- Test: `supabase/tests/store_products_rpc_test.sql`
- Modify: `lib/features/billing/data/billing_repository.dart`
- Modify: `lib/features/billing/application/iap_controller.dart`
- Modify: `test/features/billing/billing_repository_test.dart` (thêm group)

- [ ] **Step 1: pgTAP fail**

```sql
-- supabase/tests/store_products_rpc_test.sql
-- Run with: supabase test db
-- Proves migration 20260707200000: get_store_products catalog RPC.
begin;
select plan(3);
select ok(exists(select 1 from pg_proc where proname='get_store_products'), 'get_store_products exists');
select ok(
  (select count(*) >= 4 from public.get_store_products('android')),
  'android co >= 4 product (boost/see_likes/premium_filters/pro)');
select ok(
  (select count(*) = 0 from public.get_store_products('windows')),
  'platform la -> rong');
select * from finish();
rollback;
```

- [ ] **Step 2: Chạy fail** — `npx supabase test db`.

- [ ] **Step 3: Migration**

```sql
-- supabase/migrations/20260707200000_store_products_rpc.sql
-- Catalog product id theo platform cho IapController (het hardcode client).
-- SECURITY INVOKER: RLS products_read (is_active) van ap dung.
create or replace function public.get_store_products(p_platform text)
returns table (type text, store_product_id text)
language sql
stable
set search_path=''
as $$
  select p.type, p.store_product_id
  from public.products p
  where p.platform = p_platform and p.is_active;
$$;
```

- [ ] **Step 4: Apply + pass** — `npx supabase migration up && npx supabase test db`.

- [ ] **Step 5: Flutter test fail** — thêm vào `test/features/billing/billing_repository_test.dart`:

```dart
group('storeProductIds', () {
  test('map type -> store_product_id theo platform', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_store_products', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk([
              {'type': 'boost', 'store_product_id': 'com.cunghat.boost'},
              {'type': 'pro', 'store_product_id': 'com.cunghat.pro'},
            ]));
    final ids = await BillingRepository(client).storeProductIds('android');
    expect(ids, {'boost': 'com.cunghat.boost', 'pro': 'com.cunghat.pro'});
  });
});
```

(Nếu file test chưa import `../../support/supabase_mocks.dart` thì thêm.)

- [ ] **Step 6: Implement**

`billing_repository.dart` thêm:

```dart
/// Catalog product-id theo platform tu bang products (het hardcode client).
Future<Map<String, String>> storeProductIds(String platform) async {
  final rows = await _client
      .rpc('get_store_products', params: {'p_platform': platform}) as List<dynamic>;
  return {
    for (final r in rows.cast<Map<String, dynamic>>())
      r['type'] as String: r['store_product_id'] as String,
  };
}
```

`iap_controller.dart` — xoá const `_storeProductIds` + TODO cũ, thêm cache và dùng trong `buy`:

```dart
Map<String, String>? _catalog;

Future<String?> _productIdFor(String feature) async {
  try {
    _catalog ??= await ref.read(billingRepositoryProvider).storeProductIds(
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
  } catch (e) {
    debugPrint('IAP catalog load failed: $e');
    return null;
  }
  return _catalog![feature];
}

Future<void> buy(String feature) async {
  final productId = await _productIdFor(feature);
  if (productId == null) return;
  // ... phan con lai giu nguyen (queryProductDetails -> buyConsumable/NonConsumable)
}
```

- [ ] **Step 7: Gates + commit**

Run: `flutter.bat test && flutter.bat analyze && npx supabase test db` → xanh.

```bash
git add supabase/migrations/20260707200000_store_products_rpc.sql supabase/tests/store_products_rpc_test.sql lib/features/billing/data/billing_repository.dart lib/features/billing/application/iap_controller.dart test/features/billing/billing_repository_test.dart
git commit -m "feat(billing): catalog IAP tu bang products qua get_store_products"
```

---

### Task 11: `ingest-places-venues` thêm mode textQuery (music box)

**Files:**
- Modify: `supabase/functions/ingest-places-venues/index.ts`

- [ ] **Step 1: Implement** — thay đoạn đọc body + fetch bằng:

```ts
  const { city, lat, lng, radius_m = 5000, style_tag = "k_style", text_query } =
    await req.json();
  let res: Response;
  if (text_query) {
    // searchText: bat "music box"/"phong hat mini" ma searchNearby type=karaoke bo sot.
    res = await fetch("https://places.googleapis.com/v1/places:searchText", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": Deno.env.get("GOOGLE_PLACES_API_KEY")!,
        "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location",
      },
      body: JSON.stringify({
        textQuery: text_query,
        pageSize: 20,
        locationBias: { circle: { center: { latitude: lat, longitude: lng }, radius: radius_m } },
      }),
    });
  } else {
    res = await fetch("https://places.googleapis.com/v1/places:searchNearby", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": Deno.env.get("GOOGLE_PLACES_API_KEY")!,
        "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location",
      },
      body: JSON.stringify({
        includedTypes: ["karaoke"],
        maxResultCount: 20,
        locationRestriction: { circle: { center: { latitude: lat, longitude: lng }, radius: radius_m } },
      }),
    });
  }
  const data = await res.json();
```

Phần upsert giữ nguyên.

- [ ] **Step 2: Smoke secret-gate**

```bash
docker restart supabase_edge_runtime_cung-hat && sleep 3
curl -s -o /dev/null -w "%{http_code}\n" -X POST "http://127.0.0.1:54321/functions/v1/ingest-places-venues" -H "Content-Type: application/json" -H "Authorization: Bearer $(grep -o 'sb_publishable_[A-Za-z0-9_]*' ../cung-hat/README.md 2>/dev/null || echo dummy)" -d '{"city":"HN"}'
```
Expected: `403` (thiếu x-ingest-secret) — gate còn nguyên. (Chạy thật cần GOOGLE_PLACES_API_KEY → operator gate.)

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/ingest-places-venues/index.ts
git commit -m "feat(venues): ingest-places-venues ho tro searchText (music box) ben canh searchNearby"
```

---

### Task 12: Harness verify + verify doc + final gates

**Files:**
- Create: `scripts/verify_payments_local.sh`
- Create: `docs/verify-maps-payments-2026-07-07.md` (kết quả chạy)

- [ ] **Step 1: Script**

```bash
#!/usr/bin/env bash
# scripts/verify_payments_local.sh
# Verify THAT (khong fake): crypto/HMAC that voi secret DUMMY trong supabase/functions/.env.
# Yeu cau: supabase start dang chay; .env da co MOMO_ACCESS_KEY/MOMO_SECRET_KEY/ZALOPAY_KEY2 dummy;
# docker restart supabase_edge_runtime_cung-hat sau khi doi .env.
set -euo pipefail
BASE="http://127.0.0.1:54321/functions/v1"
PSQL="docker exec supabase_db_cung-hat psql -U postgres -d postgres -t -A -c"
ACCESS="${MOMO_ACCESS_KEY:-dummyaccess}"
SECRET="${MOMO_SECRET_KEY:-dummysecret}"
KEY2="${ZALOPAY_KEY2:-dummykey2}"
PASS=0; FAIL=0
check() { local name="$1" want="$2" got="$3";
  if [ "$want" = "$got" ]; then echo "PASS  $name"; PASS=$((PASS+1));
  else echo "FAIL  $name (want=$want got=$got)"; FAIL=$((FAIL+1)); fi; }

REF="verify-$(date +%s)"
$PSQL "insert into public.venue_bookings (venue_id, amount_minor, gateway, gateway_ref, state) select id, booking_deposit_minor, 'momo', '$REF', 'initiated' from public.venues limit 1;" >/dev/null
AMT=$($PSQL "select amount_minor from public.venue_bookings where gateway_ref='$REF';")

# 1) MoMo IPN ky dung -> 204 + paid + commission 10%
RAW="accessKey=$ACCESS&amount=$AMT&extraData=&message=Success&orderId=$REF&orderInfo=test&orderType=momo_wallet&partnerCode=PC&payType=qr&requestId=r1&responseTime=1&resultCode=0&transId=99"
SIG=$(printf '%s' "$RAW" | openssl dgst -sha256 -hmac "$SECRET" -r | cut -d' ' -f1)
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/payments-webhook?gateway=momo" -H "Content-Type: application/json" -d "{\"partnerCode\":\"PC\",\"orderId\":\"$REF\",\"requestId\":\"r1\",\"amount\":$AMT,\"orderInfo\":\"test\",\"orderType\":\"momo_wallet\",\"transId\":99,\"resultCode\":0,\"message\":\"Success\",\"payType\":\"qr\",\"responseTime\":1,\"extraData\":\"\",\"signature\":\"$SIG\"}")
check "momo ipn signed -> 204" 204 "$CODE"
check "booking -> paid" "paid" "$($PSQL "select state from public.venue_bookings where gateway_ref='$REF';")"
check "commission 10%" "$((AMT/10))" "$($PSQL "select commission_minor from public.venue_bookings where gateway_ref='$REF';")"

# 2) idempotent: gui lai cung IPN -> 204, van paid
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/payments-webhook?gateway=momo" -H "Content-Type: application/json" -d "{\"partnerCode\":\"PC\",\"orderId\":\"$REF\",\"requestId\":\"r1\",\"amount\":$AMT,\"orderInfo\":\"test\",\"orderType\":\"momo_wallet\",\"transId\":99,\"resultCode\":0,\"message\":\"Success\",\"payType\":\"qr\",\"responseTime\":1,\"extraData\":\"\",\"signature\":\"$SIG\"}")
check "momo ipn replay -> 204 (idempotent)" 204 "$CODE"

# 3) tamper amount -> 401
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/payments-webhook?gateway=momo" -H "Content-Type: application/json" -d "{\"partnerCode\":\"PC\",\"orderId\":\"$REF\",\"requestId\":\"r1\",\"amount\":1,\"orderInfo\":\"test\",\"orderType\":\"momo_wallet\",\"transId\":99,\"resultCode\":0,\"message\":\"Success\",\"payType\":\"qr\",\"responseTime\":1,\"extraData\":\"\",\"signature\":\"$SIG\"}")
check "momo ipn tampered -> 401" 401 "$CODE"

# 4) ZaloPay callback ky dung -> return_code 1 + paid
REF2="verify-zlp-$(date +%s)"
$PSQL "insert into public.venue_bookings (venue_id, amount_minor, gateway, gateway_ref, state) select id, booking_deposit_minor, 'zalopay', '$REF2', 'initiated' from public.venues limit 1;" >/dev/null
AMT2=$($PSQL "select amount_minor from public.venue_bookings where gateway_ref='$REF2';")
DATA="{\"app_trans_id\":\"$REF2\",\"amount\":$AMT2,\"app_id\":1}"
MAC=$(printf '%s' "$DATA" | openssl dgst -sha256 -hmac "$KEY2" -r | cut -d' ' -f1)
BODY=$(python3 - "$DATA" "$MAC" <<'EOF'
import json,sys; print(json.dumps({"data": sys.argv[1], "mac": sys.argv[2], "type": 1}))
EOF
)
RET=$(curl -s -X POST "$BASE/payments-webhook?gateway=zalopay" -H "Content-Type: application/json" -d "$BODY")
check "zalopay callback signed -> return_code 1" "1" "$(printf '%s' "$RET" | grep -o '"return_code":[0-9-]*' | cut -d: -f2)"
check "zalopay booking -> paid" "paid" "$($PSQL "select state from public.venue_bookings where gateway_ref='$REF2';")"

# 5) ZaloPay mac sai -> return_code -1, state khong doi
REF3="verify-zlp2-$(date +%s)"
$PSQL "insert into public.venue_bookings (venue_id, amount_minor, gateway, gateway_ref, state) select id, booking_deposit_minor, 'zalopay', '$REF3', 'initiated' from public.venues limit 1;" >/dev/null
BODY_BAD=$(python3 - "{\"app_trans_id\":\"$REF3\",\"amount\":1,\"app_id\":1}" "deadbeef" <<'EOF'
import json,sys; print(json.dumps({"data": sys.argv[1], "mac": sys.argv[2], "type": 1}))
EOF
)
RET=$(curl -s -X POST "$BASE/payments-webhook?gateway=zalopay" -H "Content-Type: application/json" -d "$BODY_BAD")
check "zalopay bad mac -> return_code -1" "-1" "$(printf '%s' "$RET" | grep -o '"return_code":[0-9-]*' | cut -d: -f2)"
check "zalopay bad mac -> van initiated" "initiated" "$($PSQL "select state from public.venue_bookings where gateway_ref='$REF3';")"

# 6) validate-iap khong JWT -> 401; webhook gateway la -> 400
check "validate-iap no jwt -> 401" 401 "$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/validate-iap" -H "Content-Type: application/json" -d '{}')"
check "webhook unknown gateway -> 400" 400 "$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/payments-webhook?gateway=xyz" -H "Content-Type: application/json" -d '{}')"

# don dep
$PSQL "delete from public.venue_bookings where gateway_ref in ('$REF','$REF2','$REF3');" >/dev/null
echo "---"; echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]
```

Ghi chú cho implementer: nếu `python3` không có trên PATH Git Bash, thay khối BODY bằng nối chuỗi JSON escape tay (data là chuỗi JSON lồng — cần escape `"` thành `\"`).

- [ ] **Step 2: Chạy harness**

```bash
cd "/c/Users/Hwang Ming Hung/cung-hat-photos-wt"
grep -q MOMO_SECRET_KEY supabase/functions/.env || printf 'MOMO_ACCESS_KEY=dummyaccess\nMOMO_SECRET_KEY=dummysecret\nZALOPAY_KEY2=dummykey2\n' >> supabase/functions/.env
docker restart supabase_edge_runtime_cung-hat && sleep 3
bash scripts/verify_payments_local.sh
```
Expected: `PASS=11 FAIL=0` (exit 0).

- [ ] **Step 3: Full gates cuối đợt**

Run: `flutter.bat test && flutter.bat analyze && npx supabase test db`
Expected: toàn bộ xanh (dự kiến ≥250 Flutter + ≥140 pgTAP).

- [ ] **Step 4: Verify doc** — ghi `docs/verify-maps-payments-2026-07-07.md`: bảng kết quả harness (11 mục), kết quả gates, ghi chú những gì CHƯA verify được vì thiếu credential (map native, Places ingest thật, IAP mua thật, create-order sandbox thật) + lệnh sẽ chạy khi có credential.

- [ ] **Step 5: Commit**

```bash
git add scripts/verify_payments_local.sh docs/verify-maps-payments-2026-07-07.md
git commit -m "test(payments): harness verify HMAC self-signed + verify doc dot maps-payments"
```

- [ ] **Step 6: DỪNG** — final holistic review (requesting-code-review) rồi báo user quyết merge. KHÔNG tự merge.

---

## Credential gates (DỪNG hỏi user — KHÔNG fake để qua)

| Gate | Cần gì từ user | Mở khoá gì |
|---|---|---|
| Google Maps billing + keys | Maps SDK key (Android/iOS) + Places server key (lưu ý blocker billing vùng Ấn Độ — account US `…1412@gmail.com` ít ma sát hơn) | Map native trên emulator/device, Places ingest thật, density script |
| IAP store | App Store Connect + Play Console, 4 product id, `APPLE_SHARED_SECRET`, `GOOGLE_PLAY_SA_JSON`, package/bundle id | validate-iap chạy thật; mua thử cần build store + sandbox tester |
| MoMo/ZaloPay merchant | partnerCode/appId + khoá HMAC thật + IPN URL public (Supabase cloud) | create-order + IPN prod thật |

## Deferred có chủ đích
- iOS build không compile được trên Windows — AppDelegate/Info.plist chỉ review, verify khi có macOS/CI.
- Create-order sandbox THẬT (đánh vào test-payment.momo.vn / sb-openapi.zalopay.vn bằng sandbox creds công khai) — optional, chạy khi user gật ở gate duyệt plan (quyết định #2 trong spec).
- Per-venue deposit pricing (BD nhập giá từng quán) — v2.
- send-sms provider thật, FCM, `cunghat://` native scheme — operator gates P7, ngoài đợt.
