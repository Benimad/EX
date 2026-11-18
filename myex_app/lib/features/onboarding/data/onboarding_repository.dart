import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/onboarding_answers.dart';

/// Persists quiz answers to public.onboarding_answers (RLS: own row only).
class OnboardingRepository {
  OnboardingRepository(this._db);
  final SupabaseClient _db;

  Future<void> save(OnboardingAnswers a, {required bool completed}) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from('onboarding_answers').upsert({
      'user_id': uid,
      ...a.toJson(),
      if (completed) 'completed_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  Future<OnboardingAnswers?> fetch() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _db
        .from('onboarding_answers')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return row == null ? null : OnboardingAnswers.fromJson(row);
  }
}
