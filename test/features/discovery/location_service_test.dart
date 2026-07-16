import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';

class _MockRepo extends Mock implements DiscoveryRepository {}

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  _FakeGeolocatorPlatform({
    this.serviceEnabled = true,
    this.checkResult = LocationPermission.always,
    this.requestResult = LocationPermission.always,
    this.lastKnown,
    this.failCurrent = false,
  });

  final bool serviceEnabled;
  final LocationPermission checkResult;
  final LocationPermission requestResult;
  final Position? lastKnown;
  final bool failCurrent;

  bool openedAppSettings = false;
  bool openedLocationSettings = false;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => checkResult;

  @override
  Future<LocationPermission> requestPermission() async => requestResult;

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

  @override
  Future<bool> openAppSettings() async {
    openedAppSettings = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openedLocationSettings = true;
    return true;
  }
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

  _MockRepo pushOkRepo() {
    final repo = _MockRepo();
    when(
      () => repo.updateMyLocation(any(), any(), area: any(named: 'area')),
    ).thenAnswer((_) async {});
    return repo;
  }

  test('pushPosition forwards lat/lng/area to the repo', () async {
    final repo = pushOkRepo();
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

  group('captureAndPush trả reason thay vì bool (P0-1)', () {
    test('định vị hệ thống tắt → serviceDisabled', () async {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        serviceEnabled: false,
      );

      final status = await LocationService(_MockRepo()).captureAndPush();

      expect(status, LocationCaptureStatus.serviceDisabled);
    });

    test('user từ chối quyền sau khi được hỏi → permissionDenied', () async {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        checkResult: LocationPermission.denied,
        requestResult: LocationPermission.denied,
      );

      final status = await LocationService(_MockRepo()).captureAndPush();

      expect(status, LocationCaptureStatus.permissionDenied);
    });

    test('quyền bị chặn vĩnh viễn (deniedForever) → permissionDenied', () async {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        checkResult: LocationPermission.deniedForever,
      );

      final status = await LocationService(_MockRepo()).captureAndPush();

      expect(status, LocationCaptureStatus.permissionDenied);
    });

    test('không bắt được fix và không có vị trí cache → noFix', () async {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        failCurrent: true,
        lastKnown: null,
      );

      final status = await LocationService(_MockRepo()).captureAndPush();

      expect(status, LocationCaptureStatus.noFix);
    });

    test('đẩy vị trí lên server lỗi (RPC/offline) → pushFailed', () async {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
      final repo = _MockRepo();
      when(
        () => repo.updateMyLocation(any(), any(), area: any(named: 'area')),
      ).thenThrow(Exception('network'));

      final status = await LocationService(repo).captureAndPush();

      expect(status, LocationCaptureStatus.pushFailed);
    });

    test('có quyền + có fix + push OK → success và đẩy đúng lat/lng', () async {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
      final repo = pushOkRepo();

      final status = await LocationService(repo).captureAndPush();

      expect(status, LocationCaptureStatus.success);
      verify(() => repo.updateMyLocation(10.77, 106.70)).called(1);
    });

    test('fix hiện tại lỗi nhưng có cache → success bằng last known', () async {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        failCurrent: true,
        lastKnown: _position(21.028, 105.854),
      );
      final repo = pushOkRepo();

      final status = await LocationService(repo).captureAndPush();

      expect(status, LocationCaptureStatus.success);
      verify(() => repo.updateMyLocation(21.028, 105.854)).called(1);
    });
  });

  group('openSettingsFor', () {
    test('serviceDisabled → mở cài đặt định vị hệ thống', () async {
      final fake = _FakeGeolocatorPlatform();
      GeolocatorPlatform.instance = fake;

      await LocationService(_MockRepo())
          .openSettingsFor(LocationCaptureStatus.serviceDisabled);

      expect(fake.openedLocationSettings, isTrue);
      expect(fake.openedAppSettings, isFalse);
    });

    test('permissionDenied → mở cài đặt của app', () async {
      final fake = _FakeGeolocatorPlatform();
      GeolocatorPlatform.instance = fake;

      await LocationService(_MockRepo())
          .openSettingsFor(LocationCaptureStatus.permissionDenied);

      expect(fake.openedAppSettings, isTrue);
      expect(fake.openedLocationSettings, isFalse);
    });
  });
}
