import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/daily_walking_tracker.dart';
import 'package:park_demo/map/map_location_controller.dart';

MapLocationSample _sample(
  double latitude,
  double longitude,
  DateTime timestamp, {
  double accuracy = 4,
}) => MapLocationSample(
  latitude: latitude,
  longitude: longitude,
  accuracy: accuracy,
  timestamp: timestamp,
  inside: true,
);

void main() {
  test('suma caminata válida y rechaza precisión mala, desorden y saltos', () {
    final tracker = DailyWalkingTracker();
    final start = DateTime.utc(2026, 10, 8, 12);
    expect(tracker.update(_sample(-1.369, -78.648, start)), 0);
    final walked = tracker.update(
      _sample(-1.36895, -78.648, start.add(const Duration(seconds: 5))),
    );
    expect(walked, inInclusiveRange(5, 7));

    expect(
      tracker.update(
        _sample(
          -1.3689,
          -78.648,
          start.add(const Duration(seconds: 10)),
          accuracy: 50,
        ),
      ),
      walked,
    );
    expect(
      tracker.update(
        _sample(-1.368, -78.64, start.add(const Duration(seconds: 11))),
      ),
      walked,
    );
    expect(tracker.update(_sample(-1.3689, -78.648, start)), walked);
  });

  test('cambia de fecha sin contar dos veces el último segmento', () {
    final tracker = DailyWalkingTracker();
    tracker.update(
      _sample(-1.369, -78.648, DateTime.utc(2026, 10, 8, 23, 59, 58)),
    );
    expect(
      tracker.update(
        _sample(-1.36895, -78.648, DateTime.utc(2026, 10, 9, 0, 0, 3)),
      ),
      0,
    );
  });
}
