import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_document_controller.dart';
import 'package:park_demo/map/map_marker_icon_factory.dart';

Map<String, Object?> _document({
  String updatedAt = '2026-10-08T12:00:00.000Z',
  double latitude = -1.369,
  bool megaVisible = true,
}) {
  return <String, Object?>{
    'schemaVersion': 4,
    'updatedAt': updatedAt,
    'places': <Object?>[
      <String, Object?>{
        'id': 20,
        'cat': 'evento',
        'name': 'Mega Escenario',
        'latitude': latitude,
        'longitude': -78.648,
        'isVisible': megaVisible,
        'isFeatured': true,
        'needsReview': false,
        'recommendationId': 'megaescenario',
        'events': <Object?>[],
      },
      <String, Object?>{
        'id': 30,
        'cat': 'comida',
        'name': 'Patio de comidas La Luna',
        'latitude': -1.370,
        'longitude': -78.649,
        'isVisible': false,
        'isFeatured': false,
        'needsReview': false,
        'recommendationId': 'patio-luna',
        'events': <Object?>[],
      },
    ],
  };
}

void main() {
  dynamic markerPresentationOf(MapPlace place) {
    try {
      return (place as dynamic).markerPresentation;
    } on NoSuchMethodError {
      return null;
    }
  }

  test('asigna iconos 2D reconocibles a atracciones y escenarios', () {
    MapPlace place(String id, String category, String name) => MapPlace(
      id: id,
      category: category,
      name: name,
      latitude: -1.369,
      longitude: -78.648,
      isVisible: true,
      isFeatured: category == 'evento',
      needsReview: false,
      events: const <Map<String, Object?>>[],
    );

    final cases = <(MapPlace place, String iconKey, bool large)>[
      (place('23', 'show', 'Parque de Dinosaurios'), 'dinosaur', false),
      (place('29', 'servicio', 'Granja'), 'farm', false),
      (place('22', 'show', 'Resbaladera Gigante'), 'slide', false),
      (place('20', 'evento', 'Mega Escenario'), 'stage', true),
      (place('28', 'evento', 'Plaza de la Luna'), 'moon', true),
      (place('93', 'evento', 'Plaza del Sol'), 'sun', true),
    ];

    for (final item in cases) {
      final dynamic presentation = markerPresentationOf(item.$1);
      expect(presentation?.iconKey, item.$2, reason: item.$1.name);
      expect(presentation?.isLarge, item.$3, reason: item.$1.name);
    }
  });

  test('usa iconos 2D funcionales como respaldo para servicios', () {
    final places = <MapPlace>[
      const MapPlace(
        id: 'bathroom',
        category: 'bano',
        name: 'Baños',
        latitude: -1.369,
        longitude: -78.648,
        isVisible: true,
        isFeatured: false,
        needsReview: false,
        events: <Map<String, Object?>>[],
      ),
      const MapPlace(
        id: 'food',
        category: 'comida',
        name: 'Patio de comidas',
        latitude: -1.369,
        longitude: -78.648,
        isVisible: true,
        isFeatured: false,
        needsReview: false,
        events: <Map<String, Object?>>[],
      ),
    ];

    expect(markerPresentationOf(places.first)?.iconKey, 'restroom');
    expect(markerPresentationOf(places.last)?.iconKey, 'food');
  });

  test('orienta las etiquetas grandes hacia el centro del mapa', () {
    MapPlace event(String id, double longitude) => MapPlace(
      id: id,
      category: 'evento',
      name: id,
      latitude: -1.369,
      longitude: longitude,
      isVisible: true,
      isFeatured: true,
      needsReview: false,
      events: const <Map<String, Object?>>[],
    );

    final west = MapMarkerIconFactory.anchorFor(event('Luna', -78.6490));
    final east = MapMarkerIconFactory.anchorFor(event('Sol', -78.6464));

    expect(west.dx, lessThan(.5));
    expect(east.dx, greaterThan(.5));
  });

  test('acepta un documento v4 nuevo y notifica exactamente una vez', () {
    final controller = MapDocumentController();
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    expect(controller.acceptJson(jsonEncode(_document())), isTrue);
    expect(notifications, 1);
    expect(controller.visiblePlaces.map((place) => place.id), ['20']);
    expect(
      controller.visibleRecommendationPlaces.map(
        (place) => place.recommendationId,
      ),
      ['megaescenario'],
    );
    expect(jsonDecode(controller.toJson()!)['schemaVersion'], 4);
  });

  test('rechaza documentos repetidos o anteriores sin volver a notificar', () {
    final controller = MapDocumentController();
    var notifications = 0;
    controller.addListener(() => notifications += 1);
    final current = jsonEncode(_document());

    expect(controller.acceptJson(current), isTrue);
    expect(controller.acceptJson(current), isFalse);
    expect(
      controller.acceptJson(
        jsonEncode(
          _document(updatedAt: '2026-10-07T12:00:00.000Z', latitude: -1.36),
        ),
      ),
      isFalse,
    );
    expect(controller.snapshot!.places.first.latitude, -1.369);
    expect(notifications, 1);
  });

  test('un documento inválido conserva la última versión válida', () {
    final controller = MapDocumentController();
    expect(controller.acceptJson(jsonEncode(_document())), isTrue);

    expect(controller.acceptJson('{mal json'), isFalse);
    expect(
      controller.acceptJson(
        jsonEncode(<String, Object?>{..._document(), 'schemaVersion': 2}),
      ),
      isFalse,
    );
    expect(
      controller.acceptJson(jsonEncode(_document(latitude: 90.1))),
      isFalse,
    );
    expect(controller.snapshot!.places.first.latitude, -1.369);
  });

  test('rechaza categorías retiradas y coordenadas geográficas inválidas', () {
    final controller = MapDocumentController();
    final invalid = _document();
    final places = invalid['places']! as List<Object?>;
    places[0] = <String, Object?>{
      ...(places[0]! as Map<String, Object?>),
      'cat': 'trans',
    };

    expect(controller.acceptJson(jsonEncode(invalid)), isFalse);
    expect(controller.snapshot, isNull);
  });

  test(
    'expone lugares de recomendación ocultos sin usar nombres accidentales',
    () {
      final controller = MapDocumentController();
      final document = _document();
      final places = document['places']! as List<Object?>;
      places.add(<String, Object?>{
        'id': 'custom-no-runi-id',
        'cat': 'servicio',
        'name': 'Megaescenario parecido',
        'latitude': -1.3695,
        'longitude': -78.6475,
        'isVisible': true,
        'isFeatured': false,
        'needsReview': false,
        'events': <Object?>[],
      });

      expect(controller.acceptJson(jsonEncode(document)), isTrue);
      expect(
        controller.recommendationPlaces.map((place) => place.recommendationId),
        containsAll(<String>['megaescenario', 'patio-luna']),
      );
      expect(
        controller.visibleRecommendationPlaces.map(
          (place) => place.recommendationId,
        ),
        isNot(contains('patio-luna')),
      );
      expect(
        controller.recommendationPlaces.map((place) => place.id),
        isNot(contains('custom-no-runi-id')),
      );
    },
  );

  test('rechaza IDs duplicados', () {
    final controller = MapDocumentController();
    final document = _document();
    final places = document['places']! as List<Object?>;
    places.add(<String, Object?>{...(places.first! as Map<String, Object?>)});

    expect(controller.acceptJson(jsonEncode(document)), isFalse);
    expect(controller.snapshot, isNull);
  });
}
