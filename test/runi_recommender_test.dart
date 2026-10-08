import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/account/account_session.dart';
import 'package:park_demo/runi/runi_recommender.dart';

void main() {
  const engine = RuniRecommendationEngine();

  test('un perfil de conciertos recibe el próximo show del Megaescenario', () {
    const profile = VisitorProfile(
      visitReasons: {'Conciertos'},
      visitFrequency: 'Primera vez',
      recommendationReasons: {'Espectáculos'},
    );
    final events = <RuniScheduledEvent>[
      RuniScheduledEvent(
        venueId: 'megaescenario',
        venueName: 'Megaescenario',
        title: 'Guaynaa',
        startsAt: DateTime(2026, 11, 1, 18),
        tags: const {'Conciertos', 'Shows'},
      ),
    ];

    final plan = engine.build(
      profile: profile,
      now: DateTime(2026, 11, 1, 16, 30),
      events: events,
    );

    expect(
      plan.steps.any(
        (step) => step.placeId == 'megaescenario' && step.title == 'Guaynaa',
      ),
      isTrue,
    );
    expect(
      plan.steps.firstWhere((step) => step.placeId == 'megaescenario').reason,
      contains('conciertos'),
    );
  });

  test('un perfil de granja comienza por la Granja interactiva', () {
    const profile = VisitorProfile(
      visitReasons: {'Granja'},
      visitFrequency: '1 vez',
      recommendationReasons: {'Diversión familiar'},
    );

    final plan = engine.build(
      profile: profile,
      now: DateTime(2026, 11, 1, 9, 30),
    );

    expect(plan.steps.first.placeId, 'granja-interactiva');
    expect(plan.steps.first.reason, contains('granja'));
  });

  test(
    'el mismo perfil, hora y señales producen exactamente la misma ruta',
    () {
      const profile = VisitorProfile(
        visitReasons: {'Todo'},
        visitFrequency: 'Más de 3',
        recommendationReasons: {'Variedad'},
      );
      final events = <RuniScheduledEvent>[
        RuniScheduledEvent(
          venueId: 'plaza-sol',
          venueName: 'Plaza del Sol',
          title: 'Show Feria',
          startsAt: DateTime(2026, 10, 31, 13),
          tags: const {'Shows'},
        ),
      ];
      final now = DateTime(2026, 10, 31, 10, 15);

      final first = engine.build(profile: profile, now: now, events: events);
      final second = engine.build(profile: profile, now: now, events: events);

      expect(first, second);
      expect(first.steps, isNotEmpty);
      expect(
        first.steps.every(
          (step) => step.confidence >= 0 && step.confidence <= 1,
        ),
        isTrue,
      );
    },
  );

  test('fuera de la feria prepara la próxima fecha sin fingir que es hoy', () {
    const profile = VisitorProfile(
      visitReasons: {'Shows'},
      visitFrequency: 'Primera vez',
      recommendationReasons: {'Organización'},
    );
    final events = <RuniScheduledEvent>[
      RuniScheduledEvent(
        venueId: 'plaza-luna',
        venueName: 'Plaza de la Luna',
        title: 'Mega Rumba',
        startsAt: DateTime(2026, 10, 31, 12),
        tags: const {'Shows'},
      ),
    ];

    final plan = engine.build(
      profile: profile,
      now: DateTime(2026, 10, 8, 9),
      events: events,
    );

    expect(plan.isPreview, isTrue);
    expect(plan.planDate, DateTime(2026, 10, 31));
    expect(plan.summary.toLowerCase(), contains('próxima fecha'));
  });

  test('la próxima fecha reserva el show que mejor coincide con el perfil', () {
    const profile = VisitorProfile(
      visitReasons: {'Conciertos'},
      visitFrequency: 'Primera vez',
      recommendationReasons: {'Espectáculos'},
    );
    final events = <RuniScheduledEvent>[
      RuniScheduledEvent(
        venueId: 'plaza-sol',
        venueName: 'Plaza del Sol',
        title: 'Inauguración',
        startsAt: DateTime(2026, 10, 30, 12),
        tags: const {'Shows'},
      ),
      RuniScheduledEvent(
        venueId: 'megaescenario',
        venueName: 'Megaescenario',
        title: 'Grupo Bodega',
        startsAt: DateTime(2026, 10, 30, 18),
        tags: const {'Shows', 'Conciertos'},
      ),
    ];

    final plan = engine.build(
      profile: profile,
      now: DateTime(2026, 10, 8, 10),
      events: events,
    );

    final show = plan.steps.firstWhere(
      (step) => step.placeId == 'megaescenario',
    );
    expect(show.title, 'Grupo Bodega');
    expect(show.scheduledAt, DateTime(2026, 10, 30, 18));
    expect(show.reason, contains('conciertos'));
  });

  test('una ruta equilibrada incluye como máximo una parada de comida', () {
    final plan = engine.build(
      profile: const VisitorProfile(),
      now: DateTime(2026, 10, 8, 10),
      events: <RuniScheduledEvent>[
        RuniScheduledEvent(
          venueId: 'plaza-sol',
          venueName: 'Plaza del Sol',
          title: 'Inauguración',
          startsAt: DateTime(2026, 10, 30, 12),
          tags: const {'Shows'},
        ),
      ],
    );

    expect(
      plan.steps.where((step) => step.kind == RuniVisitKind.food),
      hasLength(lessThanOrEqualTo(1)),
    );
  });

  test('el catálogo inteligente no contiene ni recomienda Paseo en Tren', () {
    final plan = engine.build(
      profile: const VisitorProfile(),
      now: DateTime(2026, 11, 1, 10),
    );

    expect(
      RuniRecommendationEngine.catalogPlaceNames,
      isNot(contains('Paseo en Tren')),
    );
    expect(
      plan.steps.map((step) => step.title),
      everyElement(isNot(contains('Tren'))),
    );
  });

  test('los lugares administrados reemplazan nombre y coordenadas por id', () {
    const profile = VisitorProfile(
      visitReasons: {'Shows'},
      visitFrequency: 'Más de 3',
      recommendationReasons: {'Espectáculos'},
    );
    final baseline = engine.build(
      profile: profile,
      now: DateTime(2026, 11, 1, 13),
    );
    final moved = engine.build(
      profile: profile,
      now: DateTime(2026, 11, 1, 13),
      places: const <RuniPlaceOverride>[
        RuniPlaceOverride(
          recommendationId: 'plaza-luna',
          name: 'Plaza de la Luna actualizada',
          latitude: -1.375,
          longitude: -78.655,
          isVisible: true,
        ),
      ],
    );
    final repeated = engine.build(
      profile: profile,
      now: DateTime(2026, 11, 1, 13),
      places: const <RuniPlaceOverride>[
        RuniPlaceOverride(
          recommendationId: 'plaza-luna',
          name: 'Plaza de la Luna actualizada',
          latitude: -1.375,
          longitude: -78.655,
          isVisible: true,
        ),
      ],
    );

    expect(
      moved.steps
          .where((step) => step.placeId == 'plaza-luna')
          .map((step) => step.placeName),
      everyElement('Plaza de la Luna actualizada'),
    );
    expect(moved, isNot(baseline));
    expect(repeated, moved);
  });

  test('un escenario oculto tampoco aparece mediante sus eventos', () {
    final plan = engine.build(
      profile: const VisitorProfile(
        visitReasons: {'Conciertos'},
        recommendationReasons: {'Espectáculos'},
      ),
      now: DateTime(2026, 11, 1, 16),
      events: <RuniScheduledEvent>[
        RuniScheduledEvent(
          venueId: 'megaescenario',
          venueName: 'Megaescenario',
          title: 'Show administrado',
          startsAt: DateTime(2026, 11, 1, 18),
          tags: const {'Conciertos'},
        ),
      ],
      places: const <RuniPlaceOverride>[
        RuniPlaceOverride(
          recommendationId: 'megaescenario',
          name: 'Mega Escenario',
          latitude: -1.3683715122171023,
          longitude: -78.64615330831766,
          isVisible: false,
        ),
      ],
    );

    expect(
      plan.steps.where((step) => step.placeId == 'megaescenario'),
      isEmpty,
    );
    expect(
      plan.steps.where((step) => step.title == 'Show administrado'),
      isEmpty,
    );
  });

  test('nunca recomienda eventos de Tren ni Trasbordo', () {
    final plan = engine.build(
      profile: const VisitorProfile(visitReasons: {'Todo'}),
      now: DateTime(2026, 11, 1, 9),
      events: <RuniScheduledEvent>[
        RuniScheduledEvent(
          venueId: 'plaza-sol',
          venueName: 'Plaza del Sol',
          title: 'Trasbordo turístico',
          startsAt: DateTime(2026, 11, 1, 10),
          tags: const {'Shows'},
        ),
        RuniScheduledEvent(
          venueId: 'plaza-luna',
          venueName: 'Plaza de la Luna',
          title: 'Paseo en Tren',
          startsAt: DateTime(2026, 11, 1, 11),
          tags: const {'Shows'},
        ),
      ],
    );

    expect(
      plan.steps.map((step) => step.title.toLowerCase()),
      everyElement(
        allOf(isNot(contains('tren')), isNot(contains('trasbordo'))),
      ),
    );
  });
}
