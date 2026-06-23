import 'package:geolocator/geolocator.dart';
import '../data/discovery_repository.dart';

class LocationService {
  LocationService(this._repo);
  final DiscoveryRepository _repo;

  Future<void> pushPosition(double lat, double lng, {String? area}) =>
      _repo.updateMyLocation(lat, lng, area: area);

  /// Requests permission, reads the device position, pushes it (snapped server-side).
  /// Returns false (never throws) if services are off, permission denied, or no fix.
  Future<bool> captureAndPush() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return false;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await pushPosition(pos.latitude, pos.longitude);
      return true;
    } catch (_) {
      return false;
    }
  }
}
