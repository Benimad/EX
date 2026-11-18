import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/cancel_survey.dart';

abstract interface class CancelSurveyLog {
  Future<void> record({
    required CancelReason reason,
    String? offerShown,
    bool offerAccepted = false,
    String? note,
  });
}

/// Inserts into cancel_survey_responses (RLS: insert own). Best effort: a
/// failure here must never block the cancel path.
class SupabaseCancelSurveyLog implements CancelSurveyLog {
  SupabaseCancelSurveyLog(this._db);
  final SupabaseClient _db;

  static const _maxNote = 500;

  @override
  Future<void> record({
    required CancelReason reason,
    String? offerShown,
    bool offerAccepted = false,
    String? note,
  }) async {
    try {
      final n = note?.trim();
      await _db.from('cancel_survey_responses').insert({
        'reason': reason.name,
        'offer_shown': offerShown,
        'offer_accepted': offerAccepted,
        if (n != null && n.isNotEmpty)
          'note': n.length > _maxNote ? n.substring(0, _maxNote) : n,
      });
    } catch (e) {
      debugPrint('cancel survey log failed (non-blocking): $e');
    }
  }
}

final cancelSurveyLogProvider = Provider<CancelSurveyLog>(
  (ref) => SupabaseCancelSurveyLog(ref.watch(supabaseClientProvider)),
);
