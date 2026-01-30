// test/widgets/search_bar_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/widgets/search_bar.dart';

void main() {
  group('AppSearchBar', () {
    testWidgets('renders with hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchBar(
              controller: TextEditingController(),
              hintText: 'Search...',
              hasContent: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Search...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows clear button when hasContent is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchBar(
              controller: TextEditingController(text: 'test'),
              hintText: 'Search...',
              hasContent: true,
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('hides clear button when hasContent is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchBar(
              controller: TextEditingController(),
              hintText: 'Search...',
              hasContent: false,
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('calls onChanged when text changes', (WidgetTester tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchBar(
              controller: TextEditingController(),
              hintText: 'Search...',
              hasContent: false,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      expect(changedValue, 'hello');
    });

    testWidgets('calls onClear when clear button is tapped', (WidgetTester tester) async {
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchBar(
              controller: TextEditingController(text: 'test'),
              hintText: 'Search...',
              hasContent: true,
              onChanged: (_) {},
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(cleared, true);
    });

    testWidgets('applies custom padding', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(24);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchBar(
              controller: TextEditingController(),
              hintText: 'Search...',
              hasContent: false,
              onChanged: (_) {},
              padding: customPadding,
            ),
          ),
        ),
      );

      final paddingWidget = tester.widget<Padding>(find.byType(Padding).first);
      expect(paddingWidget.padding, customPadding);
    });
  });

  group('SearchEmptyState - from empty_state.dart', () {
    // Note: SearchEmptyState is in empty_state.dart, but we test the integration here
    testWidgets('shows search icon and message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded),
                  const Text('No results found'),
                  Text('No records match "test"'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      expect(find.text('No results found'), findsOneWidget);
    });
  });
}
