import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/core/design/design.dart';
import 'package:myex_app/core/supabase/supabase_providers.dart';
import 'package:myex_app/demo/demo_repositories.dart';
import 'package:myex_app/demo/demo_store.dart';
import 'package:myex_app/features/draft_jail/data/draft_repository.dart';
import 'package:myex_app/features/onboarding/application/onboarding_controller.dart';
import 'package:myex_app/features/onboarding/presentation/onboarding_quiz_screen.dart';
import 'package:myex_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AttachmentQuiz.score (3 statements, agree = 1)', () {
    test('none → secure', () {
      expect(AttachmentQuiz.score([0, 0, 0]), AttachmentStyle.secure);
    });
    test('worry or replay → anxious', () {
      expect(AttachmentQuiz.score([1, 0, 0]), AttachmentStyle.anxious);
      expect(AttachmentQuiz.score([0, 0, 1]), AttachmentStyle.anxious);
    });
    test('rather not need anyone → avoidant', () {
      expect(AttachmentQuiz.score([0, 1, 0]), AttachmentStyle.avoidant);
    });
    test('both → fearful', () {
      expect(AttachmentQuiz.score([1, 1, 0]), AttachmentStyle.fearful);
    });
    test('incomplete or out of range → null', () {
      expect(AttachmentQuiz.score([1, 1]), isNull);
      expect(AttachmentQuiz.score([0, 0, 2]), isNull);
      expect(AttachmentQuiz.score([0, -1, 0]), isNull);
    });
  });

  test('answers round-trip through the onboarding_answers row shape', () {
    const a = OnboardingAnswers(
      language: 'tr',
      whatHappened: WhatHappened.theyEnded,
      yourName: '  Selin ',
      exName: '',
      endedWhen: EndedWhen.weeks,
      length: RelationshipLength.y1to3,
      contact: ContactLevel.shared,
      hardestTimes: [HardestTime.lateNight, HardestTime.weekends],
      mood: 3,
      feelings: [Feeling.sad, Feeling.anxious],
      attachmentAnswers: [1, 0, 1],
      goals: [Goal.noContact, Goal.selfWorth],
    );
    final j = a.toJson();
    expect(j['what_happened'], 'they_ended');
    expect(j['ended_when'], 'weeks');
    expect(j['contact'], 'shared');
    expect(j['hardest_times'], ['lateNight', 'weekends']);
    expect(j['your_name'], 'Selin');
    expect(j['ex_name'], isNull, reason: 'empty optional name is not stored');
    expect(j['attachment_style'], 'anxious');
    final back = OnboardingAnswers.fromJson({...j, 'completed_at': 'x'});
    expect(back.focus, Goal.noContact);
    expect(back.contact!.lowContactTrack, isTrue);
    expect(back.suggestedCheckinHour, 22, reason: 'late night → 10 PM');
    expect(back.quizDone, isTrue);
  });

  test('check-in hour is pre-filled from the hardest time (R9)', () {
    expect(
      const OnboardingAnswers(
        hardestTimes: [HardestTime.mornings],
      ).suggestedCheckinHour,
      8,
    );
    expect(
      const OnboardingAnswers(
        hardestTimes: [HardestTime.mornings],
        checkinHour: 21,
      ).suggestedCheckinHour,
      21,
    );
  });

  testWidgets(
    'quiz: every step gates Continue, offers SOS, and saves answers',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 4000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = DemoStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            draftRepositoryProvider.overrideWithValue(
              DemoDraftRepository(store),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OnboardingQuizScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      PrimaryButton cta() =>
          tester.widget<PrimaryButton>(find.byKey(const Key('onb-continue')));
      Future<void> next() async {
        expect(find.byKey(const Key('onb-help')), findsOneWidget, reason: 'R8');
        await tester.tap(find.byKey(const Key('onb-continue')));
        await tester.pumpAndSettle();
      }

      Future<void> pick(String label) async {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      // Language
      expect(cta().onPressed, isNull);
      await pick('English');
      await next();
      // Name (optional)
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('onb-your-name')),
          matching: find.byType(TextField),
        ),
        'Selin',
      );
      await next();
      // What happened
      expect(cta().onPressed, isNull);
      await pick('They ended it');
      await next();
      // When
      expect(cta().onPressed, isNull);
      await pick('1–4 weeks ago');
      await next();
      // Details (optional)
      expect(cta().onPressed, isNotNull);
      await next();
      // Contact
      expect(cta().onPressed, isNull);
      await pick('We share kids or work');
      await next();
      // Hardest time
      expect(cta().onPressed, isNull);
      await pick('Late at night');
      await next();
      // Mira interstitial
      expect(find.text('Mira’s there at 2 AM.'), findsOneWidget);
      await next();
      // Feelings (slider default)
      await next();
      // Focus: at most three
      expect(cta().onPressed, isNull);
      await tester.tap(find.text('Stop texting them'));
      await tester.tap(find.text('Feel like myself again'));
      await tester.tap(find.text('Sleep better'));
      await tester.tap(find.text('Understand what went wrong')); // 4th ignored
      await tester.pumpAndSettle();
      await next();
      // Attachment: all three
      expect(cta().onPressed, isNull);
      for (var i = 0; i < 3; i++) {
        await tester.tap(
          find.descendant(
            of: find.byKey(Key('onb-attach-$i')),
            matching: find.text(i == 1 ? 'Not really' : 'Agree'),
          ),
        );
        await tester.pumpAndSettle();
      }
      await next();
      // R10: unsent message goes to Draft Jail, without the daily allowance.
      expect(cta().onPressed, isNull);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('onb-unsent')),
          matching: find.byType(TextField),
        ),
        'I still think about you.',
      );
      await tester.pumpAndSettle();
      await next();
      await tester.pump(const Duration(seconds: 3)); // toast
      expect(store.drafts, hasLength(1));
      expect(store.draftsUsed, 0, reason: 'onboarding draft is free');
      // R9: check-in pre-prompt pre-filled from "late at night" → 10 PM.
      expect(find.text('Want a check-in when it’s hardest?'), findsOneWidget);
      expect(find.textContaining('10:00'), findsWidgets);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(OnboardingQuizScreen)),
      );
      final saved = container.read(onboardingProvider);
      expect(saved.name, 'Selin');
      expect(saved.endedWhen, EndedWhen.weeks);
      expect(saved.contact, ContactLevel.shared);
      expect(saved.hardestTimes, [HardestTime.lateNight]);
      expect(saved.focus, Goal.noContact);
      expect(saved.goals.length, 3);
      expect(saved.attachmentStyle, AttachmentStyle.anxious);
    },
  );
}
