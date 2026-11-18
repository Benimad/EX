import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/features/coach/domain/chat_origin.dart';
import 'package:myex_app/features/draft_jail/data/draft_repository.dart';
import 'package:myex_app/features/draft_jail/domain/draft.dart';
import 'package:myex_app/features/draft_jail/presentation/draft_jail_screen.dart';
import 'package:myex_app/l10n/app_localizations.dart';

void main() {
  group('countdown', () {
    test('formats hh:mm:ss and never goes negative', () {
      expect(
        formatCountdown(const Duration(hours: 23, minutes: 4, seconds: 9)),
        '23:04:09',
      );
      expect(formatCountdown(Duration.zero), '00:00:00');
      expect(formatCountdown(const Duration(seconds: -5)), '00:00:00');
    });

    test('a draft is locked for 24h, then ready', () {
      final created = DateTime(2026, 11, 18, 22);
      final d = LockedDraft(
        id: 'x',
        body: 'please answer me',
        origin: ChatOrigin.normal,
        createdAt: created,
        lockedUntil: created.add(draftLockDuration),
      );
      expect(d.isLocked(DateTime(2026, 11, 19, 21, 59)), isTrue);
      expect(d.remaining(DateTime(2026, 11, 19, 21)), const Duration(hours: 1));
      expect(d.isLocked(DateTime(2026, 11, 19, 22)), isFalse);
      expect(d.wordCount, 3);
    });
  });

  group('lock outcome', () {
    test('parses rpc lock_draft results', () {
      expect(
        LockOutcome.fromJson({
          'ok': true,
          'id': 'a',
          'locked_until': '2026-11-19T22:00:00Z',
        }),
        isA<DraftLocked>(),
      );
      expect(
        LockOutcome.fromJson({
          'ok': false,
          'reason': 'limit',
          'resets_at': '2026-11-19T06:00:00Z',
        }),
        isA<DraftLimitReached>().having(
          (o) => o.resetsAt,
          'resetsAt',
          isNotNull,
        ),
      );
      expect(
        LockOutcome.fromJson({'ok': false, 'reason': 'weird'}),
        isA<DraftLockFailed>(),
      );
    });

    test('free limit shows the limit sheet, but NEVER from SOS', () {
      const limit = DraftLimitReached();
      expect(
        draftUiAction(limit, ChatOrigin.normal),
        DraftUiAction.showLimitSheet,
      );
      expect(draftUiAction(limit, ChatOrigin.sos), DraftUiAction.showError);
      expect(
        draftUiAction(
          DraftLocked(id: 'a', lockedUntil: DateTime(2026)),
          ChatOrigin.sos,
        ),
        DraftUiAction.locked,
      );
    });
  });

  group('DraftJailScreen', () {
    Future<_FakeRepo> pump(
      WidgetTester tester, {
      required ChatOrigin origin,
      required LockOutcome outcome,
      List<LockedDraft> drafts = const [],
    }) async {
      final repo = _FakeRepo(outcome, drafts);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [draftRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DraftJailScreen(origin: origin),
          ),
        ),
      );
      await tester.pump();
      return repo;
    }

    Future<void> lockText(WidgetTester tester) async {
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('draft-input')),
          matching: find.byType(TextField),
        ),
        'I miss you',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('draft-lock')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('normal origin over the free limit → limit sheet', (
      tester,
    ) async {
      final repo = await pump(
        tester,
        origin: ChatOrigin.normal,
        outcome: const DraftLimitReached(),
      );
      await lockText(tester);
      expect(repo.lastOrigin, ChatOrigin.normal);
      expect(find.byKey(const Key('draft-limit-sheet')), findsOneWidget);
      // The text is never lost.
      expect(find.text('I miss you'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('SOS origin: sent as sos, and no limit/upsell UI ever', (
      tester,
    ) async {
      final repo = await pump(
        tester,
        origin: ChatOrigin.sos,
        // Even if the server misbehaved and said "limit"…
        outcome: const DraftLimitReached(),
      );
      await lockText(tester);
      expect(repo.lastOrigin, ChatOrigin.sos);
      expect(find.byKey(const Key('draft-limit-sheet')), findsNothing);
      expect(find.textContaining('Premium'), findsNothing);
      expect(find.textContaining('coin'), findsNothing);
      // A neutral error toast instead; let it finish.
      expect(
        find.text('We couldn’t lock it. Your text is still here.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('locked drafts show a live countdown', (tester) async {
      final now = DateTime.now();
      await pump(
        tester,
        origin: ChatOrigin.normal,
        outcome: const DraftLockFailed('x'),
        drafts: [
          LockedDraft(
            id: 'd1',
            body: 'call me',
            origin: ChatOrigin.normal,
            createdAt: now,
            lockedUntil: now.add(const Duration(hours: 2)),
          ),
        ],
      );
      await tester.pump();
      expect(find.text('Locked draft'), findsOneWidget);
      expect(find.textContaining('Unlocks in 01:5'), findsOneWidget);
      // The draft body stays hidden while locked.
      expect(find.text('call me'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

class _FakeRepo implements DraftRepository {
  _FakeRepo(this.outcome, this.drafts);
  final LockOutcome outcome;
  final List<LockedDraft> drafts;
  ChatOrigin? lastOrigin;

  @override
  Future<List<LockedDraft>> list() async => drafts;

  @override
  Future<LockOutcome> lock(String body, ChatOrigin origin) async {
    lastOrigin = origin;
    return outcome;
  }

  @override
  Future<LockOutcome> lockOnboarding(String body) async => outcome;

  @override
  Future<bool> release(String id) async => false;

  @override
  Future<void> delete(String id) async {}
}
