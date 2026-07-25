import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/domain/venue_suggestion.dart';
import 'package:cung_hat/features/plan/presentation/venue_map_surface.dart';

VenueSuggestion _venue(String id, double lat, double lng) => VenueSuggestion(
  id: id,
  name: 'V$id',
  address: 'A',
  styleTag: 'k_style',
  photos: const [],
  distanceBand: '<1',
  lat: lat,
  lng: lng,
);

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('fallback ve pin midpoint khi co midpoint', (tester) async {
    await tester.pumpWidget(
      wrap(
        VenueMapSurface(
          venues: [_venue('v1', 21.02, 105.85), _venue('v2', 21.04, 105.86)],
          midpoint: const MapPoint(lat: 21.03, lng: 105.855),
          useNativeMap: false,
          onVenueSelected: (_) {},
        ),
      ),
    );
    expect(find.byKey(const Key('midpoint_marker')), findsOneWidget);
    expect(find.byKey(const Key('venue_marker_v1')), findsOneWidget);
  });

  testWidgets('khong co midpoint -> khong co pin midpoint', (tester) async {
    await tester.pumpWidget(
      wrap(
        VenueMapSurface(
          venues: [_venue('v1', 21.02, 105.85)],
          useNativeMap: false,
          onVenueSelected: (_) {},
        ),
      ),
    );
    expect(find.byKey(const Key('midpoint_marker')), findsNothing);
  });

  testWidgets('host: pin la nut bam duoc, tra ve dung venue', (tester) async {
    VenueSuggestion? picked;
    await tester.pumpWidget(
      wrap(
        VenueMapSurface(
          venues: [_venue('v1', 21.02, 105.85)],
          useNativeMap: false,
          onVenueSelected: (v) => picked = v,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('venue_marker_v1')));
    await tester.pump();
    expect(picked?.id, 'v1');
  });

  // [AUDIT] Truoc day plan_screen truyen `(_) {}` cho thanh vien: pin van la
  // IconButton.filled co tooltip nen trong nhu bam duoc, bam lai khong xay ra
  // gi va cung khong bao vi sao. Pin phai het la nut khi khong duoc chon quan.
  testWidgets('khong phai host: pin van thay nhung khong bam duoc', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        VenueMapSurface(
          venues: [_venue('v1', 21.02, 105.85)],
          useNativeMap: false,
          onVenueSelected: null,
        ),
      ),
    );
    final marker = find.byKey(const Key('venue_marker_v1'));
    expect(marker, findsOneWidget, reason: 'van phai thay vi tri quan');
    expect(
      find.descendant(of: marker, matching: find.byType(IconButton)),
      findsNothing,
      reason: 'khong duoc render nhu nut bam duoc',
    );
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('venues rong + co midpoint -> van ve midpoint', (tester) async {
    await tester.pumpWidget(
      wrap(
        VenueMapSurface(
          venues: const [],
          midpoint: const MapPoint(lat: 21.03, lng: 105.855),
          useNativeMap: false,
          onVenueSelected: (_) {},
        ),
      ),
    );
    expect(find.byKey(const Key('midpoint_marker')), findsOneWidget);
  });
}
