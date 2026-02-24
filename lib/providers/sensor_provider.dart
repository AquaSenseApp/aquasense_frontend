import 'package:flutter/material.dart';
import '../core/errors/api_exception.dart';
import '../models/sensor_model.dart';
import '../models/user_model.dart';
import '../services/sensor_service.dart';

/// Possible states for any async data load.
enum LoadState { initial, loading, loaded, error }

/// Identifies which screen owns a search query.
enum SensorSearchScope { home, sensors }

// ─────────────────────────────────────────────────────────────────────────────
// SensorProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Central state manager for sensors, search, wizard, and editing.
///
/// Fetches from GET /api/sensors/user/{userId} via [SensorService].
/// Converts [ApiSensorDto] → [SensorModel] with sensible defaults for
/// fields the backend doesn't yet return (advisory, reading, riskLevel).
class SensorProvider extends ChangeNotifier {
  SensorProvider(UserModel? user) : _user = user;

  UserModel? _user;

  /// Called by ProxyProvider when auth state changes (login / logout).
  void updateUser(UserModel? user) {
    if (_user?.userId == user?.userId) return; // no change
    _user = user;
    if (user != null) loadSensors();
  }

  // ── Sensor list ───────────────────────────────────────────────────────────

  List<SensorModel> _sensors = [];
  LoadState _loadState       = LoadState.initial;
  String?   _errorMessage;

  List<SensorModel> get sensors      => _sensors;
  LoadState         get loadState    => _loadState;
  String?           get errorMessage => _errorMessage;
  bool              get isLoading    => _loadState == LoadState.loading;

  List<SensorModel> recentSensors({int count = 3}) =>
      _sensors.take(count).toList();

  /// Fetches sensors for the authenticated user from the real API.
  Future<void> loadSensors() async {
    final userId = _user?.userId;
    if (userId == null) return;

    _loadState    = LoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final dtos = await SensorService.instance.getSensorsForUser(userId);
      _sensors   = dtos.map(_dtoToModel).toList();
      _loadState = LoadState.loaded;
    } on ApiException catch (e) {
      _loadState    = LoadState.error;
      _errorMessage = e.displayMessage;
    }
    notifyListeners();
  }

  /// Converts an API DTO to the rich UI [SensorModel].
  SensorModel _dtoToModel(ApiSensorDto dto) {
    return SensorModel(
      id:     dto.id.toString(),
      apiId:  dto.id,
      apiKey: dto.apiKey,
      name:   dto.name,
      location: dto.location,
      parameter: dto.parameterType,
      riskLevel: RiskLevel.medium, // default until analytics returns data
      latestReading: SensorReading(
        value:     0,
        parameter: dto.parameterType,
        trend:     TrendDirection.stable,
        timestamp: DateTime.now(),
      ),
      advisory: const AiAdvisory(
        headline:           'Awaiting first reading',
        impactExplanation:  'Upload a reading to generate an advisory.',
        recommendedActions: ['Upload sensor data to begin monitoring.'],
        impactNotes:        '',
      ),
    );
  }

  // ── Per-screen search ─────────────────────────────────────────────────────

  final Map<SensorSearchScope, String> _queries = {};

  void setSearchQuery(String query, {required SensorSearchScope scope}) {
    _queries[scope] = query.toLowerCase();
    notifyListeners();
  }

  void clearSearch({required SensorSearchScope scope}) {
    _queries.remove(scope);
    notifyListeners();
  }

  List<SensorModel> filteredSensors({required SensorSearchScope scope}) {
    final q = _queries[scope] ?? '';
    if (q.isEmpty) return _sensors;
    return _sensors.where((s) =>
      s.id.toLowerCase().contains(q)       ||
      s.name.toLowerCase().contains(q)     ||
      s.location.toLowerCase().contains(q) ||
      s.parameter.label.toLowerCase().contains(q),
    ).toList();
  }

  List<SensorModel> filteredRecentSensors({int count = 3}) =>
      filteredSensors(scope: SensorSearchScope.home).take(count).toList();

  // ── Register sensor via API ───────────────────────────────────────────────

  bool _registerLoading = false;
  bool get registerLoading => _registerLoading;

  /// Calls POST /api/sensors/register then appends the new sensor to the list.
  Future<SensorModel?> registerSensor({
    required String sensorName,
    required String sensorType,
    required String location,
  }) async {
    final userId = _user?.userId;
    if (userId == null) return null;

    _registerLoading = true;
    notifyListeners();
    try {
      final result = await SensorService.instance.registerSensor(
        sensorName: sensorName,
        sensorType: sensorType,
        location:   location,
        userId:     userId,
      );

      final newSensor = SensorModel(
        id:       result.sensorId.toString(),
        apiId:    result.sensorId,
        apiKey:   result.apiKey,
        name:     sensorName,
        location: location,
        parameter: _typeToParam(sensorType),
        riskLevel: RiskLevel.medium,
        latestReading: SensorReading(
          value:     0,
          parameter: _typeToParam(sensorType),
          trend:     TrendDirection.stable,
          timestamp: DateTime.now(),
        ),
        advisory: const AiAdvisory(
          headline:           'Awaiting first reading',
          impactExplanation:  'Upload a reading to generate an advisory.',
          recommendedActions: ['Upload sensor data to begin monitoring.'],
          impactNotes:        '',
        ),
      );

      _sensors = [..._sensors, newSensor];
      _registerLoading = false;
      notifyListeners();
      return newSensor;
    } on ApiException catch (e) {
      _errorMessage    = e.displayMessage;
      _registerLoading = false;
      notifyListeners();
      return null;
    }
  }

  ParameterType _typeToParam(String type) {
    final t = type.toLowerCase();
    if (t.contains('ph'))       return ParameterType.pH;
    if (t.contains('turbid'))   return ParameterType.turbidity;
    if (t.contains('oxygen'))   return ParameterType.dissolvedOxygen;
    if (t.contains('temp'))     return ParameterType.temperature;
    if (t.contains('conduct'))  return ParameterType.conductivity;
    return ParameterType.other;
  }

  // ── Edit sensor (local update) ────────────────────────────────────────────

  bool _editLoading = false;
  bool get editLoading => _editLoading;

  Future<bool> updateSensor(SensorModel original, EditSensorForm form) async {
    _editLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    final updated = original.copyWith(
      name:              form.name.isNotEmpty ? form.name : original.name,
      location:          form.location.isNotEmpty ? form.location : original.location,
      safeRange:         form.safeRange,
      alertThreshold:    form.alertThreshold,
      aiAdvisoryEnabled: form.aiAdvisoryEnabled,
      sensitivityLevel:  form.sensitivityLevel,
    );

    final idx = _sensors.indexWhere((s) => s.id == original.id);
    if (idx >= 0) _sensors = List.of(_sensors)..[idx] = updated;

    _editLoading = false;
    notifyListeners();
    return true;
  }

  // ── Add Sensor wizard (kept for sheet UI compatibility) ───────────────────

  static const int totalWizardSteps = 5;
  static const int lastWizardStep   = totalWizardSteps - 1;

  AddSensorForm _form         = AddSensorForm();
  int           _wizardStep   = 0;
  bool          _addingLoading = false;

  AddSensorForm get form          => _form;
  int           get wizardStep    => _wizardStep;
  bool          get addingLoading => _addingLoading;
  bool          get isLastStep    => _wizardStep == lastWizardStep;

  void nextWizardStep() {
    if (_wizardStep < lastWizardStep) { _wizardStep++; notifyListeners(); }
  }
  void prevWizardStep() {
    if (_wizardStep > 0) { _wizardStep--; notifyListeners(); }
  }
  void resetWizard() {
    _form        = AddSensorForm();
    _wizardStep  = 0;
    _addingLoading = false;
    notifyListeners();
  }
  void updateForm() => notifyListeners();

  bool get canAdvance {
    switch (_wizardStep) {
      case 0: return _form.step1Valid;
      case 1: return _form.step2Valid;
      default: return true;
    }
  }

  /// On the final wizard step, calls the real API to register the sensor.
  Future<SensorModel?> submitSensor() async {
    _addingLoading = true;
    notifyListeners();

    final sensor = await registerSensor(
      sensorName: _form.sensorName,
      sensorType: _form.parameterType?.label ?? 'Other',
      location:   '${_form.specificLocation}, ${_form.site}',
    );

    _addingLoading = false;
    notifyListeners();
    return sensor;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EditSensorForm
// ─────────────────────────────────────────────────────────────────────────────

class EditSensorForm {
  String name;
  String location;
  String safeRange;
  AlertThreshold? alertThreshold;
  bool aiAdvisoryEnabled;
  RiskSensitivityLevel? sensitivityLevel;

  EditSensorForm({
    required this.name,
    required this.location,
    required this.safeRange,
    required this.alertThreshold,
    required this.aiAdvisoryEnabled,
    required this.sensitivityLevel,
  });

  factory EditSensorForm.fromSensor(SensorModel sensor) => EditSensorForm(
    name:              sensor.name,
    location:          sensor.location,
    safeRange:         sensor.safeRange,
    alertThreshold:    sensor.alertThreshold,
    aiAdvisoryEnabled: sensor.aiAdvisoryEnabled,
    sensitivityLevel:  sensor.sensitivityLevel,
  );

  bool get isValid => name.isNotEmpty && location.isNotEmpty;
}
