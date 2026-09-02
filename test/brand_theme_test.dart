import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/auth/access_flow.dart';
import 'package:park_demo/design/brand_theme.dart';
import 'package:park_demo/main.dart';

void main() {
  testWidgets('la app expone los colores oficiales en su tema', (tester) async {
    await tester.pumpWidget(const MushucRunaApp());

    final context = tester.element(find.byType(AccessGate));
    final theme = Theme.of(context);

    expect(theme.colorScheme.primary, const Color(0xFF7A0708));
    expect(theme.colorScheme.secondary, const Color(0xFFBEA458));
    expect(theme.colorScheme.tertiary, const Color(0xFF004F18));
    expect(theme.scaffoldBackgroundColor, AppColors.surface);
  });
}
