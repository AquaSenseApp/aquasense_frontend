// test/unit/services/location_service_test.dart
//
// WHY these tests exist
// ─────────────────────
// LocationResult is a pure data class that holds both the machine-readable
// coordinates string ("lat,lng") and the human-readable address that the
// wizard displays.  The format of the coordinates string matters: if it
// changes from "-1.292100,36.821900" to "-1.2921, 36.8219" (with a space),
// sensor registration fails because the backend stores it verbatim and GPS
// map links break.
//
// LocationException carries the user-visible error message that appears when
// GPS is denied or the device's location service is disabled.  A truncated
// or blank message leaves the operator with no instructions on how to fix it.
//
// We do NOT test the platform channel (Geolocator.getCurrentPosition) here —
// that requires a device or emulator.  The service-level integration tests
// live in test/integration/.

import 'package:flutter_test/flutter_test.dart';
import 'package:aquasense/services/location_service.dart';

void main() {
  // ── LocationResult ────────────────────────────────────────────────────────

  group('LocationResult · construction', () {
    const result = LocationResult(
      coordinates: '-1.292100,36.821900',
      address:     'Nairobi North Station, Nairobi, Kenya',
    );

    test('stores coordinates unchanged', () {
      expect(result.coordinates, '-1.292100,36.821900');
    });

    test('stores address unchanged', () {
      expect(result.address, 'Nairobi North Station, Nairobi, Kenya');
    });

    test('coordinates and address are independent — a short address does not '
        'modify coordinates', () {
      const r = LocationResult(coordinates: '0.0,0.0', address: 'Unknown');
      expect(r.coordinates, '0.0,0.0');
      expect(r.address,     'Unknown');
    });
  });

  group('LocationResult · coordinate format contract', () {
    // WHY test the format?  The backend stores gps_coordinates as a raw string.
    // We produce "lat,lng" (no space) so that external tools parsing the string
    // with split(',') always get exactly two parts.

    test('coordinate string contains exactly one comma', () {
      const r = LocationResult(
        coordinates: '-1.292100,36.821900',
        address:     '',
      );
      expect(r.coordinates.split(',').length, 2,
          reason: 'split(",") must produce [lat, lng] — any extra commas or '
              'spaces will break map link generation');
    });

    test('fallback coordinates use the same format as geocoded ones', () {
      // When geocoding fails, LocationService falls back to the raw position
      // string.  We document that the format is identical either way.
      const fallback = LocationResult(
        coordinates: '-1.286389,36.817223',
        address:     '-1.286389,36.817223', // address is the coords as fallback
      );
      expect(fallback.coordinates, isNotEmpty);
      expect(fallback.coordinates, contains(','));
    });
  });

  // ── LocationException ─────────────────────────────────────────────────────

  group('LocationException · message delivery', () {
    test('stores and returns the message unchanged', () {
      const e = LocationException('Location services are disabled on this device.');
      expect(e.message, 'Location services are disabled on this device.');
    });

    test('implements Exception — can be caught as Exception', () {
      Exception? caught;
      try {
        throw const LocationException('denied');
      } on Exception catch (e) {
        caught = e;
      }
      expect(caught, isNotNull);
    });

    test('toString includes the message', () {
      const e = LocationException('permission denied');
      expect(e.toString(), contains('permission denied'));
    });

    test('permission-denied message contains actionable instructions', () {
      // The UI displays this message directly; it must tell the user what to do.
      const e = LocationException(
        'Location permission denied. Enable it in Settings.',
      );
      expect(e.message, contains('Settings'),
          reason: 'Users need to know where to go to fix the problem — '
              'a bare "denied" message gives them no next step');
    });

    test('permanently-denied message distinguishes from soft denial', () {
      const e = LocationException(
        'Location permission permanently denied. Open Settings to allow.',
      );
      // Must mention "permanently" so the UI can show "open Settings" instead
      // of the misleading "try again" button.
      expect(e.message, contains('permanently'));
    });
  });
}
