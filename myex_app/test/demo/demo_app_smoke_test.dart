import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/app.dart';
import 'package:myex_app/demo/demo_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real app with the demo overrides (what the keyless APK runs):
/// onboarding starts, the Demo pill is there, SOS is reachable, and nothing
/// touches Supabase or RevenueCat.
void main() {
  testWidgets('demo app boots into onboarding with the Demo pill', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(overrides: demoOverrides(prefs), child: const MyExApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('demo-pill')), findsOneWidget);
    expect(find.byKey(const Key('onb-continue')), findsOneWidget);
    expect(find.byKey(const Key('onb-help')), findsOneWidget);
    // SOS from onboarding (R8): opens without any account or key.
    await tester.tap(find.byKey(const Key('onb-help')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('sos-urgent')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    // Let one-shot timers (toasts, debounces) finish.
    await tester.pump(const Duration(seconds: 5));
  });
}
