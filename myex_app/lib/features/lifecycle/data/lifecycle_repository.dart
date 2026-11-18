import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/reminder_plan.dart';

class LifecycleRepository {
  LifecycleRepository(this._db);
  final SupabaseClient _db;

  Future<ValueRecap> recap() async => ValueRecap.fromJson(
    await _db.rpc<Map<String, dynamic>>('get_value_recap'),
  );

  Future<bool> winbackEligible() => _db.rpc<bool>('winback_eligible');

  /// True only once per user, ever (server flag).
  Future<bool> markWinbackShown() => _db.rpc<bool>('mark_winback_shown');

  /// Lets the server push backup know a local reminder exists (M7).
  Future<void> setTrialReminderLocalAt(DateTime? at) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db
        .from('profiles')
        .update({'trial_reminder_local_at': at?.toUtc().toIso8601String()})
        .eq('id', uid);
  }
}

final lifecycleRepositoryProvider = Provider<LifecycleRepository>(
  (ref) => LifecycleRepository(ref.watch(supabaseClientProvider)),
);

final valueRecapProvider = FutureProvider.autoDispose<ValueRecap>(
  (ref) => ref.watch(lifecycleRepositoryProvider).recap(),
);
