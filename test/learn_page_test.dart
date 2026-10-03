import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period/features/learn/presentation/learn_page.dart';

void main() {
  testWidgets('Learn page shows the reading library', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LearnPage()));
    await tester.pumpAndSettle();

    expect(find.text('Your reading room'), findsOneWidget);
    expect(find.text('All guides'), findsOneWidget);

    await tester.tap(find.text('The menstrual cycle, gently explained'));
    await tester.pumpAndSettle();
    expect(find.text('World Health Organization'), findsOneWidget);
    expect(find.text('Read the source'), findsOneWidget);
  });
}
