import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client. Initialized in bootstrap before runApp.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Current Supabase user id (anonymous or linked). Rebuilds on auth change.
final authUserIdProvider = StreamProvider<String?>((ref) {
  final auth = ref.watch(supabaseClientProvider).auth;
  return auth.onAuthStateChange.map((s) => s.session?.user.id).distinct();
});

/// Local key-value store, loaded in bootstrap and injected via override.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('sharedPreferencesProvider must be overridden'),
);
