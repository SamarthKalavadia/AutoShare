import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshare/features/auth/register_page.dart';
import 'package:autoshare/features/profile/edit_profile_page.dart';
import 'package:autoshare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoshare/features/auth/presentation/widgets/app_text_field.dart';
import 'package:autoshare/data/models/user_model.dart';

class MockAuthController extends AuthController {
  @override
  AsyncValue<UserModel?> build() {
    return AsyncValue.data(
      UserModel.empty().copyWith(
        uid: 'test_uid',
        name: 'John Doe',
        phone: '9876543210',
        gender: 'Male',
      ),
    );
  }
}

void main() {
  group('Phone Number Formatters & Validation Tests - Register Page', () {
    testWidgets('Verify formatters and validation messages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => MockAuthController()),
          ],
          child: const MaterialApp(home: RegisterPage()),
        ),
      );

      // Find by AppTextField since we know RegisterPage uses it
      final appTextFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is AppTextField && widget.labelText == 'Phone number',
      );
      expect(appTextFieldFinder, findsOneWidget);

      final appTextField = tester.widget<AppTextField>(appTextFieldFinder);
      final validator = appTextField.validator;
      final formatters = appTextField.inputFormatters;

      expect(validator, isNotNull);
      expect(formatters, isNotNull);

      // Verify formatters exist and block non-digits and length > 10
      expect(formatters!.any((f) => f is FilteringTextInputFormatter), isTrue);

      // Test formatters behavior manually
      TextEditingValue val = const TextEditingValue(text: '98765abc10');
      for (final formatter in formatters) {
        val = formatter.formatEditUpdate(TextEditingValue.empty, val);
      }
      expect(val.text, '9876510'); // 'abc' is removed

      // Pasting letters/symbols/spaces
      val = const TextEditingValue(text: '+91 98765-43210');
      for (final formatter in formatters) {
        val = formatter.formatEditUpdate(TextEditingValue.empty, val);
      }
      expect(
        val.text,
        '9198765432',
      ); // + and space and - are removed, limited to 10 digits

      // Pasting more than 10 digits
      val = const TextEditingValue(text: '98765432101');
      for (final formatter in formatters) {
        val = formatter.formatEditUpdate(TextEditingValue.empty, val);
      }
      expect(val.text, '9876543210'); // 11th digit is dropped

      // Test validation logic
      // 1. Empty field
      expect(validator!(''), 'Please enter your phone number');
      expect(validator!(null), 'Please enter your phone number');

      // 2. 1-9 digits
      expect(validator!('1'), 'Please enter a valid 10-digit phone number');
      expect(validator!('9876'), 'Please enter a valid 10-digit phone number');
      expect(
        validator!('987654321'),
        'Please enter a valid 10-digit phone number',
      );

      // 3. Exactly 10 digits starting with 6
      expect(validator!('6876543210'), isNull);

      // 4. Exactly 10 digits starting with 7
      expect(validator!('7876543210'), isNull);

      // 5. Exactly 10 digits starting with 8
      expect(validator!('8876543210'), isNull);

      // 6. Exactly 10 digits starting with 9
      expect(validator!('9876543210'), isNull);

      // 7. First digit validation
      expect(
        validator!('1234567890'),
        'Please enter a valid 10-digit mobile number',
      );
      expect(
        validator!('5123456789'),
        'Please enter a valid 10-digit mobile number',
      );
    });
  });

  group('Phone Number Formatters & Validation Tests - Edit Profile Page', () {
    testWidgets('Verify formatters and validation messages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => MockAuthController()),
          ],
          child: const MaterialApp(home: EditProfilePage()),
        ),
      );

      // Let the Future.microtask run to populate state
      await tester.pump();

      // Find the TextField by its hint text
      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Enter your phone number',
      );
      expect(textFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(textFieldFinder);
      final formatters = textField.inputFormatters;
      expect(formatters, isNotNull);

      // Find the parent TextFormField to get the validator
      final textFormFieldFinder = find.ancestor(
        of: textFieldFinder,
        matching: find.byType(TextFormField),
      );
      expect(textFormFieldFinder, findsOneWidget);

      final textFormField = tester.widget<TextFormField>(textFormFieldFinder);
      final validator = textFormField.validator;
      expect(validator, isNotNull);

      // Verify formatters exist and block non-digits and length > 10
      expect(formatters!.any((f) => f is FilteringTextInputFormatter), isTrue);

      // Test formatters behavior manually
      TextEditingValue val = const TextEditingValue(text: '98765abc10');
      for (final formatter in formatters) {
        val = formatter.formatEditUpdate(TextEditingValue.empty, val);
      }
      expect(val.text, '9876510'); // 'abc' is removed

      // Pasting letters/symbols/spaces
      val = const TextEditingValue(text: '+91 98765-43210');
      for (final formatter in formatters) {
        val = formatter.formatEditUpdate(TextEditingValue.empty, val);
      }
      expect(
        val.text,
        '9198765432',
      ); // + and space and - are removed, limited to 10 digits

      // Pasting more than 10 digits
      val = const TextEditingValue(text: '98765432101');
      for (final formatter in formatters) {
        val = formatter.formatEditUpdate(TextEditingValue.empty, val);
      }
      expect(val.text, '9876543210'); // 11th digit is dropped

      // Test validation logic
      // 1. Empty field
      expect(validator!(''), 'This field is required');
      expect(validator!(null), 'This field is required');

      // 2. 1-9 digits
      expect(validator!('1'), 'Please enter a valid 10-digit phone number');
      expect(validator!('9876'), 'Please enter a valid 10-digit phone number');
      expect(
        validator!('987654321'),
        'Please enter a valid 10-digit phone number',
      );

      // 3. Exactly 10 digits starting with 6
      expect(validator!('6876543210'), isNull);

      // 4. Exactly 10 digits starting with 7
      expect(validator!('7876543210'), isNull);

      // 5. Exactly 10 digits starting with 8
      expect(validator!('8876543210'), isNull);

      // 6. Exactly 10 digits starting with 9
      expect(validator!('9876543210'), isNull);

      // 7. First digit validation
      expect(
        validator!('1234567890'),
        'Please enter a valid 10-digit mobile number',
      );
      expect(
        validator!('5123456789'),
        'Please enter a valid 10-digit mobile number',
      );
    });
  });
}
