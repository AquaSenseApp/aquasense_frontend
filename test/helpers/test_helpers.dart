// test/helpers/test_helpers.dart
//
// Shared fixtures and setup utilities used by every test file.
// Import this at the top of each test — never duplicate setup logic.
//
// WHY a single helpers file?
//   If each test file creates its own UserModel or SensorModel, a field rename
//   breaks a dozen files.  Centralising fixtures means one change fixes all.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquasense/models/alert_model.dart';
import 'package:aquasense/models/sensor_model.dart';
import 'package:aquasense/models/user_model.dart';

// ignore_for_file: unused_import
export 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences fake
// ─────────────────────────────────────────────────────────────────────────────

/// Seeds SharedPreferences with [values] and resets it to in-memory defaults.
///
/// Call inside [setUp] before any test that touches prefs.
/// Flutter's test runner uses an in-memory implementation — nothing touches
/// disk and state does not survive between test cases.
void setupFakeSharedPrefs([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
}

// ─────────────────────────────────────────────────────────────────────────────
// Canonical fixtures
// ─────────────────────────────────────────────────────────────────────────────

/// A fully-authenticated user — has userId, token, isEmailVerified = true.
final kAuthenticatedUser = UserModel(
  userId:           1,
  email:            'test@aquasense.io',
  username:         'TestUser',
  fullName:         'Test User',
  organizationType: 'School',
  token:            'eyJ.test.token',
  isEmailVerified:  true,
  rememberMe:       false,
);

/// A registered user whose email is still unverified (awaiting OTP).
final kUnverifiedUser = UserModel(
  userId:          2,
  email:           'pending@aquasense.io',
  isEmailVerified: false,
);

/// Creates a [SensorModel] with sensible defaults for tests.
SensorModel makeSensor({
  String        id       = 'AQ-PH-001',
  String        name     = 'Test Sensor',
  String        location = 'Test Location',
  ParameterType param    = ParameterType.pH,
  RiskLevel     risk     = RiskLevel.medium,
  int?          apiId,
  String?       apiKey,
}) =>
    SensorModel(
      id:            id,
      apiId:         apiId,
      apiKey:        apiKey,
      name:          name,
      location:      location,
      parameter:     param,
      riskLevel:     risk,
      latestReading: SensorReading(
        value:     7.0,
        parameter: param,
        trend:     TrendDirection.stable,
        timestamp: DateTime(2026, 1, 1, 12),
      ),
      advisory: const AiAdvisory(
        headline:           'Stable',
        impactExplanation:  'All parameters within range.',
        recommendedActions: ['Continue monitoring.'],
        impactNotes:        '',
      ),
    );

/// Creates an active [AlertModel] with a known apiId.
AlertModel makeAlert({
  String    id        = 'alert-1',
  int?      apiId     = 1,
  AlertType type      = AlertType.alert,
  String    status    = 'active',
  String    title     = 'pH is low',
  String    desc      = 'Advisory: treat with alkaline solution.',
  DateTime? timestamp,
}) =>
    AlertModel(
      id:          id,
      apiId:       apiId,
      title:       title,
      description: desc,
      reading:     '3.0 pH',
      safeRange:   '6.5 – 8.5',
      type:        type,
      status:      status,
      timestamp:   timestamp ?? DateTime(2026, 2, 24, 10, 29),
    );

/// Rebuilds an [AlertModel] with a different timestamp (AlertModel is immutable).
AlertModel alertAt(AlertModel a, DateTime ts) => AlertModel(
  id:          a.id,
  apiId:       a.apiId,
  title:       a.title,
  description: a.description,
  reading:     a.reading,
  safeRange:   a.safeRange,
  type:        a.type,
  status:      a.status,
  timestamp:   ts,
);
