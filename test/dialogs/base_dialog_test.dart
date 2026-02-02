import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/dialogs/base_dialog.dart';

void main() {
  group('DialogHeader', () {
    testWidgets('renders title and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogHeader(
              title: 'Test Title',
              icon: Icons.add,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows close button when onClose provided', (tester) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogHeader(
              title: 'Test',
              icon: Icons.add,
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, true);
    });

    testWidgets('hides close button when onClose is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogHeader(
              title: 'Test',
              icon: Icons.add,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('DialogFooter', () {
    testWidgets('renders cancel and save buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogFooter(
              onCancel: () {},
              onSave: () {},
              cancelText: 'Cancel',
              saveText: 'Save',
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('calls onCancel when cancel pressed', (tester) async {
      var cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogFooter(
              onCancel: () => cancelled = true,
              onSave: () {},
              cancelText: 'Cancel',
              saveText: 'Save',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      expect(cancelled, true);
    });

    testWidgets('calls onSave when save pressed', (tester) async {
      var saved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogFooter(
              onCancel: () {},
              onSave: () => saved = true,
              cancelText: 'Cancel',
              saveText: 'Save',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      expect(saved, true);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogFooter(
              onCancel: () {},
              onSave: () {},
              cancelText: 'Cancel',
              saveText: 'Save',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables buttons when loading', (tester) async {
      var saved = false;
      var cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogFooter(
              onCancel: () => cancelled = true,
              onSave: () => saved = true,
              cancelText: 'Cancel',
              saveText: 'Save',
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.tap(find.text('Save'));

      expect(cancelled, false);
      expect(saved, false);
    });
  });

  group('DialogErrorBanner', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogErrorBanner(message: 'Error message'),
          ),
        ),
      );

      expect(find.text('Error message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('calls onDismiss when close pressed', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogErrorBanner(
              message: 'Error',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, true);
    });

    testWidgets('hides dismiss button when onDismiss is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogErrorBanner(message: 'Error'),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('DialogSectionHeader', () {
    testWidgets('renders title and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogSectionHeader(
              title: 'Section Title',
              icon: Icons.person,
            ),
          ),
        ),
      );

      expect(find.text('Section Title'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('DialogLoadingOverlay', () {
    testWidgets('shows child when not loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogLoadingOverlay(
              isLoading: false,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows loading overlay when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogLoadingOverlay(
              isLoading: true,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
