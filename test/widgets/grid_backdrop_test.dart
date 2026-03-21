import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futeboladas/widgets/grid_backdrop.dart';

void main() {
  group('GridBackdrop Widget', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GridBackdrop())),
      );

      expect(find.byType(GridBackdrop), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is GridBackdropPainter,
        ),
        findsOneWidget,
      );
    });
  });
}
