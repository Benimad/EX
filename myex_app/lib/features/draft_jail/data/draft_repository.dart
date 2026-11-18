import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../coach/domain/chat_origin.dart';
import '../domain/draft.dart';

abstract interface class DraftRepository {
  Future<List<LockedDraft>> list();
  Future<LockOutcome> lock(String body, ChatOrigin origin);

  /// The one unsent message written during onboarding (R10). Saved to Draft
  /// Jail without using the free daily draft.
  Future<LockOutcome> lockOnboarding(String body);

  /// True when released (only allowed after 24h; the server checks).
  Future<bool> release(String id);
  Future<void> delete(String id);
}

/// Supabase implementation: reads via RLS, writes via lock/release RPCs.
class SupabaseDraftRepository implements DraftRepository {
  SupabaseDraftRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<List<LockedDraft>> list() async {
    final rows = await _db
        .from('locked_drafts')
        .select('id,body,origin,created_at,locked_until,released_at')
        .order('created_at', ascending: false)
        .limit(50);
    return [for (final r in rows) LockedDraft.fromRow(r)];
  }

  @override
  Future<LockOutcome> lock(String body, ChatOrigin origin) async {
    final res = await _db.rpc<Map<String, dynamic>>(
      'lock_draft',
      params: {'p_body': body, 'p_origin': origin.wire},
    );
    return LockOutcome.fromJson(res);
  }

  @override
  Future<LockOutcome> lockOnboarding(String body) async {
    final res = await _db.rpc<Map<String, dynamic>>(
      'lock_draft',
      params: {'p_body': body, 'p_origin': 'onboarding'},
    );
    return LockOutcome.fromJson(res);
  }

  @override
  Future<bool> release(String id) async {
    final res = await _db.rpc<Map<String, dynamic>>(
      'release_draft',
      params: {'p_id': id},
    );
    return res['ok'] == true;
  }

  @override
  Future<void> delete(String id) async {
    await _db.from('locked_drafts').delete().eq('id', id);
  }
}

final draftRepositoryProvider = Provider<DraftRepository>(
  (ref) => SupabaseDraftRepository(ref.watch(supabaseClientProvider)),
);

final draftsProvider = FutureProvider.autoDispose<List<LockedDraft>>(
  (ref) => ref.watch(draftRepositoryProvider).list(),
);
