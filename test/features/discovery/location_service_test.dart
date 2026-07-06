import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';

class _MockRepo extends Mock implements DiscoveryRepository {}

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  _FakeGeolocatorPlatform({this.lastKnown, this.failCurrent = false});

  final Position? lastKnown;
  final bool failCurrent;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.always;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (failCurrent) throw const LocationServiceDisabledException();
    return _position(10.77, 106.70);
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => lastKnown;
}

Position _position(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026, 6, 29),
  accuracy: 25,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late GeolocatorPlatform originalGeolocator;

  setUp(() {
    originalGeolocator = GeolocatorPlatform.instance;
  });

  tearDown(() {
    GeolocatorPlatform.instance = originalGeolocator;
  });

  test('pushPosition forwards lat/lng/area to the repo', () async {
    final repo = _MockRepo();
    when(
      () => repo.updateMyLocation(any(), any(), area: any(named: 'area')),
    ).thenAnswer((_) async {});
    await LocationService(repo).pushPosition(10.77, 106.70, area: 'Q1');
    verify(() => repo.updateMyLocation(10.77, 106.70, area: 'Q1')).called(1);
  });

  test(
    'currentPosition falls back to last known position when current fix fails',
    () async {
      final cached = _position(10.776889, 106.700981);
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        failCurrent: true,
        lastKnown: cached,
      );

      final pos = await LocationService(_MockRepo()).currentPosition();

      expect(pos?.latitude, 10.776889);
      expect(pos?.longitude, 106.700981);
    },
  );
}
