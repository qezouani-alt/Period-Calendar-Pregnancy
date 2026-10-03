import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:period/features/pregnancy/presentation/pregnancy_organizers.dart';

void main() {
  for (final source in ['Gallery', 'Take picture']) {
    testWidgets('$source requests iOS permission before opening the picker', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
      final requests = <int>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'requestPermissions') {
          final permissions = List<int>.from(call.arguments as List);
          requests.addAll(permissions);
          return {for (final permission in permissions) permission: 0};
        }
        throw StateError('Unexpected permission call: ${call.method}');
      });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPregnancyRecordsSheet(
                  context,
                  records: const [],
                  onSave: (_) async {},
                  onRemove: (_) async {},
                ),
                child: const Text('Documents'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();
      expect(requests, isEmpty);
      await tester.tap(find.text(source));
      await tester.pumpAndSettle();
      expect(requests, [
        source == 'Gallery' ? Permission.photos.value : Permission.camera.value,
      ]);
      expect(find.text('Access is off'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
