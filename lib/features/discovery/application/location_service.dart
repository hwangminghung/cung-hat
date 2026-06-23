import 'package:geolocator/geolocator.dart';
import '../data/discovery_repository.dart';

class LocationService {
  LocationService(this._repo);
  final DiscoveryRepository _repo;

  Future<void> pushPosition(double lat, double lng, {String? area}) =>
      _repo.updateMyLocation(lat, lng, area: area);

  /// Requests permission, reads the device position, pushes it (snapped server-side).
  Future<bool> captureAndPush() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return false;
    }
    final pos = await Geolocator.getCurrentPosition();
    await pushPosition(pos.latitude, pos.longitude);
    return true;
  }
}
