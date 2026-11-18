import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/router/app_router.dart';
import '../../../core/util/context_x.dart';
import '../../monetization/application/monetization_providers.dart';
import '../../monetization/domain/paywall_offer.dart';
import '../../monetization/presentation/lock_day_sheet.dart';
import '../../monetization/presentation/widgets/status_chips.dart';
import '../application/plan_progress.dart';
import '../domain/plan_models.dart';

/// Plan tab (spec S2): large title, progress, days grouped by stage.
/// Locked days are shown (title + promise), not hidden.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(planStateProvider);
    final s = state.value;

    return ScreenBackground(
      child: LargeTitleScrollView(
        title: l.planTitle,
        subtitle: s == null ? null : l.planSubtitle(s.currentDay),
        trailing: const CoinChip(),
        onRefresh: () async {
          ref.invalidate(limitsProvider);
          ref.invalidate(planStateProvider);
          await ref
              .read(planStateProvider.future)
              .then<void>((_) {}, onError: (Object _) {});
        },
        children: switch (state) {
          AsyncData(:final value) => _body(context, ref, value),
          AsyncError() => [
            SolidCard(
              child: Column(
                children: [
                  Text(
                    l.planError,
                    style: MyExType.headline,
                    textAlign: TextAlign.center,
                  ),
                  const Gap(MyExSpacing.s3),
                  PrimaryButton(
                    label: l.commonRetry,
                    onPressed: () => ref.invalidate(planStateProvider),
                  ),
                ],
              ),
            ),
          ],
          _ => const [
            SkeletonBox(height: MyExSizes.progressHeight * 4),
            SkeletonBox(height: MyExSizes.skeletonList * 2),
          ],
        },
      ),
    );
  }

  List<Widget> _body(BuildContext context, WidgetRef ref, PlanState s) {
    final l = context.l10n;
    String stageLabel(PlanStage st) => switch (st) {
      PlanStage.week1 => l.planStageWeek1,
      PlanStage.week2 => l.planStageWeek2,
      PlanStage.week3 => l.planStageWeek3,
      PlanStage.rebuild => l.planStageRebuild,
    };
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProgressBar(value: s.doneCount / planTotalDays),
          const Gap(MyExSpacing.s2),
          Footnote(
            s.finished ? l.planFinished : l.planDoneCount(s.doneCount),
            textAlign: TextAlign.start,
          ),
        ],
      ),
      for (final stage in PlanStage.values)
        if (s.teasers.any((t) => t.stage == stage))
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(stageLabel(stage)),
              InsetGroup(
                children: [
                  for (final t in s.teasers.where((t) => t.stage == stage))
                    _dayRow(context, ref, s, t),
                ],
              ),
            ],
          ),
    ];
  }

  Widget _dayRow(
    BuildContext context,
    WidgetRef ref,
    PlanState s,
    PlanDayTeaser t,
  ) {
    final l = context.l10n;
    final status = s.statusOf(t.day);
    final isToday = status == PlanDayStatus.open;
    final prevDone = s.completions[t.day - 1];
    final String subtitle = switch (status) {
      PlanDayStatus.done => l.planRowDone(t.day),
      PlanDayStatus.open => l.planRowToday(t.day, t.minutes),
      PlanDayStatus.locked => l.planRowLocked(t.day),
      PlanDayStatus.waiting when prevDone != null => l.planRowOpensAt(
        t.day,
        context.timeOfDay(PlanSchedule.nextReset(s.now)),
      ),
      PlanDayStatus.waiting => l.planRowAfter(t.day, t.day - 1),
    };
    return ListRow(
      key: Key('plan-day-${t.day}'),
      leading: DayBadge(
        day: t.day,
        tone: switch (status) {
          PlanDayStatus.done => DayBadgeTone.done,
          PlanDayStatus.open => DayBadgeTone.today,
          PlanDayStatus.waiting => DayBadgeTone.open,
          PlanDayStatus.locked => DayBadgeTone.locked,
        },
      ),
      title: t.title,
      subtitle: subtitle,
      chevron: isToday,
      onTap: () => _onTap(context, ref, s, t, status),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    PlanState s,
    PlanDayTeaser t,
    PlanDayStatus status,
  ) async {
    final l = context.l10n;
    switch (status) {
      case PlanDayStatus.open || PlanDayStatus.done:
        unawaited(context.push(Routes.planDay(t.day)));
      case PlanDayStatus.waiting:
        showMyExToast(
          context,
          s.completions.containsKey(t.day - 1)
              ? l.planWaitingToast(
                  context.timeOfDay(PlanSchedule.nextReset(s.now)),
                )
              : l.planAfterToast(t.day - 1),
        );
      case PlanDayStatus.locked:
        final r = await showLockDaySheet(
          context: context,
          day: t.day,
          title: t.title,
          minutes: t.minutes,
        );
        if (!context.mounted || r == null) return;
        switch (r) {
          case LockDayResult.premium:
            unawaited(context.push(Routes.paywallFor(PaywallTrigger.planLock)));
          case LockDayResult.getCoins:
            unawaited(context.push(Routes.coins));
          case LockDayResult.unlocked:
            ref.invalidate(planStateProvider);
            showMyExToast(context, l.lockDayUnlocked(t.day), success: true);
        }
    }
  }
}
