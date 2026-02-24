import 'package:flutter/material.dart';
import '../core/errors/api_exception.dart';
import '../models/alert_model.dart';
import '../models/user_model.dart';
import '../services/alert_service.dart';

enum AlertLoadState { initial, loading, loaded, error }

/// Manages alert list, filter, search, and resolving alerts via real API.
///
/// Constructed with the authenticated [UserModel] so it can fetch
/// alerts for the correct userId immediately.
class AlertProvider extends ChangeNotifier {
  AlertProvider(UserModel? user) : _user = user {
    if (_user != null) loadAlerts();
  }

  UserModel? _user;

  /// Called by ProxyProvider when auth state changes.
  void updateUser(UserModel? user) {
    if (_user?.userId == user?.userId) return;
    _user = user;
    if (user != null) loadAlerts();
  }

  // ── State ────────────────────────────────────────────────────────────────

  List<AlertModel>  _alerts    = [];
  AlertLoadState    _loadState = AlertLoadState.initial;
  AlertFilter       _filter    = AlertFilter.all;
  String            _query     = '';
  String?           _errorMessage;

  AlertFilter     get filter       => _filter;
  AlertLoadState  get loadState    => _loadState;
  bool            get isLoading    => _loadState == AlertLoadState.loading;
  String?         get errorMessage => _errorMessage;

  // ── Load ─────────────────────────────────────────────────────────────────

  /// Fetches alerts from GET /api/alerts/user/{userId}.
  /// Falls back to empty list if user is not authenticated.
  Future<void> loadAlerts() async {
    final userId = _user?.userId;
    if (userId == null) return; // not authenticated yet

    _loadState    = AlertLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final dtos = await AlertService.instance.getAlertsForUser(userId);
      _alerts    = dtos.map((d) => d.toModel()).toList();
      _loadState = AlertLoadState.loaded;
    } on ApiException catch (e) {
      _loadState    = AlertLoadState.error;
      _errorMessage = e.displayMessage;
    }
    notifyListeners();
  }

  // ── Resolve ──────────────────────────────────────────────────────────────

  /// PATCH /api/alerts/resolve/{alertId}
  ///
  /// Updates the alert status to "resolved" in the local list on success.
  Future<bool> resolveAlert(AlertModel alert) async {
    final apiId = alert.apiId;
    if (apiId == null) {
      // Local mock alert — just toggle locally
      _toggleResolvedLocally(alert.id);
      return true;
    }
    try {
      await AlertService.instance.resolveAlert(apiId);
      _toggleResolvedLocally(alert.id);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.displayMessage;
      notifyListeners();
      return false;
    }
  }

  void _toggleResolvedLocally(String id) {
    _alerts = _alerts.map((a) {
      if (a.id == id) return a.copyWith(status: 'resolved');
      return a;
    }).toList();
    notifyListeners();
  }

  // ── Filter ───────────────────────────────────────────────────────────────

  void setFilter(AlertFilter f) {
    _filter = f;
    notifyListeners();
  }

  // ── Search ───────────────────────────────────────────────────────────────

  void setSearchQuery(String q) {
    _query = q.toLowerCase();
    notifyListeners();
  }

  void clearSearch() {
    _query = '';
    notifyListeners();
  }

  // ── Derived ──────────────────────────────────────────────────────────────

  List<AlertModel> get visibleAlerts {
    return _alerts.where((a) {
      final matchesFilter = _filter.matches(a.type);
      final matchesQuery  = _query.isEmpty ||
          a.title.toLowerCase().contains(_query) ||
          a.description.toLowerCase().contains(_query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  /// Alerts grouped by calendar day, newest first.
  List<({String label, List<AlertModel> alerts})> get groupedAlerts {
    final visible = visibleAlerts;
    if (visible.isEmpty) return [];

    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<String, List<AlertModel>> buckets = {};
    for (final alert in visible) {
      final d    = alert.timestamp;
      final day  = DateTime(d.year, d.month, d.day);
      final diff = today.difference(day).inDays;

      final label = diff == 0
          ? 'Today, ${_month(d.month)} ${d.day}'
          : diff == 1
              ? 'Yesterday, ${_month(d.month)} ${d.day}'
              : '${_month(d.month)} ${d.day}';

      buckets.putIfAbsent(label, () => []).add(alert);
    }

    return buckets.entries
        .map((e) => (label: e.key, alerts: e.value))
        .toList();
  }

  String _month(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}
