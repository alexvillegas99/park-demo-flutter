import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_document_controller.dart';
import 'package:park_demo/map/map_view_model.dart';
import 'package:park_demo/map/widgets/map_search_filters.dart';

void main() {
  testWidgets(
    'las diez categorías usan una sola fila gráfica y se alcanzan deslizando',
    (tester) async {
      final document = MapDocumentController();
      final viewModel = MapViewModel(document: document);
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 390,
                child: MapSearchFilters(viewModel: viewModel, onShowAll: () {}),
              ),
            ),
          ),
        ),
      );

      final strip = find.byKey(const Key('map-category-scroll'));
      expect(strip, findsOneWidget);
      expect(tester.widget<ListView>(strip).scrollDirection, Axis.horizontal);
      expect(
        find.descendant(of: strip, matching: find.byType(FilterChip)),
        findsNothing,
      );
      expect(
        find.descendant(of: strip, matching: find.byType(Icon)),
        findsNothing,
      );
      expect(find.byKey(const Key('map-category-all')), findsOneWidget);

      await tester.drag(strip, const Offset(-620, 0));
      await tester.pumpAndSettle();

      final zones = find.byKey(const Key('map-category-zones'));
      expect(zones, findsOneWidget);
      await tester.tap(zones);
      await tester.pumpAndSettle();

      expect(viewModel.state.category, MapCategory.zones);
      expect(
        find.byKey(const Key('map-category-selection-zones')),
        findsOneWidget,
      );
    },
  );
}
