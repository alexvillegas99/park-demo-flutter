import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_document_controller.dart';
import 'package:park_demo/map/map_geo.dart';
import 'package:park_demo/map/map_view_model.dart';

MapDocumentController _document() {
  final controller = MapDocumentController();
  controller.acceptJson(
    jsonEncode(<String, Object?>{
      'schemaVersion': 4,
      'updatedAt': '2026-10-08T12:00:00Z',
      'places': <Object?>[
        for (final entry
            in <
              ({
                String id,
                String name,
                String cat,
                double lat,
                double lng,
                bool featured,
              })
            >[
              (
                id: '20',
                name: 'Mega Escenario',
                cat: 'evento',
                lat: -1.3690,
                lng: -78.6480,
                featured: true,
              ),
              (
                id: '28',
                name: 'Plaza de la Luna',
                cat: 'evento',
                lat: -1.3691,
                lng: -78.6481,
                featured: true,
              ),
              (
                id: '93',
                name: 'Plaza del Sol',
                cat: 'evento',
                lat: -1.3689,
                lng: -78.6479,
                featured: true,
              ),
              (
                id: 'b1',
                name: 'Baños Norte',
                cat: 'bano',
                lat: -1.3688,
                lng: -78.6478,
                featured: false,
              ),
              (
                id: 'z1',
                name: 'Zona Ñ',
                cat: 'zona',
                lat: -1.3700,
                lng: -78.6490,
                featured: false,
              ),
            ])
          <String, Object?>{
            'id': entry.id,
            'cat': entry.cat,
            'name': entry.name,
            'latitude': entry.lat,
            'longitude': entry.lng,
            'isVisible': true,
            'isFeatured': entry.featured,
            'needsReview': false,
            'events': <Object?>[],
          },
      ],
    }),
  );
  return controller;
}

void main() {
  test('la vista inicial muestra solamente los tres escenarios destacados', () {
    final viewModel = MapViewModel(document: _document());
    expect(viewModel.visiblePlaces.map((place) => place.name), <String>[
      'Mega Escenario',
      'Plaza de la Luna',
      'Plaza del Sol',
    ]);
  });

  test('zoom y filtro revelan puntos secundarios; búsqueda ignora tildes', () {
    final viewModel = MapViewModel(document: _document());
    viewModel.setZoom(18);
    expect(
      viewModel.visiblePlaces.map((place) => place.name),
      contains('Baños Norte'),
    );
    expect(
      viewModel.visiblePlaces.map((place) => place.name),
      isNot(contains('Zona Ñ')),
    );
    viewModel.setSearch('zona n');
    expect(viewModel.visiblePlaces.single.name, 'Zona Ñ');
  });

  test('selección permanece visible y cercanos se ordenan por metros', () {
    final viewModel = MapViewModel(document: _document());
    viewModel.selectPlace('b1');
    expect(viewModel.visiblePlaces.map((place) => place.id), contains('b1'));
    viewModel.setCurrentLocation(
      GeoPoint(latitude: -1.36881, longitude: -78.64781),
    );
    expect(viewModel.nearbyPlaces.first.place.id, 'b1');
    expect(viewModel.nearbyPlaces.first.meters, lessThan(5));
  });
}
