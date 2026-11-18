import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';

/// Configures RevenueCat with appUserID = Supabase uid, and keeps the two
/// identities in sync. RevenueCat app user ids are therefore Supabase auth
/// UUIDs, which the webhook relies on (M3).
abstract final class RevenueCatBootstrap {
  static StreamSubscription<AuthState>? _authSub;

  static String get _apiKey => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => Env.rcApiKeyIos,
    TargetPlatform.android => Env.rcApiKeyAndroid,
    _ => '',
  };

  static bool get isSupportedPlatform => !kIsWeb && _apiKey.isNotEmpty;

  static Future<void> init(SupabaseClient supabase) async {
    if (!isSupportedPlatform) {
      debugPrint('RevenueCat not configured for this platform.');
      return;
    }
    if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);

    if (!await Purchases.isConfigured) {
      final config = PurchasesConfiguration(_apiKey)
        ..appUserID = supabase.auth.currentUser?.id;
      await Purchases.configure(config);
    }

    await _authSub?.cancel();
    _authSub = supabase.auth.onAuthStateChange.listen((s) async {
      try {
        final id = s.session?.user.id;
        if (id != null && id != await Purchases.appUserID) {
          await Purchases.logIn(id);
        } else if (s.event == AuthChangeEvent.signedOut &&
            !await Purchases.isAnonymous) {
          await Purchases.logOut();
        }
      } catch (e) {
        debugPrint('RevenueCat identity sync failed: $e');
      }
    });
  }
}
