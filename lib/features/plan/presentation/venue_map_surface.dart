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

class _PositionedVenueMarker extends StatelessWidget {
  const _PositionedVenueMarker({
    required this.venue,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.size,
    required this.onVenueSelected,
  });

  final VenueSuggestion venue;
  final double minLat, maxLat, minLng, maxLng;
  final Size size;
  final ValueChanged<VenueSuggestion> onVenueSelected;

  @override
  Widget build(BuildContext context) {
    final x = _scalePos(venue.lng!, minLng, maxLng, 28, size.width - 28);
    final y = _scalePos(venue.lat!, maxLat, minLat, 28, size.height - 28);

    return Positioned(
      left: x - 24,
      top: y - 24,
      child: IconButton.filled(
        key: Key('venue_marker_${venue.id}'),
        tooltip: venue.name,
        onPressed: () => onVenueSelected(venue),
        icon: const Icon(Icons.location_on),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final thinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..strokeWidth = 1;

    for (var x = -size.height; x < size.width; x += 48) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        thinPaint,
      );
    }
    for (var y = 28.0; y < size.height; y += 54) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 18), roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
