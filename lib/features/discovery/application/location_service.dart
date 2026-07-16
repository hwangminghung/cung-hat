import 'package:geolocator/geolocator.dart';
import '../data/discovery_repository.dart';

/// Kết quả một lần bắt + đẩy vị trí — UI cần NGUYÊN NHÂN (P0-1) để không đổ
/// lỗi "hết người quanh đây" khi thật ra là thiếu quyền/GPS tắt/mạng lỗi.
enum LocationCaptureStatus {
  success,
  /// Định vị hệ thống (GPS/Location Services) đang tắt.
  serviceDisabled,
  /// User từ chối quyền (gồm cả deniedForever — chỉ mở app settings mới gỡ được).
  permissionDenied,
  /// Có quyền nhưng không bắt được fix và không có vị trí cache.
  noFix,
  /// Bắt được vị trí nhưng đẩy lên server lỗi (RPC/offline).
  pushFailed,
}

class LocationService {
  LocationService(this._repo);
  final DiscoveryRepository _repo;

  Future<void> pushPosition(double lat, double lng, {String? area}) =>
      _repo.updateMyLocation(lat, lng, area: area);

  /// Requests permission and reads the device position. Returns null (never throws)
  /// if services are off, permission denied, or no fix.
  Future<Position?> currentPosition() async {
    if (await _gatekeep() != null) return null;
    return _fix();
  }

  /// Requests permission, reads the device position, pushes it (snapped
  /// server-side). Never throws — trả [LocationCaptureStatus] để UI phân biệt
  /// đúng nguyên nhân thay vì nuốt lỗi thành deck/board rỗng.
  Future<LocationCaptureStatus> captureAndPush() async {
    final blocked = await _gatekeep();
    if (blocked != null) return blocked;
    final pos = await _fix();
    if (pos == null) return LocationCaptureStatus.noFix;
    try {
      await pushPosition(pos.latitude, pos.longitude);
    } catch (_) {
      return LocationCaptureStatus.pushFailed;
    }
    return LocationCaptureStatus.success;
  }

  /// Mở đúng màn cài đặt cho từng nguyên nhân: GPS tắt → cài đặt định vị hệ
  /// thống; thiếu quyền → cài đặt của app (đường duy nhất khi deniedForever).
  Future<bool> openSettingsFor(LocationCaptureStatus status) =>
      status == LocationCaptureStatus.serviceDisabled
          ? Geolocator.openLocationSettings()
          : Geolocator.openAppSettings();

  /// null = được phép đọc vị trí; khác null = lý do bị chặn.
  Future<LocationCaptureStatus?> _gatekeep() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationCaptureStatus.serviceDisabled;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return LocationCaptureStatus.permissionDenied;
    }
    return null;
  }

  Future<Position?> _fix() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }
}
