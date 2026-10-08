import 'dart:math' as math;

import 'package:park_demo/account/account_session.dart';
import 'package:park_demo/map/map_geo.dart';

enum RuniVisitKind { attraction, farm, food, show, concert }

class RuniScheduledEvent {
  const RuniScheduledEvent({
    required this.venueId,
    required this.venueName,
    required this.title,
    required this.startsAt,
    required this.tags,
  });

  final String venueId;
  final String venueName;
  final String title;
  final DateTime startsAt;
  final Set<String> tags;
}

class RuniPlaceOverride {
  const RuniPlaceOverride({
    required this.recommendationId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isVisible,
  });

  final String recommendationId;
  final String name;
  final double latitude;
  final double longitude;
  final bool isVisible;
}

class RuniRecommendation {
  const RuniRecommendation({
    required this.placeId,
    required this.placeName,
    required this.title,
    required this.scheduledAt,
    required this.reason,
    required this.confidence,
    required this.kind,
    required this.isScheduledEvent,
  });

  final String placeId;
  final String placeName;
  final String title;
  final DateTime scheduledAt;
  final String reason;
  final double confidence;
  final RuniVisitKind kind;
  final bool isScheduledEvent;

  String get timeLabel =>
      '${scheduledAt.hour.toString().padLeft(2, '0')}:'
      '${scheduledAt.minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is RuniRecommendation &&
      other.placeId == placeId &&
      other.placeName == placeName &&
      other.title == title &&
      other.scheduledAt == scheduledAt &&
      other.reason == reason &&
      other.confidence == confidence &&
      other.kind == kind &&
      other.isScheduledEvent == isScheduledEvent;

  @override
  int get hashCode => Object.hash(
    placeId,
    placeName,
    title,
    scheduledAt,
    reason,
    confidence,
    kind,
    isScheduledEvent,
  );
}

class RuniPlan {
  const RuniPlan({
    required this.planDate,
    required this.isPreview,
    required this.summary,
    required this.signals,
    required this.steps,
  });

  final DateTime planDate;
  final bool isPreview;
  final String summary;
  final List<String> signals;
  final List<RuniRecommendation> steps;

  @override
  bool operator ==(Object other) =>
      other is RuniPlan &&
      other.planDate == planDate &&
      other.isPreview == isPreview &&
      other.summary == summary &&
      _sameList(other.signals, signals) &&
      _sameList(other.steps, steps);

  @override
  int get hashCode => Object.hash(
    planDate,
    isPreview,
    summary,
    Object.hashAll(signals),
    Object.hashAll(steps),
  );
}

bool _sameList<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

class RuniRecommendationEngine {
  const RuniRecommendationEngine();

  static const _catalog = <_RuniCandidate>[
    _RuniCandidate(
      id: 'parque-dinosaurios',
      name: 'Parque de Dinosaurios',
      kind: RuniVisitKind.attraction,
      tags: {'Atracciones', 'Diversión familiar', 'Todo'},
      preferredMinute: 600,
      baseCrowd: .36,
      latitude: -1.3688026442110364,
      longitude: -78.6483060840965,
      iconic: true,
    ),
    _RuniCandidate(
      id: 'granja-interactiva',
      name: 'Granja interactiva',
      kind: RuniVisitKind.farm,
      tags: {'Granja', 'Atracciones', 'Diversión familiar', 'Todo'},
      preferredMinute: 630,
      baseCrowd: .28,
      latitude: -1.3668817600929775,
      longitude: -78.64447686812765,
      iconic: false,
    ),
    _RuniCandidate(
      id: 'resbaladera-gigante',
      name: 'Resbaladera Gigante',
      kind: RuniVisitKind.attraction,
      tags: {'Atracciones', 'Diversión familiar', 'Todo'},
      preferredMinute: 690,
      baseCrowd: .44,
      latitude: -1.3687512701991082,
      longitude: -78.64882311608577,
      iconic: true,
    ),
    _RuniCandidate(
      id: 'plaza-sol',
      name: 'Plaza del Sol',
      kind: RuniVisitKind.show,
      tags: {'Shows', 'Espectáculos', 'Todo'},
      preferredMinute: 720,
      baseCrowd: .42,
      latitude: -1.3679063449262399,
      longitude: -78.6464702970399,
      iconic: true,
    ),
    _RuniCandidate(
      id: 'patio-luna',
      name: 'Patio de comidas La Luna',
      kind: RuniVisitKind.food,
      tags: {'Atención', 'Organización', 'Variedad', 'Todo'},
      preferredMinute: 780,
      baseCrowd: .48,
      latitude: -1.3695262426865618,
      longitude: -78.64916589239968,
      iconic: false,
    ),
    _RuniCandidate(
      id: 'patio-mega',
      name: 'Patio de comidas Megaescenario',
      kind: RuniVisitKind.food,
      tags: {'Atención', 'Organización', 'Variedad', 'Todo'},
      preferredMinute: 810,
      baseCrowd: .4,
      latitude: -1.3677466426272615,
      longitude: -78.64543685306535,
      iconic: false,
    ),
    _RuniCandidate(
      id: 'plaza-luna',
      name: 'Plaza de la Luna',
      kind: RuniVisitKind.show,
      tags: {'Shows', 'Espectáculos', 'Todo'},
      preferredMinute: 840,
      baseCrowd: .38,
      latitude: -1.3696178522878562,
      longitude: -78.64905080695641,
      iconic: true,
    ),
    _RuniCandidate(
      id: 'mushuc-park',
      name: 'Mushuc Park',
      kind: RuniVisitKind.attraction,
      tags: {'Atracciones', 'Diversión familiar', 'Variedad', 'Todo'},
      preferredMinute: 900,
      baseCrowd: .46,
      latitude: -1.3676698916239916,
      longitude: -78.64635598660159,
      iconic: true,
    ),
    _RuniCandidate(
      id: 'megaescenario',
      name: 'Megaescenario',
      kind: RuniVisitKind.concert,
      tags: {'Conciertos', 'Shows', 'Espectáculos', 'Todo'},
      preferredMinute: 1080,
      baseCrowd: .55,
      latitude: -1.3683715122171023,
      longitude: -78.64615330831766,
      iconic: true,
    ),
  ];

  static final Set<String> catalogPlaceNames = Set<String>.unmodifiable(
    _catalog.map((candidate) => candidate.name),
  );

  RuniPlan build({
    required VisitorProfile profile,
    required DateTime now,
    Iterable<RuniScheduledEvent> events = const <RuniScheduledEvent>[],
    Map<String, double> crowdByPlace = const <String, double>{},
    Iterable<RuniPlaceOverride> places = const <RuniPlaceOverride>[],
  }) {
    final overrides = <String, RuniPlaceOverride>{
      for (final place in places) place.recommendationId: place,
    };
    final hiddenPlaceIds = overrides.values
        .where((place) => !place.isVisible)
        .map((place) => place.recommendationId)
        .toSet();
    final managedCatalog = _catalog
        .where((candidate) => !hiddenPlaceIds.contains(candidate.id))
        .map((candidate) {
          final override = overrides[candidate.id];
          return override == null
              ? candidate
              : candidate.withPlaceOverride(override);
        })
        .toList(growable: false);
    final eventList =
        events
            .where(
              (event) =>
                  !hiddenPlaceIds.contains(event.venueId) &&
                  !_isUnsupportedTransit(event.title) &&
                  !_isUnsupportedTransit(event.venueName),
            )
            .toList(growable: false)
          ..sort((left, right) => left.startsAt.compareTo(right.startsAt));
    final today = _dateOnly(now);
    final eventsToday = eventList
        .where((event) => _dateOnly(event.startsAt) == today)
        .toList(growable: false);
    final nextEvent = eventList
        .where((event) => _dateOnly(event.startsAt).isAfter(today))
        .firstOrNull;
    final isPreview = eventsToday.isEmpty && nextEvent != null;
    final planDate = isPreview ? _dateOnly(nextEvent.startsAt) : today;
    final planEvents = eventList
        .where((event) => _dateOnly(event.startsAt) == planDate)
        .toList(growable: false);
    final startMinute = isPreview
        ? 600
        : (now.hour * 60 + now.minute).clamp(540, 1110);
    final candidates = <_RuniCandidate>[
      ...managedCatalog,
      ...planEvents.map((event) => _candidateFromEvent(event, managedCatalog)),
    ];
    final anchorEvent = _selectAnchorEvent(candidates, profile);
    final flexibleTarget = anchorEvent == null ? 4 : 3;
    final steps = <RuniRecommendation>[];
    final usedPlaces = <String>{};
    var slotMinute = startMinute;
    _RuniCandidate? previous;

    while (steps.length < flexibleTarget) {
      final scores = <_ScoredCandidate>[];
      for (final candidate in candidates) {
        if (usedPlaces.contains(candidate.id)) continue;
        if (anchorEvent != null && candidate.id == anchorEvent.id) continue;
        if (candidate.kind == RuniVisitKind.food &&
            steps.any((step) => step.kind == RuniVisitKind.food)) {
          continue;
        }
        if (_isUnsupportedTransit(candidate.name) ||
            _isUnsupportedTransit(candidate.eventTitle ?? '')) {
          continue;
        }
        if (candidate.isEvent && candidate.preferredMinute < slotMinute - 20) {
          continue;
        }
        final crowd = _estimatedCrowd(
          candidate,
          slotMinute,
          crowdByPlace[candidate.id],
        );
        final score = _score(
          candidate: candidate,
          profile: profile,
          slotMinute: slotMinute,
          crowd: crowd,
          previous: previous,
        );
        scores.add(_ScoredCandidate(candidate, score, crowd));
      }
      if (scores.isEmpty) break;
      scores.sort((left, right) {
        final byScore = right.score.compareTo(left.score);
        if (byScore != 0) return byScore;
        final byPlace = left.candidate.id.compareTo(right.candidate.id);
        if (byPlace != 0) return byPlace;
        return (left.candidate.eventTitle ?? left.candidate.name).compareTo(
          right.candidate.eventTitle ?? right.candidate.name,
        );
      });
      final selected = scores.first;
      final confidence = _softmaxConfidence(scores);
      final scheduledMinute = selected.candidate.isEvent
          ? selected.candidate.preferredMinute
          : slotMinute;
      final scheduledAt = DateTime(
        planDate.year,
        planDate.month,
        planDate.day,
        scheduledMinute ~/ 60,
        scheduledMinute % 60,
      );
      steps.add(
        RuniRecommendation(
          placeId: selected.candidate.id,
          placeName: selected.candidate.name,
          title: selected.candidate.eventTitle ?? selected.candidate.name,
          scheduledAt: scheduledAt,
          reason: _reason(
            selected.candidate,
            profile,
            selected.crowd,
            slotMinute,
          ),
          confidence: confidence,
          kind: selected.candidate.kind,
          isScheduledEvent: selected.candidate.isEvent,
        ),
      );
      usedPlaces.add(selected.candidate.id);
      previous = selected.candidate;
      slotMinute = math.max(slotMinute + 75, scheduledMinute + 55);
      if (slotMinute > 1260) break;
    }

    if (anchorEvent != null) {
      final anchorCrowd = _estimatedCrowd(
        anchorEvent,
        anchorEvent.preferredMinute,
        crowdByPlace[anchorEvent.id],
      );
      final anchorDate = DateTime(
        planDate.year,
        planDate.month,
        planDate.day,
        anchorEvent.preferredMinute ~/ 60,
        anchorEvent.preferredMinute % 60,
      );
      final anchorAffinity = _profileAffinity(anchorEvent, profile);
      steps.add(
        RuniRecommendation(
          placeId: anchorEvent.id,
          placeName: anchorEvent.name,
          title: anchorEvent.eventTitle!,
          scheduledAt: anchorDate,
          reason: _reason(
            anchorEvent,
            profile,
            anchorCrowd,
            anchorEvent.preferredMinute - 60,
          ),
          confidence: (.72 + .23 * anchorAffinity).clamp(0, .95).toDouble(),
          kind: anchorEvent.kind,
          isScheduledEvent: true,
        ),
      );
      steps.sort(
        (left, right) => left.scheduledAt.compareTo(right.scheduledAt),
      );
    }

    final profileSignal = profile.visitReasons.isEmpty
        ? 'Ruta general'
        : profile.visitReasons.join(' · ');
    return RuniPlan(
      planDate: planDate,
      isPreview: isPreview,
      summary: isPreview
          ? 'Preparé tu próxima fecha con los shows publicados y los mejores momentos para cada zona.'
          : profile.isEmpty
          ? 'Preparé una ruta equilibrada para esta hora con lugares disponibles y afluencia estimada.'
          : 'Combiné tus intereses con la hora, los shows publicados y la afluencia estimada.',
      signals: List<String>.unmodifiable(<String>[
        profileSignal,
        'Hora y recorrido',
        'Programación vigente',
        'Afluencia estimada',
      ]),
      steps: List<RuniRecommendation>.unmodifiable(steps),
    );
  }

  static _RuniCandidate _candidateFromEvent(
    RuniScheduledEvent event,
    List<_RuniCandidate> catalog,
  ) {
    final venue = catalog.firstWhere(
      (candidate) => candidate.id == event.venueId,
      orElse: () => _RuniCandidate(
        id: event.venueId,
        name: event.venueName,
        kind: event.tags.contains('Conciertos')
            ? RuniVisitKind.concert
            : RuniVisitKind.show,
        tags: event.tags,
        preferredMinute: event.startsAt.hour * 60 + event.startsAt.minute,
        baseCrowd: .5,
        latitude: -1.3690877425784418,
        longitude: -78.647792380582,
        iconic: true,
      ),
    );
    return _RuniCandidate(
      id: event.venueId,
      name: venue.name,
      kind: event.tags.contains('Conciertos')
          ? RuniVisitKind.concert
          : RuniVisitKind.show,
      tags: <String>{...venue.tags, ...event.tags},
      preferredMinute: event.startsAt.hour * 60 + event.startsAt.minute,
      baseCrowd: venue.baseCrowd,
      latitude: venue.latitude,
      longitude: venue.longitude,
      iconic: venue.iconic,
      eventTitle: event.title,
    );
  }

  static _RuniCandidate? _selectAnchorEvent(
    List<_RuniCandidate> candidates,
    VisitorProfile profile,
  ) {
    if (profile.isEmpty) return null;
    final events = candidates.where((candidate) => candidate.isEvent).toList();
    if (events.isEmpty) return null;
    events.sort((left, right) {
      final byAffinity = _profileAffinity(
        right,
        profile,
      ).compareTo(_profileAffinity(left, profile));
      if (byAffinity != 0) return byAffinity;
      final byTime = left.preferredMinute.compareTo(right.preferredMinute);
      if (byTime != 0) return byTime;
      return left.eventTitle!.compareTo(right.eventTitle!);
    });
    return _profileAffinity(events.first, profile) >= .85 ? events.first : null;
  }

  static double _score({
    required _RuniCandidate candidate,
    required VisitorProfile profile,
    required int slotMinute,
    required double crowd,
    required _RuniCandidate? previous,
  }) {
    final affinity = _profileAffinity(candidate, profile);
    final schedule = _timeFit(candidate, slotMinute);
    final opportunity = 1 - crowd;
    final continuity = previous == null
        ? .68
        : (1 - MapGeo.distanceMeters(candidate.point, previous.point) / 450)
              .clamp(0, 1)
              .toDouble();
    final novelty = _novelty(candidate, profile.visitFrequency);
    final variety = previous == null || previous.kind != candidate.kind
        ? 1.0
        : .25;
    var score =
        .30 * affinity +
        .25 * schedule +
        .15 * opportunity +
        .15 * continuity +
        .10 * novelty +
        .05 * variety;
    if (candidate.kind == RuniVisitKind.food &&
        slotMinute >= 720 &&
        slotMinute <= 870) {
      score += .16;
    }
    if (candidate.isEvent &&
        candidate.preferredMinute >= slotMinute &&
        candidate.preferredMinute <= slotMinute + 90) {
      score += .18;
    }
    return score;
  }

  static double _profileAffinity(
    _RuniCandidate candidate,
    VisitorProfile profile,
  ) {
    if (profile.isEmpty) return .58;
    final interests = <String>{
      ...profile.visitReasons,
      ...profile.recommendationReasons,
    };
    if (interests.contains('Todo')) return .95;
    final matches = candidate.tags.intersection(interests).length;
    if (matches > 1) return 1;
    if (matches == 1) return .9;
    if (candidate.kind == RuniVisitKind.food) return .48;
    return .2;
  }

  static double _timeFit(_RuniCandidate candidate, int slotMinute) {
    final difference = (candidate.preferredMinute - slotMinute).abs();
    if (candidate.isEvent) {
      if (candidate.preferredMinute < slotMinute) return 0;
      if (difference <= 30) return 1;
      if (difference <= 90) return .92;
      if (difference <= 150) return .7;
      return .28;
    }
    return (1 - difference / 300).clamp(.18, 1).toDouble();
  }

  static double _novelty(_RuniCandidate candidate, String? frequency) {
    return switch (frequency) {
      'Primera vez' => candidate.iconic ? .95 : .7,
      'Más de 3' => candidate.isEvent ? 1 : (candidate.iconic ? .42 : .8),
      '3 veces' => candidate.isEvent ? .92 : .68,
      _ => candidate.isEvent ? .82 : .72,
    };
  }

  static double _estimatedCrowd(
    _RuniCandidate candidate,
    int minute,
    double? override,
  ) {
    if (override != null) return override.clamp(0, 1).toDouble();
    var crowd = candidate.baseCrowd;
    if (minute >= 720 && minute <= 900) crowd += .12;
    if (candidate.kind == RuniVisitKind.food && minute >= 720) crowd += .08;
    if (candidate.isEvent && (candidate.preferredMinute - minute).abs() <= 60) {
      crowd += .14;
    }
    return crowd.clamp(.08, .95).toDouble();
  }

  static double _softmaxConfidence(List<_ScoredCandidate> scores) {
    final maxScore = scores.first.score;
    const temperature = .12;
    final weights = scores
        .map((item) => math.exp((item.score - maxScore) / temperature))
        .toList(growable: false);
    final total = weights.fold<double>(0, (sum, value) => sum + value);
    final choiceProbability = weights.first / total;
    return (.64 + choiceProbability * .31).clamp(.64, .95).toDouble();
  }

  static String _reason(
    _RuniCandidate candidate,
    VisitorProfile profile,
    double crowd,
    int slotMinute,
  ) {
    if (candidate.isEvent) {
      if (candidate.tags.contains('Conciertos') &&
          profile.visitReasons.contains('Conciertos')) {
        return 'Próximo show y coincide con tu interés en conciertos';
      }
      return 'Está en la programación y empieza cerca de esta hora';
    }
    if (candidate.kind == RuniVisitKind.farm &&
        profile.visitReasons.contains('Granja')) {
      return 'Coincide con tu interés en granja y tiene baja afluencia';
    }
    if (candidate.kind == RuniVisitKind.food) {
      return slotMinute >= 720 && slotMinute <= 870
          ? 'Pausa recomendada por la hora y la continuidad de la ruta'
          : 'Punto de comida conveniente dentro del recorrido';
    }
    if (candidate.kind == RuniVisitKind.attraction &&
        (profile.visitReasons.contains('Atracciones') ||
            profile.visitReasons.contains('Todo'))) {
      return 'Coincide con tus intereses y mantiene un recorrido continuo';
    }
    if (crowd <= .4) {
      return 'Menor afluencia estimada a esta hora';
    }
    return 'Aporta variedad y mantiene una ruta eficiente';
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool _isUnsupportedTransit(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('tren') ||
        normalized.contains('trasbordo') ||
        normalized.contains('transbordo');
  }
}

class _RuniCandidate {
  const _RuniCandidate({
    required this.id,
    required this.name,
    required this.kind,
    required this.tags,
    required this.preferredMinute,
    required this.baseCrowd,
    required this.latitude,
    required this.longitude,
    required this.iconic,
    this.eventTitle,
  });

  final String id;
  final String name;
  final RuniVisitKind kind;
  final Set<String> tags;
  final int preferredMinute;
  final double baseCrowd;
  final double latitude;
  final double longitude;
  final bool iconic;
  final String? eventTitle;

  bool get isEvent => eventTitle != null;
  GeoPoint get point => GeoPoint(latitude: latitude, longitude: longitude);

  _RuniCandidate withPlaceOverride(RuniPlaceOverride override) =>
      _RuniCandidate(
        id: id,
        name: override.name,
        kind: kind,
        tags: tags,
        preferredMinute: preferredMinute,
        baseCrowd: baseCrowd,
        latitude: override.latitude,
        longitude: override.longitude,
        iconic: iconic,
        eventTitle: eventTitle,
      );
}

class _ScoredCandidate {
  const _ScoredCandidate(this.candidate, this.score, this.crowd);

  final _RuniCandidate candidate;
  final double score;
  final double crowd;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
