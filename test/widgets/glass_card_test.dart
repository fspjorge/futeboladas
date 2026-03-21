import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futeboladas/widgets/glass_card.dart';

void main() {
  group('GlassCard Widget', () {
    testWidgets('renders child content correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(child: const Text('Conteúdo do GlassCard')),
          ),
        ),
      );

      expect(find.text('Conteúdo do GlassCard'), findsOneWidget);
      // Validate that it has BackdropFilter (glass effect)
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });
}
