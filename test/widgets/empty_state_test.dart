// test/widgets/empty_state_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/widgets/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'Start adding items to see them here',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('Start adding items to see them here'), findsOneWidget);
    });

    testWidgets('shows action button when actionLabel and onAction provided', (tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'Start adding items',
              actionLabel: 'Add Item',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      await tester.pump();

      expect(actionPressed, true);
    });

    testWidgets('hides action button when onAction is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'Start adding items',
              actionLabel: 'Add Item',
            ),
          ),
        ),
      );

      // Action button text should not appear without onAction
      expect(find.text('Add Item'), findsNothing);
    });

    testWidgets('centers content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'Message',
            ),
          ),
        ),
      );

      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('has proper text alignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'Message',
            ),
          ),
        ),
      );

      final titleWidget = tester.widget<Text>(find.text('No Items'));
      expect(titleWidget.textAlign, TextAlign.center);

      final messageWidget = tester.widget<Text>(find.text('Message'));
      expect(messageWidget.textAlign, TextAlign.center);
    });
  });

  group('ChickenEmptyState', () {
    testWidgets('renders title and message', (tester) async {
      // Use runAsync because AnimatedChickens has real async operations (Future.delayed)
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChickenEmptyState(
                title: 'No Records',
                message: 'Start tracking your eggs',
              ),
            ),
          ),
        );
        // Allow widget tree to fully build
        await Future.delayed(const Duration(milliseconds: 100));
      });

      await tester.pump();

      expect(find.text('No Records'), findsOneWidget);
      expect(find.text('Start tracking your eggs'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      bool pressed = false;

      // Use runAsync because AnimatedChickens has real async operations (Future.delayed)
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChickenEmptyState(
                title: 'No Records',
                message: 'Start tracking',
                actionLabel: 'Add Record',
                onAction: () => pressed = true,
              ),
            ),
          ),
        );
        // Allow widget tree to fully build
        await Future.delayed(const Duration(milliseconds: 100));
      });

      await tester.pump();

      expect(find.text('Add Record'), findsOneWidget);

      await tester.tap(find.text('Add Record'));
      await tester.pump();

      expect(pressed, true);
    });
  });

  group('SearchEmptyState', () {
    testWidgets('renders with search query', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchEmptyState(
              query: 'test search',
            ),
          ),
        ),
      );

      expect(find.text('No results found'), findsOneWidget);
      expect(find.textContaining('test search'), findsOneWidget);
    });

    testWidgets('shows search_off icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchEmptyState(
              query: 'test',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('shows clear button when onClear provided', (tester) async {
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchEmptyState(
              query: 'test',
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      expect(find.text('Clear Search'), findsOneWidget);

      await tester.tap(find.text('Clear Search'));
      await tester.pump();

      expect(cleared, true);
    });

    testWidgets('hides clear button when onClear is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchEmptyState(
              query: 'test',
            ),
          ),
        ),
      );

      expect(find.text('Clear Search'), findsNothing);
    });
  });
}
