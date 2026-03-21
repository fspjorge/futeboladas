import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futeboladas/widgets/empty_state.dart';

void main() {
  group('EmptyState Widget', () {
    testWidgets('renders icon and message correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.search_off,
              message: 'Nenhum resultado encontrado.',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('Nenhum resultado encontrado.'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('renders action button and triggers callback', (
      WidgetTester tester,
    ) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.error,
              message: 'Ocorreu um erro.',
              actionLabel: 'Tentar Novamente',
              onAction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(TextButton);
      expect(buttonFinder, findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pump();

      expect(actionTriggered, isTrue);
    });
  });
}
