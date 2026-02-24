import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Result returned by [LocationService.getCurrentLocation].
class LocationResult {
  /// Decimal-degree coordinates, e.g. "-1.2921,36.8219"
  final String coordinates;

  /// Human-readable address, e.g. "Nairobi North Station, Nairobi, Kenya"
  final String address;

  const LocationResult({
    required this.coordinates,
    required this.address,
  });
}

/// Wraps [Geolocator] and [Geocoding] behind a single async call.
///
/// Handles permission requests, service-disabled errors, and reverse-
/// geocoding. Throws a [LocationException] with a user-readable message
/// so callers can show it directly in the UI.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Requests permission if needed and returns the current position
  /// with a human-readable address via reverse geocoding.
  ///
  /// Throws [LocationException] on permission denial or service off.
  Future<LocationResult> getCurrentLocation() async {
    // 1. Check if location services are enabled on the device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled on this device.');
    }

    // 2. Check / request permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Location permission denied. Enable it in Settings.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission permanently denied. Open Settings to allow.',
      );
    }

    // 3. Get position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );

    // 4. Reverse-geocode to a human-readable address
    final coords = '${position.latitude.toStringAsFixed(6)},'
        '${position.longitude.toStringAsFixed(6)}';

    String address = coords; // fallback if geocoding fails
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.name,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((s) => s != null && s.isNotEmpty).toList();
        address = parts.join(', ');
      }
    } catch (_) {
      // Geocoding failed — coords are still valid
    }

    return LocationResult(coordinates: coords, address: address);
  }
}

/// Thrown by [LocationService] when GPS cannot be obtained.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
  @override
  String toString() => 'LocationException: $message';
}
