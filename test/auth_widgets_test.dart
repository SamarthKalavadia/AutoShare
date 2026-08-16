import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autoshare/features/auth/presentation/widgets/primary_button.dart';
import 'package:autoshare/features/auth/presentation/widgets/password_field.dart';
import 'package:autoshare/features/auth/presentation/widgets/validation_text.dart';

void main() {
  group('Auth UI Reusable Widgets Tests', () {
    testWidgets('PrimaryButton displays text and handles tap', (
      WidgetTester tester,
    ) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Submit',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      expect(pressed, isTrue);
    });

    testWidgets('PasswordField toggles obscureText when icon is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PasswordField(labelText: 'Password')),
        ),
      );

      final textFieldFinder = find.byType(EditableText);
      EditableText editableText = tester.widget<EditableText>(textFieldFinder);
      expect(editableText.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      editableText = tester.widget<EditableText>(textFieldFinder);
      expect(editableText.obscureText, isFalse);
    });

    testWidgets(
      'ValidationText updates strength indicators based on password input',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ValidationText(password: 'StrongP@ss1')),
          ),
        );

        expect(find.text('Strong'), findsOneWidget);
        expect(find.text('8+ chars'), findsOneWidget);
      },
    );
  });
}
