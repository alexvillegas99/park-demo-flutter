import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/main.dart';

void main() {
  testWidgets('App boots', (tester) async {
    await tester.pumpWidget(const MushucRunaApp());
    expect(find.text('Mushuc Runa'), findsOneWidget);
  });
}
