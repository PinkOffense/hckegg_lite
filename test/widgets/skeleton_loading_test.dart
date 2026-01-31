// test/widgets/skeleton_loading_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/widgets/skeleton_loading.dart';

void main() {
  group('SkeletonBox', () {
    testWidgets('renders with default height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxHeight, 16);
    });

    testWidgets('renders with custom dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(width: 100, height: 50),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.maxHeight, 50);
    });

    testWidgets('applies border radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(borderRadius: 10),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(10));
    });

    testWidgets('uses different colors for dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: SkeletonBox(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.grey.shade800);
    });

    testWidgets('uses light colors for light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: SkeletonBox(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.grey.shade300);
    });
  });

  group('SkeletonCard', () {
    testWidgets('renders with default height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('renders with custom height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(height: 200),
          ),
        ),
      );

      final container = tester.widgetList<Container>(find.byType(Container)).firstWhere(
            (c) => c.constraints?.maxHeight == 200,
            orElse: () => Container(),
          );
      expect(container.constraints?.maxHeight, 200);
    });

    testWidgets('contains multiple skeleton boxes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(),
          ),
        ),
      );

      // Should have multiple skeleton boxes for avatar, title, subtitle, content
      expect(find.byType(SkeletonBox), findsAtLeast(3));
    });
  });

  group('SkeletonListView', () {
    testWidgets('renders default number of items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListView(),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(SkeletonCard), findsNWidgets(5));
    });

    testWidgets('renders custom number of items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListView(itemCount: 3),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsNWidgets(3));
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListView(),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(find.byType(Semantics).first);
      expect(semantics.properties.label, 'Loading content');
    });
  });

  group('SkeletonStatsGrid', () {
    testWidgets('renders default 2x2 grid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SkeletonStatsGrid(),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(4));
    });

    testWidgets('renders custom grid size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SkeletonStatsGrid(columns: 3, rows: 2),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsNWidgets(6));
    });
  });

  group('SkeletonChart', () {
    testWidgets('renders with default height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonChart(),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('contains multiple bar placeholders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonChart(),
          ),
        ),
      );

      // Should have 7 bar placeholders (for a week of data)
      // Plus title skeleton
      expect(find.byType(SkeletonBox), findsAtLeast(7));
    });
  });

  group('SkeletonPage', () {
    testWidgets('renders full page skeleton with all sections', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonPage(),
          ),
        ),
      );

      expect(find.byType(SkeletonStatsGrid), findsOneWidget);
      expect(find.byType(SkeletonChart), findsOneWidget);
      expect(find.byType(SkeletonCard), findsNWidgets(3));
    });

    testWidgets('can hide stats section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonPage(showStats: false),
          ),
        ),
      );

      expect(find.byType(SkeletonStatsGrid), findsNothing);
    });

    testWidgets('can hide chart section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonPage(showChart: false),
          ),
        ),
      );

      expect(find.byType(SkeletonChart), findsNothing);
    });

    testWidgets('renders custom number of list items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonPage(
              showStats: false,
              showChart: false,
              listItemCount: 5,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsNWidgets(5));
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonPage(),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(find.byType(Semantics).first);
      expect(semantics.properties.label, 'Loading page content');
    });
  });

  group('ShimmerLoading', () {
    testWidgets('shows child when isLoading is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              isLoading: false,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('wraps child in shader mask when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              isLoading: true,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('animates the shimmer effect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              child: SkeletonBox(width: 100, height: 20),
            ),
          ),
        ),
      );

      // Pump a few frames to verify animation is running
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Animation should be running without errors
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });
  });
}
