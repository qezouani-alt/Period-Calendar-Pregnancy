import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period/core/widgets/keyboard_done_overlay.dart';

void main() {
  testWidgets('Done above the keyboard closes an active text field', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeyboardDoneOverlay(child: child!),
        home: Scaffold(body: TextField(focusNode: focusNode)),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });
}
