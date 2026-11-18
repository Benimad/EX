import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_answers.dart';

export '../domain/onboarding_answers.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(supabaseClientProvider)),
);

/// Quiz answers: cached locally (instant start-up, works offline) and saved
/// to Supabase (public.onboarding_answers) when the quiz finishes.
class OnboardingController extends Notifier<OnboardingAnswers> {
  static const _kAnswers = 'onb.answers';
  static const _kQuizDone = 'onb.quizDone';
  static const _kDone = 'onb.completed';

  @override
  OnboardingAnswers build() {
    final p = ref.watch(sharedPreferencesProvider);
    final raw = p.getString(_kAnswers);
    var a = const OnboardingAnswers();
    if (raw != null) {
      try {
        a = OnboardingAnswers.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt cache: start over.
      }
    }
    return a.copyWith(
      quizDone: p.getBool(_kQuizDone) ?? false,
      completed: p.getBool(_kDone) ?? false,
    );
  }

  /// Updates answers while the user moves through the quiz (local only).
  Future<void> update(OnboardingAnswers a) async {
    state = a;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_kAnswers, jsonEncode(a.toJson()));
  }

  /// Finishes the quiz: saves to the server (best effort; retried on next
  /// launch if it failed) and marks the quiz done locally.
  Future<void> finishQuiz() async {
    final p = ref.read(sharedPreferencesProvider);
    try {
      await ref.read(onboardingRepositoryProvider).save(state, completed: true);
    } catch (e) {
      debugPrint('onboarding save failed (will retry): $e');
      await p.setBool('onb.pendingSync', true);
    }
    await p.setBool(_kQuizDone, true);
    state = state.copyWith(quizDone: true);
  }

  /// Re-sends answers if the last save failed (call on start-up).
  Future<void> syncIfPending() async {
    final p = ref.read(sharedPreferencesProvider);
    if (!(p.getBool('onb.pendingSync') ?? false) || !state.quizDone) return;
    try {
      await ref.read(onboardingRepositoryProvider).save(state, completed: true);
      await p.remove('onb.pendingSync');
    } catch (_) {}
  }

  /// The onboarding paywall was passed (bought or closed).
  Future<void> markCompleted() async {
    await ref.read(sharedPreferencesProvider).setBool(_kDone, true);
    state = state.copyWith(completed: true);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingAnswers>(
      OnboardingController.new,
    );

/// Local "remind me before my trial ends" preference (also mirrored to
/// profiles.remind_trial on the server).
class RemindTrialController extends Notifier<bool> {
  static const _k = 'paywall.remindTrial';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_k) ?? true;

  Future<void> set(bool v) async {
    state = v;
    await ref.read(sharedPreferencesProvider).setBool(_k, v);
  }
}

final remindTrialProvider = NotifierProvider<RemindTrialController, bool>(
  RemindTrialController.new,
);

/// App language chosen in onboarding (null = follow the device).
class AppLocaleController extends Notifier<Locale?> {
  static const _k = 'app.locale';

  @override
  Locale? build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_k);
    return code == null ? null : Locale(code);
  }

  Future<void> set(String code) async {
    state = Locale(code);
    await ref.read(sharedPreferencesProvider).setString(_k, code);
    // Server copy (plan content, push copy) follows the app language.
    try {
      final db = ref.read(supabaseClientProvider);
      final uid = db.auth.currentUser?.id;
      if (uid != null) {
        await db.from('profiles').update({'locale': code}).eq('id', uid);
      }
    } catch (_) {
      // Offline or not configured (tests): bootstrap syncs it next launch.
    }
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleController, Locale?>(
  AppLocaleController.new,
);
