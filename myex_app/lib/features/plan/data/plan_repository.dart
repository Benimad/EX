import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/plan_models.dart';

/// Plan data. Teasers + own progress are plain selects (RLS); day content and
/// completion go through RPCs that enforce access and the 09:00 time gate.
class PlanRepository {
  PlanRepository(this._db);
  final SupabaseClient _db;

  Future<List<PlanDayTeaser>> fetchTeasers(String lang) async {
    final rows = await _db
        .from('plan_days')
        .select('day,stage,minutes,title_en,title_tr,promise_en,promise_tr')
        .order('day');
    return [for (final r in rows) PlanDayTeaser.fromRow(r, lang)];
  }

  Future<Map<int, DateTime>> fetchCompletions() async {
    final rows = await _db
        .from('user_plan_progress')
        .select('day,completed_at');
    return {
      for (final r in rows)
        (r['day'] as num).toInt(): DateTime.parse(
          r['completed_at'] as String,
        ).toLocal(),
    };
  }

  Future<Set<int>> fetchUnlockedDays() async {
    final rows = await _db
        .from('content_unlocks')
        .select('ref')
        .eq('kind', 'plan_day');
    return {for (final r in rows) ?int.tryParse(r['ref'].toString())};
  }

  Future<PlanDayDetail> getDay(int day) async {
    final res = await _db.rpc<Map<String, dynamic>>(
      'get_plan_day',
      params: {'p_day': day},
    );
    return PlanDayDetail.fromJson(res);
  }

  /// Returns null on success, or the server's reason ('waiting', 'locked').
  Future<({bool ok, String? reason, DateTime? nextOpensAt})> complete(
    int day,
    List<String> entries,
  ) async {
    final res = await _db.rpc<Map<String, dynamic>>(
      'complete_plan_day',
      params: {'p_day': day, 'p_entries': entries},
    );
    final next = res['next_opens_at'];
    return (
      ok: res['ok'] == true,
      reason: res['reason'] as String?,
      nextOpensAt: next is String ? DateTime.tryParse(next)?.toLocal() : null,
    );
  }
}
