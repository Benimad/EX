import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';

/// No-contact start date (profiles.no_contact_since), null if not started.
final noContactSinceProvider = FutureProvider.autoDispose<DateTime?>((
  ref,
) async {
  final db = ref.watch(supabaseClientProvider);
  final uid = ref.watch(authUserIdProvider).value;
  if (uid == null) return null;
  final row = await db
      .from('profiles')
      .select('no_contact_since')
      .eq('id', uid)
      .maybeSingle();
  final raw = row?['no_contact_since'];
  return raw is String ? DateTime.tryParse(raw) : null;
});

/// Whole days since [since] (local calendar days).
int streakDays(DateTime since, DateTime now) => DateTime(
  now.year,
  now.month,
  now.day,
).difference(DateTime(since.year, since.month, since.day)).inDays;

/// Next milestone for the hero progress bar.
const streakMilestones = [7, 14, 30, 60, 90, 180, 365];

int nextStreakMilestone(int days) =>
    streakMilestones.firstWhere((m) => m > days, orElse: () => days + 30);

/// Starts the streak today.
Future<void> startStreak(Ref ref) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if (uid == null) return;
  final t = DateTime.now();
  final date =
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  await db.from('profiles').update({'no_contact_since': date}).eq('id', uid);
  ref.invalidate(noContactSinceProvider);
}

/// Action provider so widgets (WidgetRef) can start the streak.
final startStreakProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => startStreak(ref),
);
