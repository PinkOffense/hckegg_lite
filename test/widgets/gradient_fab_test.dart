// test/widgets/gradient_fab_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/widgets/gradient_fab.dart';

void main() {
  group('GradientFAB', () {
    testWidgets('renders with required parameters', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientFAB(
              icon: Icons.add,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientFAB(
              icon: Icons.add,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GradientFAB));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('shows tooltip when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientFAB(
              icon: Icons.add,
              onPressed: () {},
              tooltip: 'Add Item',
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('renders mini size correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientFAB(
              icon: Icons.add,
              onPressed: () {},
              mini: true,
            ),
          ),
        ),
      );

      // Mini FAB should have size 40x40
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GradientFAB),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.constraints?.maxWidth, 40.0);
      expect(container.constraints?.maxHeight, 40.0);
    });

    testWidgets('renders extended style with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientFAB(
              icon: Icons.add,
              onPressed: () {},
              extended: true,
              label: 'Add Record',
            ),
          ),
        ),
      );

      expect(find.text('Add Record'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('extended requires label to show extended style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientFAB(
              icon: Icons.add,
              onPressed: () {},
              extended: true,
              // No label provided
            ),
          ),
        ),
      );

      // Without label, it should render as normal FAB (circular)
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('has gradient decoration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientFAB(
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GradientFAB),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('icon color is white', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientFAB(
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.add));
      expect(icon.color, Colors.white);
    });
  });

  group('SpeedDialItem', () {
    test('creates item with required parameters', () {
      final item = SpeedDialItem(
        icon: Icons.edit,
        label: 'Edit',
        onPressed: () {},
      );

      expect(item.icon, Icons.edit);
      expect(item.label, 'Edit');
      expect(item.onPressed, isA<VoidCallback>());
    });
  });

  group('GradientSpeedDial', () {
    testWidgets('renders main FAB', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientSpeedDial(
              items: [
                SpeedDialItem(
                  icon: Icons.edit,
                  label: 'Edit',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GradientFAB), findsWidgets);
    });

    testWidgets('shows default add icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientSpeedDial(
              items: [
                SpeedDialItem(
                  icon: Icons.edit,
                  label: 'Edit',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('uses custom icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientSpeedDial(
              icon: Icons.menu,
              items: [
                SpeedDialItem(
                  icon: Icons.edit,
                  label: 'Edit',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('toggles state when main FAB is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientSpeedDial(
              activeIcon: Icons.close,
              items: [
                SpeedDialItem(
                  icon: Icons.edit,
                  label: 'Edit',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Initially shows add icon
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Tap to open
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should now show close icon
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows item labels when opened', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientSpeedDial(
              items: [
                SpeedDialItem(
                  icon: Icons.edit,
                  label: 'Edit Item',
                  onPressed: () {},
                ),
                SpeedDialItem(
                  icon: Icons.delete,
                  label: 'Delete Item',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Tap to open
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Labels should be visible
      expect(find.text('Edit Item'), findsOneWidget);
      expect(find.text('Delete Item'), findsOneWidget);
    });

    testWidgets('calls item onPressed and closes when item tapped', (tester) async {
      bool itemPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GradientSpeedDial(
              items: [
                SpeedDialItem(
                  icon: Icons.edit,
                  label: 'Edit',
                  onPressed: () => itemPressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Open speed dial
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Tap the item (mini FAB with edit icon)
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(itemPressed, true);
    });
  });
}
