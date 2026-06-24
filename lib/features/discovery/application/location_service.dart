import 'package:geolocator/geolocator.dart';
import '../data/discovery_repository.dart';

class LocationService {
  LocationService(this._repo);
  final DiscoveryRepository _repo;

  Future<void> pushPosition(double lat, double lng, {String? area}) =>
      _repo.updateMyLocation(lat, lng, area: area);

  /// Requests permission and reads the device position. Returns null (never throws)
  /// if services are off, permission denied, or no fix.
  Future<Position?> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)),
      );
    } catch (_) {
      return null;
    }
  }

  /// Requests permission, reads the device position, pushes it (snapped server-side).
  /// Returns false (never throws) if services are off, permission denied, or no fix.
  Future<bool> captureAndPush() async {
    final pos = await currentPosition();
    if (pos == null) return false;
    await pushPosition(pos.latitude, pos.longitude);
    return true;
  }
}
