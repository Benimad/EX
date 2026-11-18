import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../monetization/application/monetization_providers.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../data/plan_repository.dart';
import '../domain/plan_models.dart';

export '../domain/plan_models.dart' show planTotalDays;

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepository(ref.watch(supabaseClientProvider)),
);

/// Plan tab state. Premium comes from the server (get_limits), not from the
/// client entitlement cache; RPCs re-check everything anyway.
final planStateProvider = FutureProvider.autoDispose<PlanState>((ref) async {
  ref.watch(authUserIdProvider);
  final repo = ref.watch(planRepositoryProvider);
  final lang =
      ref.watch(appLocaleProvider)?.languageCode ??
      ref.watch(onboardingProvider).language ??
      'en';
  final results = await (
    repo.fetchTeasers(lang),
    repo.fetchCompletions(),
    repo.fetchUnlockedDays(),
    ref.watch(limitsProvider.future),
  ).wait;
  return PlanState(
    teasers: results.$1,
    completions: results.$2,
    unlocked: results.$3,
    premium: results.$4.premium,
    now: DateTime.now(),
  );
});

/// The user's current plan day (first day not done), from real progress.
/// Day 1 while loading or before any progress exists.
final currentPlanDayProvider = Provider<int>(
  (ref) => ref.watch(planStateProvider).value?.currentDay ?? 1,
);

final planDayProvider = FutureProvider.autoDispose.family<PlanDayDetail, int>(
  (ref, day) => ref.watch(planRepositoryProvider).getDay(day),
);
