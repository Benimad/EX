import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/demo/demo_mode.dart';
import 'package:myex_app/demo/demo_purchases.dart';
import 'package:myex_app/demo/demo_repositories.dart';
import 'package:myex_app/demo/demo_store.dart';
import 'package:myex_app/features/coach/domain/chat_origin.dart';
import 'package:myex_app/features/draft_jail/domain/draft.dart';
import 'package:myex_app/features/monetization/domain/limits.dart';
import 'package:myex_app/features/monetization/domain/monetization_ids.dart';
import 'package:myex_app/features/monetization/domain/purchase_outcome.dart';
import 'package:myex_app/features/plan/domain/plan_models.dart';

void main() {
  group('DemoMode.resolve', () {
    test('missing config → demo (even in release, so a keyless APK works)', () {
      expect(
        DemoMode.resolve(flag: false, configComplete: false, release: true),
        isTrue,
      );
    });
    test('real config in release → NEVER demo, even with DEMO=true', () {
      expect(
        DemoMode.resolve(flag: true, configComplete: true, release: true),
        isFalse,
      );
    });
    test('real config in debug → demo only when asked', () {
      expect(
        DemoMode.resolve(flag: true, configComplete: true, release: false),
        isTrue,
      );
      expect(
        DemoMode.resolve(flag: false, configComplete: true, release: false),
        isFalse,
      );
    });
  });

  group('demo fakes follow the server rules', () {
    late DemoStore store;
    setUp(() => store = DemoStore());

    test('buying yearly starts a 7-day trial once, then bills', () async {
      var confirms = 0;
      final repo = DemoPurchasesRepository(
        store,
        confirm: (_) async {
          confirms++;
          return true;
        },
      );
      final offer = await repo.getPaywall();
      expect(offer.trialEligible, isTrue);
      expect(offer.annual.priceString, r'$49.99');
      final o = await repo.buy(offer.annual.handle!);
      expect(o, isA<PurchaseSuccess>().having((s) => s.isTrial, 'trial', true));
      expect(store.coins, 70, reason: '20 start + 50 premium bonus');
      expect((await repo.getPaywall()).trialEligible, isFalse);
      expect(confirms, 1);
    });

    test('cancelling the simulated sheet changes nothing', () async {
      final repo = DemoPurchasesRepository(store, confirm: (_) async => false);
      final offer = await repo.getPaywall();
      expect(await repo.buy(offer.monthly.handle!), isA<PurchaseCancelled>());
      expect(store.isPremium, isFalse);
    });

    test(
      'Mira: 3 free messages, then 402-equivalent; SOS never counts',
      () async {
        final coach = DemoCoachRepository(store, language: () => 'en');
        final normal = await coach.createConversation(ChatOrigin.normal);
        final sos = await coach.createConversation(ChatOrigin.sos);
        for (var i = 0; i < 3; i++) {
          await coach.send(conversationId: normal, text: 'hi');
        }
        expect(
          () => coach.send(conversationId: normal, text: 'again'),
          throwsA(isA<MessageLimitReached>()),
        );
        for (var i = 0; i < 5; i++) {
          await coach.send(conversationId: sos, text: 'help');
        }
        expect(store.messagesUsed, 3);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('Draft Jail: 1 free a day, SOS unlimited, next day resets', () async {
      final drafts = DemoDraftRepository(store);
      expect(await drafts.lock('a', ChatOrigin.normal), isA<DraftLocked>());
      expect(
        await drafts.lock('b', ChatOrigin.normal),
        isA<DraftLimitReached>(),
      );
      expect(await drafts.lock('c', ChatOrigin.sos), isA<DraftLocked>());
      expect(await drafts.lock('d', ChatOrigin.sos), isA<DraftLocked>());
      store.nextDay();
      expect(await drafts.lock('e', ChatOrigin.normal), isA<DraftLocked>());
    });

    test(
      'plan: day 2 opens the next day; day 4 needs coins or Premium',
      () async {
        final plan = DemoPlanRepository(store, language: () => 'en');
        final wallet = DemoWalletRepository(store);
        expect((await plan.complete(1, ['a', 'b', 'c'])).ok, isTrue);
        expect((await plan.complete(2, ['a', 'b', 'c'])).reason, 'waiting');
        store.nextDay();
        expect((await plan.complete(2, ['a', 'b', 'c'])).ok, isTrue);
        store
          ..nextDay()
          ..addCoins(0);
        await plan.complete(3, ['a', 'b', 'c']);
        store.nextDay();
        expect((await plan.getDay(4)).status, PlanDayStatus.locked);
        expect((await plan.getDay(4)).prompt, isNull);
        await wallet.spend(
          item: MonetizationIds.itemPlanDay,
          ref: '4',
          idempotencyKey: 'demo-key-1',
        );
        expect(store.coins, 5);
        expect((await plan.getDay(4)).status, PlanDayStatus.open);
      },
    );
  });
}
