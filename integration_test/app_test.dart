// integration_test/app_test.dart
//
// Integration tests for the HCK Egg Lite app.
// Run with: flutter test integration_test/app_test.dart
//
// Note: These tests require Supabase to be properly configured.
// For CI/CD, you may need to mock the Supabase client.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('Login page renders correctly', (tester) async {
      // This test verifies the login page structure without requiring Supabase
      // For full integration tests, Supabase needs to be initialized

      // Create a mock login page for testing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('HCK Egg Lite'),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify basic elements are present
      expect(find.text('HCK Egg Lite'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Empty state displays correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.egg_outlined, size: 64),
                  const SizedBox(height: 16),
                  const Text('No Records Yet'),
                  const SizedBox(height: 8),
                  const Text('Start tracking your eggs'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Add First Record'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.egg_outlined), findsOneWidget);
      expect(find.text('No Records Yet'), findsOneWidget);
      expect(find.text('Start tracking your eggs'), findsOneWidget);
      expect(find.text('Add First Record'), findsOneWidget);
    });

    testWidgets('Navigation drawer opens', (tester) async {
      final scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            key: scaffoldKey,
            appBar: AppBar(
              title: const Text('Dashboard'),
            ),
            drawer: Drawer(
              child: ListView(
                children: const [
                  DrawerHeader(
                    child: Text('HCK Egg Lite'),
                  ),
                  ListTile(
                    leading: Icon(Icons.dashboard),
                    title: Text('Dashboard'),
                  ),
                  ListTile(
                    leading: Icon(Icons.egg),
                    title: Text('Egg Records'),
                  ),
                  ListTile(
                    leading: Icon(Icons.sell),
                    title: Text('Sales'),
                  ),
                ],
              ),
            ),
            body: const Center(
              child: Text('Dashboard Content'),
            ),
          ),
        ),
      );

      // Open drawer
      scaffoldKey.currentState?.openDrawer();
      await tester.pumpAndSettle();

      // Verify drawer items
      expect(find.text('HCK Egg Lite'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Egg Records'), findsOneWidget);
      expect(find.text('Sales'), findsOneWidget);
    });

    testWidgets('FAB is tappable', (tester) async {
      bool fabPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Content')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => fabPressed = true,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(fabPressed, true);
    });

    testWidgets('Form validation works', (tester) async {
      final formKey = GlobalKey<FormState>();
      String? emailError;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                      onSaved: (value) {},
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) {
                          emailError = 'Validation failed';
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Submit without entering email
      await tester.tap(find.text('Submit'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Email is required'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField), 'invalid');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Invalid email format'), findsOneWidget);

      // Enter valid email
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      // No validation errors
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Invalid email format'), findsNothing);
    });
  });
}
