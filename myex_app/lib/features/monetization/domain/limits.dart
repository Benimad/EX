import 'package:flutter/foundation.dart';

import '../../coach/domain/chat_origin.dart';
import 'monetization_ids.dart';

/// Read-only usage snapshot from `rpc get_limits`. DISPLAY ONLY: the server
/// enforces limits in `consume_quota` (M0 rule 2).
@immutable
class LimitsState {
  const LimitsState({
    required this.premium,
    required this.freeMessagesLeft,
    required this.messageCredits,
    required this.draftsLeft,
    this.resetsAt,
  });

  factory LimitsState.fromJson(Map<String, dynamic> json) => LimitsState(
    premium: json['premium'] == true,
    freeMessagesLeft: (json['free_msgs_left'] as num?)?.toInt() ?? 0,
    messageCredits: (json['message_credits'] as num?)?.toInt() ?? 0,
    draftsLeft: (json['drafts_left'] as num?)?.toInt() ?? 0,
    resetsAt: json['resets_at'] == null
        ? null
        : DateTime.tryParse(json['resets_at'] as String)?.toLocal(),
  );

  final bool premium;
  final int freeMessagesLeft;
  final int messageCredits;
  final int draftsLeft;
  final DateTime? resetsAt;
}

/// What the Coach composer meter shows.
@immutable
class MeterState {
  const MeterState._({
    required this.visible,
    required this.sosMode,
    required this.total,
    required this.filled,
    required this.credits,
  });

  /// Pure derivation (unit tested).
  factory MeterState.derive({
    required ChatOrigin origin,
    required LimitsState? limits,
    int total = MonetizationDisplay.freeMessagesPerDay,
  }) {
    if (origin == ChatOrigin.sos) {
      return const MeterState._(
        visible: false,
        sosMode: true,
        total: 0,
        filled: 0,
        credits: 0,
      );
    }
    if (limits == null || limits.premium) {
      return const MeterState._(
        visible: false,
        sosMode: false,
        total: 0,
        filled: 0,
        credits: 0,
      );
    }
    return MeterState._(
      visible: true,
      sosMode: false,
      total: total,
      filled: limits.freeMessagesLeft.clamp(0, total),
      credits: limits.messageCredits,
    );
  }

  /// Show the free-messages meter (free user, normal chat).
  final bool visible;

  /// Show the "SOS mode · free, no limits" banner instead.
  final bool sosMode;
  final int total;
  final int filled;
  final int credits;
}

/// Thrown by the coach repository when mira-chat returns HTTP 402.
class MessageLimitReached implements Exception {
  const MessageLimitReached({this.resetsAt});
  final DateTime? resetsAt;
  @override
  String toString() => 'MessageLimitReached(resetsAt: $resetsAt)';
}

/// Can the user afford [cost] with [balance]? (Display hint; the RPC decides.)
bool canAfford({required int balance, required int cost}) =>
    cost > 0 && balance >= cost;
