import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/venue_suggestion.dart';

const _googleMapsEnabled = bool.fromEnvironment('GOOGLE_MAPS_ENABLED');

class VenueMapSurface extends StatelessWidget {
  const VenueMapSurface({
    super.key,
    required this.venues,
    required this.onVenueSelected,
    this.useNativeMap = true,
  });

  final List<VenueSuggestion> venues;
  final ValueChanged<VenueSuggestion> onVenueSelected;
  final bool useNativeMap;

  List<VenueSuggestion> get _mappable =>
      venues.where((v) => v.lat != null && v.lng != null).toList();

  @override
  Widget build(BuildContext context) {
    final mappable = _mappable;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          key: const Key('venue_map_surface'),
          height: 220,
          child: mappable.isEmpty
              ? _MapFallback(venues: venues, onVenueSelected: onVenueSelected)
              : useNativeMap && _googleMapsEnabled
              ? _NativeVenueMap(
                  venues: mappable,
                  onVenueSelected: onVenueSelected,
                )
              : _MapFallback(
                  venues: mappable,
                  onVenueSelected: onVenueSelected,
                ),
        ),
      ),
    );
  }
}

class _NativeVenueMap extends StatelessWidget {
  const _NativeVenueMap({required this.venues, required this.onVenueSelected});

  final List<VenueSuggestion> venues;
  final ValueChanged<VenueSuggestion> onVenueSelected;

  LatLng get _center {
    final lat =
        venues.map((v) => v.lat!).reduce((a, b) => a + b) / venues.length;
    final lng =
        venues.map((v) => v.lng!).reduce((a, b) => a + b) / venues.length;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: venues.length == 1 ? 14 : 12,
      ),
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
      },
    );
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.venues, required this.onVenueSelected});

  final List<VenueSuggestion> venues;
  final ValueChanged<VenueSuggestion> onVenueSelected;

  @override
  Widget build(BuildContext context) {
    final mappable = venues
        .where((v) => v.lat != null && v.lng != null)
        .toList();
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
              if (mappable.isEmpty)
                const Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 44,
                    color: Colors.black45,
                  ),
                )
              else
                for (final venue in mappable)
                  _PositionedVenueMarker(
                    venue: venue,
                    venues: mappable,
                    size: constraints.biggest,
                    onVenueSelected: onVenueSelected,
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _PositionedVenueMarker extends StatelessWidget {
  const _PositionedVenueMarker({
    required this.venue,
    required this.venues,
    required this.size,
    required this.onVenueSelected,
  });

  final VenueSuggestion venue;
  final List<VenueSuggestion> venues;
  final Size size;
  final ValueChanged<VenueSuggestion> onVenueSelected;

  double _scale(
    double value,
    double min,
    double max,
    double start,
    double end,
  ) {
    if ((max - min).abs() < 0.000001) {
      return start + (end - start) / 2;
    }
    return start + ((value - min) / (max - min)) * (end - start);
  }

  @override
  Widget build(BuildContext context) {
    final minLat = venues.map((v) => v.lat!).reduce(math.min);
    final maxLat = venues.map((v) => v.lat!).reduce(math.max);
    final minLng = venues.map((v) => v.lng!).reduce(math.min);
    final maxLng = venues.map((v) => v.lng!).reduce(math.max);
    final x = _scale(venue.lng!, minLng, maxLng, 28, size.width - 28);
    final y = _scale(venue.lat!, maxLat, minLat, 28, size.height - 28);

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
