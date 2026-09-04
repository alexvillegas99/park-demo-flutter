import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models.dart';

/// Central in-memory cache for data fetched from the REST API.
/// A failed fetch keeps the previous values (never crashes the UI).
class DataStore {
  DataStore._();
  static final DataStore instance = DataStore._();

  /// Bumped whenever any slot changes so plain `ValueListenableBuilder`
  /// consumers can rebuild. Prefer the typed notifiers below where possible.
  final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  bool _isReady = false;
  bool _isOffline = false;
  Object? _lastError;

  /// Today's featured event (from `GET /events/today`). Null when the API
  /// returns 404 — the UI shows a fallback in that case.
  final ValueNotifier<Event?> todayEvent = ValueNotifier<Event?>(null);

  /// Upcoming week schedule (from `GET /events/upcoming`), oldest first.
  final ValueNotifier<List<Event>> upcomingEvents =
      ValueNotifier<List<Event>>(const <Event>[]);

  List<Event> _events = const [];
  List<Poi> _pois = const [];
  List<Poi> _mapPois = const [];
  List<Restaurant> _restaurants = const [];
  List<AppPackage> _packages = const [];
  List<Attraction> _attractions = const [];
  List<OnboardingQuestion> _onboardingQuestions = const [];

  bool get isReady => _isReady;
  bool get isOffline => _isOffline;
  Object? get lastError => _lastError;

  /// Convenience getter mirroring the ValueNotifier so callers that don't
  /// need to subscribe can read the current value.
  Event? get todayEventData => todayEvent.value;
  List<Event> get events => _events;
  List<Poi> get pois => _pois;
  List<Poi> get mapPois => _mapPois;
  List<Restaurant> get restaurants => _restaurants;
  List<AppPackage> get packages => _packages;
  List<Attraction> get attractions => _attractions;
  List<OnboardingQuestion> get onboardingQuestions => _onboardingQuestions;

  /// Runs [f]; on error logs and returns null instead of throwing. The
  /// wrapper is `dynamic` so callers can pass any typed future.
  Future<Object?> _safe(Future<Object?> Function() f) async {
    try {
      return await f();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[DataStore] Fetch failed: $e');
      }
      return null;
    }
  }

  /// Fetch every listing in parallel; on failure keep the prior values.
  Future<void> refresh() async {
    _lastError = null;
    final api = ApiClient.instance;
    try {
      final results = await Future.wait<Object?>([
        _safe(() => api.getTodayEvent()),
        _safe(() => api.getPois()),
        _safe(() => api.getEvents()),
        _safe(() => api.getRestaurants()),
        _safe(() => api.getPackages()),
        _safe(() => api.getAttractions()),
        _safe(() => api.getMapPois()),
        _safe(() => api.getOnboardingQuestions()),
        _safe(() => api.getUpcomingEvents()),
      ]);

      // Today event: `null` is a valid value (nothing scheduled). `_safe`
      // also returns null on network failure — the UI treats both the same.
      todayEvent.value = results[0] is Event ? results[0] as Event : null;
      if (results[1] is List) _pois = List<Poi>.from(results[1] as List);
      if (results[2] is List) {
        _events = List<Event>.from(results[2] as List);
      }
      if (results[3] is List) {
        _restaurants = List<Restaurant>.from(results[3] as List);
      }
      if (results[4] is List) {
        _packages = List<AppPackage>.from(results[4] as List);
      }
      if (results[5] is List) {
        _attractions = List<Attraction>.from(results[5] as List);
      }
      if (results[6] is List) {
        _mapPois = List<Poi>.from(results[6] as List);
      }
      if (results[7] is List) {
        _onboardingQuestions =
            List<OnboardingQuestion>.from(results[7] as List);
      }
      if (results[8] is List) {
        upcomingEvents.value = List<Event>.from(results[8] as List);
      }
      _isOffline = todayEvent.value == null &&
          _pois.isEmpty &&
          _restaurants.isEmpty &&
          _packages.isEmpty &&
          upcomingEvents.value.isEmpty;
    } catch (e) {
      _lastError = e;
      _isOffline = true;
    } finally {
      _isReady = true;
      notifier.value = notifier.value + 1;
    }
  }
}
