import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/monetization/application/revenuecat_bootstrap.dart';
import '../config/env.dart';

/// Startup sequence (M4 identity rules):
/// 1. Supabase.initialize
/// 2. Ensure a session BEFORE any paywall: anonymous sign-in if none.
///    Apple/Google/email are linked to the same uid later.
/// 3. RevenueCat configured with appUserID = Supabase uid.
abstract final class Bootstrap {
  static Future<SharedPreferences> run() async {
    final prefs = await SharedPreferences.getInstance();

    if (!Supabase.instance.isInitialized) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabasePublishableKey,
        debug: kDebugMode,
      );
    }
    final client = Supabase.instance.client;

    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
    }

    await RevenueCatBootstrap.init(client);
    await _syncProfileLocale(client);
    return prefs;
  }

  /// Keeps profiles.timezone (09:00 local reset) and locale (push copy) fresh.
  /// The server rate-limits timezone changes to once per 24h.
  static Future<void> _syncProfileLocale(SupabaseClient client) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final locale = PlatformDispatcher.instance.locale.languageCode;
      final patch = <String, Object>{'locale': locale == 'tr' ? 'tr' : 'en'};
      // IANA name (e.g. "Europe/Istanbul") for the 09:00 local reset of
      // messages, drafts and plan days. The server ignores changes more often
      // than once per 24h (guard_timezone_change).
      final tz = (await FlutterTimezone.getLocalTimezone()).identifier;
      if (tz.contains('/') || tz == 'UTC') patch['timezone'] = tz;
      await client.from('profiles').update(patch).eq('id', uid);
    } catch (e) {
      debugPrint('profile locale sync failed (non-fatal): $e');
    }
  }
}
