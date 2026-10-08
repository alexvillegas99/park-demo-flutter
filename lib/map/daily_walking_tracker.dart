import 'map_geo.dart';
import 'map_location_controller.dart';

class DailyWalkingTracker {
  DailyWalkingTracker({
    this.maximumAccuracyMeters = 35,
    this.maximumSpeedMps = 3,
  });

  final double maximumAccuracyMeters;
  final double maximumSpeedMps;
  MapLocationSample? _last;
  DateTime? _day;
  double _meters = 0;

  double get meters => _meters;

  double update(MapLocationSample sample) {
    if (!sample.accuracy.isFinite || sample.accuracy > maximumAccuracyMeters) {
      return _meters;
    }
    final sampleDay = DateTime(
      sample.timestamp.year,
      sample.timestamp.month,
      sample.timestamp.day,
    );
    if (_day == null || sampleDay != _day) {
      _day = sampleDay;
      _last = sample;
      _meters = 0;
      return _meters;
    }
    final previous = _last;
    if (previous == null || !sample.timestamp.isAfter(previous.timestamp)) {
      return _meters;
    }
    final seconds =
        sample.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
    final segment = MapGeo.distanceMeters(previous.point, sample.point);
    if (seconds <= 0 || segment / seconds > maximumSpeedMps) return _meters;
    _last = sample;
    _meters += segment;
    return _meters;
  }
}
