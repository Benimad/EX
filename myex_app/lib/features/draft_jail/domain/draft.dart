import 'package:flutter/foundation.dart';

import '../../coach/domain/chat_origin.dart';

/// Lock length (the server sets locked_until = now() + 24h).
const draftLockDuration = Duration(hours: 24);

@immutable
class LockedDraft {
  const LockedDraft({
    required this.id,
    required this.body,
    required this.origin,
    required this.createdAt,
    required this.lockedUntil,
    this.releasedAt,
  });

  factory LockedDraft.fromRow(Map<String, dynamic> r) => LockedDraft(
    id: r['id'] as String,
    body: r['body'] as String,
    origin: r['origin'] == 'sos' ? ChatOrigin.sos : ChatOrigin.normal,
    createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
    lockedUntil: DateTime.parse(r['locked_until'] as String).toLocal(),
    releasedAt: r['released_at'] == null
        ? null
        : DateTime.parse(r['released_at'] as String).toLocal(),
  );

  final String id;
  final String body;
  final ChatOrigin origin;
  final DateTime createdAt;
  final DateTime lockedUntil;
  final DateTime? releasedAt;

  bool isLocked(DateTime now) => now.isBefore(lockedUntil);
  Duration remaining(DateTime now) =>
      isLocked(now) ? lockedUntil.difference(now) : Duration.zero;

  int get wordCount =>
      body.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}

/// "23:59:59" (hours can exceed 24 only if the server clock is ahead).
String formatCountdown(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${h.toString().padLeft(2, '0')}:$m:$s';
}

/// Result of rpc lock_draft.
sealed class LockOutcome {
  const LockOutcome();

  factory LockOutcome.fromJson(Map<String, dynamic> j) {
    if (j['ok'] == true) {
      return DraftLocked(
        id: j['id'] as String,
        lockedUntil: DateTime.parse(j['locked_until'] as String).toLocal(),
      );
    }
    if (j['reason'] == 'limit') {
      final r = j['resets_at'];
      return DraftLimitReached(
        resetsAt: r is String ? DateTime.tryParse(r)?.toLocal() : null,
      );
    }
    return DraftLockFailed(j['reason']?.toString() ?? 'unknown');
  }
}

class DraftLocked extends LockOutcome {
  const DraftLocked({required this.id, required this.lockedUntil});
  final String id;
  final DateTime lockedUntil;
}

class DraftLimitReached extends LockOutcome {
  const DraftLimitReached({this.resetsAt});
  final DateTime? resetsAt;
}

class DraftLockFailed extends LockOutcome {
  const DraftLockFailed(this.reason);
  final String reason;
}

/// What the screen does with a lock outcome (pure, unit tested).
enum DraftUiAction {
  /// Clear the composer, show the new locked draft.
  locked,

  /// Free daily limit: show the limit sheet (normal origin ONLY).
  showLimitSheet,

  /// Calm error toast; the text stays in the composer.
  showError,
}

/// HARD RULE 1: a draft from SOS never shows a limit or upsell. If the server
/// ever answered "limit" for SOS (it doesn't), we show a neutral error.
DraftUiAction draftUiAction(LockOutcome outcome, ChatOrigin origin) =>
    switch (outcome) {
      DraftLocked() => DraftUiAction.locked,
      DraftLimitReached() when origin == ChatOrigin.normal =>
        DraftUiAction.showLimitSheet,
      DraftLimitReached() || DraftLockFailed() => DraftUiAction.showError,
    };
