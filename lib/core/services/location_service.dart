import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double defaultKarachiLat = 24.8607;
  static const double defaultKarachiLng = 67.0011;

  /// Check if device location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('LocationService.isLocationServiceEnabled error: $e');
      return false;
    }
  }

  /// Request runtime location permissions from the user
  Future<LocationPermission> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission;
    } catch (e) {
      debugPrint('LocationService.requestPermission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Attempt to fetch real GPS coordinates with a 5-second timeout
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('LocationService.getCurrentPosition error: $e');
      return null;
    }
  }

  /// Fetches real device coordinates or gracefully falls back to Karachi City Center
  Future<({double lat, double lng})> getCoordinatesWithFallback() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return (lat: position.latitude, lng: position.longitude);
    }
    return (lat: defaultKarachiLat, lng: defaultKarachiLng);
  }
}
