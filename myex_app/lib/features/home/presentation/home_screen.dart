import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/router/app_router.dart';
import '../../../core/util/context_x.dart';
import '../../monetization/application/monetization_providers.dart';
import '../../monetization/domain/paywall_offer.dart';
import '../../monetization/presentation/paywall_copy.dart';
import '../../monetization/presentation/widgets/status_chips.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../../plan/application/plan_progress.dart';
import '../../plan/domain/plan_models.dart';
import '../application/streak.dart';

/// Home (spec H1): large title "Today", the streak hero (the app's only
/// gradient), then grouped lists. Premium is a quiet row, never a pop-up.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting(BuildContext context) {
    final l = context.l10n;
    final h = DateTime.now().hour;
    if (h < 5) return l.homeGreetingLate;
    if (h < 12) return l.homeGreetingMorning;
    if (h < 18) return l.homeGreetingAfternoon;
    return l.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final name = ref.watch(onboardingProvider).name;
    final premium = ref.watch(premiumProvider).value;
    final isPremium = premium?.isActive ?? false;
    final limits = ref.watch(limitsProvider).value;
    final since = ref.watch(noContactSinceProvider).value;
    final offer = isPremium ? null : ref.watch(paywallOfferProvider).value;
    final trialDays = offer == null
        ? null
        : PaywallCopy(offer: offer, l10n: l).trialDays;
    final greeting = _greeting(context);
    final plan = ref.watch(planStateProvider).value;

    return ScreenBackground(
      child: LargeTitleScrollView(
        title: l.homeTitle,
        subtitle: name == null ? greeting : l.homeGreetingName(greeting, name),
        trailing: const CoinChip(),
        onRefresh: () async {
          invalidateMonetization(ref);
          ref.invalidate(noContactSinceProvider);
        },
        children: [
          if (premium?.billingIssue ?? false)
            BillingIssueBanner(
              title: l.billingIssueTitle,
              message: l.meBillingIssue,
              actionLabel: l.billingIssueCta,
              onAction: () =>
                  Links.openManageSubscriptions(premium?.managementUrl),
            ),
          _StreakHero(
            since: since,
            onStart: () => ref.read(startStreakProvider)(),
            onTap: () => context.go(Routes.plan),
          ),
          InsetGroup(
            children: [
              _todayRow(context, ref, plan),
              ListRow(
                leading: const IconSquare(
                  icon: Icons.chat_bubble_outline_rounded,
                  tone: IconTone.neutral,
                ),
                title: l.homeMiraTitle,
                subtitle: isPremium
                    ? l.homeMiraUnlimited
                    : limits == null
                    ? null
                    : l.homeMiraFreeLeft(limits.freeMessagesLeft),
                onTap: () => context.go(Routes.coach),
              ),
            ],
          ),
          InsetGroup(
            children: [
              ListRow(
                leading: const IconSquare(
                  icon: Icons.edit_outlined,
                  tone: IconTone.neutral,
                ),
                title: l.homeDraftTitle,
                subtitle: l.homeDraftSub,
                onTap: () => context.push(Routes.drafts),
              ),
              ListRow(
                key: const Key('home-sos-row'),
                leading: const IconSquare(
                  icon: Icons.favorite_border_rounded,
                  tone: IconTone.danger,
                ),
                title: l.homeSosTitle,
                subtitle: l.homeSosSub,
                onTap: () => context.push(Routes.sosFrom('home')),
              ),
            ],
          ),
          if (premium != null && premium.isActive && premium.isTrial)
            InsetGroup(
              children: [
                ListRow(
                  leading: const IconSquare(icon: Icons.schedule_rounded),
                  title: l.homeTrialTitle(_daysLeft(premium.expiresAt)),
                  subtitle: l.homeTrialSub,
                  onTap: () => context.push(Routes.trial),
                ),
              ],
            )
          else if (!isPremium)
            InsetGroup(
              children: [
                ListRow(
                  leading: const IconSquare(
                    icon: Icons.lock_outline_rounded,
                    tone: IconTone.neutral,
                  ),
                  title: l.homeUpsellTitle,
                  value: trialDays != null
                      ? l.homeUpsellTryFree
                      : l.homeUpsellSeePlans,
                  onTap: () =>
                      context.push(Routes.paywallFor(PaywallTrigger.homeChip)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Today's plan step (real progress), or the plan overview while loading.
  Widget _todayRow(BuildContext context, WidgetRef ref, PlanState? plan) {
    final l = context.l10n;
    final t = plan?.teasers.where((t) => t.day == plan.currentDay).firstOrNull;
    if (plan == null || t == null || plan.finished) {
      return ListRow(
        leading: const IconSquare(icon: Icons.calendar_today_outlined),
        title: l.homePlanTitle,
        subtitle: plan?.finished ?? false ? l.planFinished : null,
        onTap: () => context.go(Routes.plan),
      );
    }
    final status = plan.statusOf(t.day);
    return ListRow(
      key: const Key('home-today-row'),
      leading: const IconSquare(icon: Icons.calendar_today_outlined),
      title: t.title,
      subtitle: switch (status) {
        PlanDayStatus.open => l.planRowToday(t.day, t.minutes),
        PlanDayStatus.locked => l.planRowLocked(t.day),
        _ => l.planRowOpensAt(
          t.day,
          context.timeOfDay(PlanSchedule.nextReset(plan.now)),
        ),
      },
      onTap: () => status == PlanDayStatus.open
          ? context.push(Routes.planDay(t.day))
          : context.go(Routes.plan),
    );
  }

  static int _daysLeft(DateTime? end) {
    if (end == null) return 0;
    final d = end.difference(DateTime.now()).inHours / 24;
    return d <= 0 ? 0 : d.ceil();
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({
    required this.since,
    required this.onStart,
    required this.onTap,
  });

  final DateTime? since;
  final VoidCallback onStart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = since;
    final labelStyle = MyExType.subheadline.copyWith(
      color: MyExColors.onHero,
      fontWeight: FontWeight.w600,
    );
    final label = Row(
      children: [
        const Icon(Icons.local_fire_department_outlined, size: MyExSizes.icon),
        const Gap(MyExSpacing.s1 + 2),
        Text(l.homeHeroLabel, style: labelStyle),
      ],
    );
    if (s == null) {
      return HeroCard(
        onTap: onStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const Gap(MyExSpacing.s3),
            Text(
              l.homeHeroStart,
              style: MyExType.title3.copyWith(color: MyExColors.onHero),
            ),
            const Gap(MyExSpacing.s1),
            Text(
              l.homeHeroStartCta,
              style: MyExType.headline.copyWith(color: MyExColors.onHero),
            ),
          ],
        ),
      );
    }
    final days = streakDays(s, DateTime.now());
    final target = nextStreakMilestone(days);
    return Semantics(
      button: true,
      label: '${l.homeHeroLabel}: $days ${l.homeHeroUnit(days)}',
      excludeSemantics: true,
      child: HeroCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const Gap(MyExSpacing.s1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$days',
                  style: MyExType.numeral(
                    MyExType.numeralHero,
                  ).copyWith(color: MyExColors.onHero),
                ),
                const Gap(MyExSpacing.s2),
                Text(
                  l.homeHeroUnit(days),
                  style: MyExType.title3.copyWith(color: MyExColors.onHero),
                ),
              ],
            ),
            const Gap(MyExSpacing.s3),
            ProgressBar(
              value: days / target,
              color: MyExColors.onHero,
              track: MyExColors.heroTrack,
            ),
            const Gap(MyExSpacing.s2),
            Text(
              l.homeHeroNext(target - days, target),
              style: MyExType.subheadline.copyWith(color: MyExColors.onHero),
            ),
          ],
        ),
      ),
    );
  }
}
