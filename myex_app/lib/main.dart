import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/analytics/analytics.dart';
import 'core/bootstrap/bootstrap.dart';
import 'core/supabase/supabase_providers.dart';
import 'demo/demo_mode.dart';
import 'features/monetization/application/monetization_providers.dart';
import 'features/onboarding/application/onboarding_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _start();
}

Future<void> _start() async {
  // DEMO: no keys needed (auto when config is missing; never in a release
  // build that has a real config). See lib/demo/demo_mode.dart.
  if (DemoMode.isActive) {
    final prefs = await SharedPreferences.getInstance();
    runApp(
      ProviderScope(
        overrides: [
          ...demoOverrides(prefs),
          analyticsContextProvider.overrideWith(
            (ref) => AnalyticsContext(
              locale:
                  ref.watch(appLocaleProvider)?.languageCode ??
                  WidgetsBinding
                      .instance
                      .platformDispatcher
                      .locale
                      .languageCode,
              isPremium: ref.watch(isPremiumProvider),
            ),
          ),
        ],
        child: const MyExApp(),
      ),
    );
    return;
  }
  try {
    final prefs = await Bootstrap.run();
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsContextProvider.overrideWith(
            (ref) => AnalyticsContext(
              locale:
                  ref.watch(appLocaleProvider)?.languageCode ??
                  WidgetsBinding
                      .instance
                      .platformDispatcher
                      .locale
                      .languageCode,
              isPremium: ref.watch(isPremiumProvider),
            ),
          ),
        ],
        child: const MyExApp(),
      ),
    );
  } catch (e, st) {
    debugPrint('startup failed: $e\n$st');
    runApp(const StartupErrorApp(onRetry: _start));
  }
}
