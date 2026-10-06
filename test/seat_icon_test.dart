import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autoshare/core/widgets/app_seat_icon.dart';

void main() {
  group('AppSeatIcon Widget Tests', () {
    testWidgets('AppSeatIcon renders properly with custom size and color', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppSeatIcon(size: 24, color: Colors.blue),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(AppSeatIcon);
      expect(iconFinder, findsOneWidget);

      final sizedBoxFinder = find.descendant(
        of: iconFinder,
        matching: find.byType(SizedBox),
      );
      expect(sizedBoxFinder, findsOneWidget);

      final SizedBox box = tester.widget(sizedBoxFinder);
      expect(box.width, equals(24));
      expect(box.height, equals(24));
    });

    testWidgets('AppSeatIcon renders properly at size 16 and size 20', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppSeatIcon(size: 16),
                AppSeatIcon(size: 20),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AppSeatIcon), findsNWidgets(2));
    });
  });
}
