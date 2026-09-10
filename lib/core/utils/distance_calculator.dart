import 'dart:math';

class DistanceCalculator {
  // Earth's radius in kilometers
  static const double earthRadiusKm = 6371.0;

  // Haversine formula calculation
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  // Estimated driving time in Karachi traffic (avg speed: ~20 km/h in urban congestion)
  static int estimateEtaMinutes(double distanceKm) {
    if (distanceKm <= 0.5) return 3;
    final minutes = (distanceKm / 22.0) * 60.0;
    return minutes.round() + 4; // Add 4 mins baseline for traffic/stops
  }

  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
