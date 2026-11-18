import 'package:flutter/foundation.dart';

// Wire values match the CHECK constraints in
// supabase/migrations/20261118000000_onboarding.sql and …0400_onboarding_v2.sql.

enum WhatHappened {
  theyEnded('they_ended'),
  iEnded('i_ended'),
  mutual('mutual'),
  complicated('complicated'),

  /// Kept for older answers; not offered in the quiz anymore.
  onOff('on_off');

  const WhatHappened(this.wire);
  final String wire;

  static const offered = [theyEnded, iEnded, mutual, complicated];

  static WhatHappened? parse(String? s) =>
      values.where((v) => v.wire == s).firstOrNull;
}

enum EndedWhen {
  thisWeek('this_week'),
  weeks('weeks'),
  months('months'),
  longer('longer');

  const EndedWhen(this.wire);
  final String wire;
  static EndedWhen? parse(String? s) =>
      values.where((v) => v.wire == s).firstOrNull;
}

enum RelationshipLength {
  lt6m('lt6m'),
  m6to12('6to12m'),
  y1to3('1to3y'),
  gt3y('gt3y');

  const RelationshipLength(this.wire);
  final String wire;

  static RelationshipLength? parse(String? s) =>
      values.where((v) => v.wire == s).firstOrNull;
}

/// Contact level decides the plan track: no contact vs low contact
/// ("we share kids or work" can't go no-contact; safety and realism).
enum ContactLevel {
  none('none'),
  sometimes('sometimes'),
  mostDays('most_days'),
  shared('shared');

  const ContactLevel(this.wire);
  final String wire;
  static ContactLevel? parse(String? s) =>
      values.where((v) => v.wire == s).firstOrNull;

  bool get lowContactTrack => this == shared;
}

enum HardestTime {
  lateNight,
  mornings,
  weekends,
  theirPosts;

  static HardestTime? parse(String s) =>
      values.where((v) => v.name == s).firstOrNull;

  /// Pre-filled check-in hour for the notification pre-prompt (R9).
  int get suggestedHour => switch (this) {
    HardestTime.lateNight || HardestTime.theirPosts => 22,
    HardestTime.mornings => 8,
    HardestTime.weekends => 11,
  };
}

enum Feeling {
  sad,
  lonely,
  anxious,
  angry,
  numb,
  confused,
  relieved;

  static Feeling? parse(String s) =>
      values.where((v) => v.name == s).firstOrNull;
}

/// Order of selection matters: the first goal is the plan's focus.
enum Goal {
  stopChecking,
  noContact,
  calm,
  understand,
  selfWorth;

  static Goal? parse(String s) => values.where((v) => v.name == s).firstOrNull;
}

enum AttachmentStyle {
  secure,
  anxious,
  avoidant,
  fearful;

  static AttachmentStyle? parse(String? s) =>
      values.where((v) => v.name == s).firstOrNull;
}

/// Three statements, each "Agree" (1) or "Not really" (0):
///   0. "I worry they’ll forget me."        → anxiety
///   1. "I’d rather not need anyone."       → avoidance
///   2. "I replay what I could have said."  → anxiety (rumination)
/// A starting point, not a diagnosis. It only shapes tone.
abstract final class AttachmentQuiz {
  static const questionCount = 3;
  static const maxAnswer = 1;

  static AttachmentStyle? score(List<int> answers) {
    if (answers.length != questionCount) return null;
    if (answers.any((a) => a < 0 || a > maxAnswer)) return null;
    final anx = answers[0] + answers[2] >= 1;
    final avo = answers[1] == 1;
    if (anx && avo) return AttachmentStyle.fearful;
    if (anx) return AttachmentStyle.anxious;
    if (avo) return AttachmentStyle.avoidant;
    return AttachmentStyle.secure;
  }
}

@immutable
class OnboardingAnswers {
  const OnboardingAnswers({
    this.language,
    this.whatHappened,
    this.yourName,
    this.exName,
    this.endedWhen,
    this.length,
    this.contact,
    this.hardestTimes = const [],
    this.mood,
    this.feelings = const [],
    this.attachmentAnswers = const [],
    this.goals = const [],
    this.checkinHour,
    this.quizDone = false,
    this.completed = false,
  });

  factory OnboardingAnswers.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T? Function(String) p) => [
      for (final v in (j[k] as List<dynamic>? ?? const [])) ?p(v.toString()),
    ];
    return OnboardingAnswers(
      language: j['language'] as String?,
      whatHappened: WhatHappened.parse(j['what_happened'] as String?),
      yourName: j['your_name'] as String?,
      exName: j['ex_name'] as String?,
      endedWhen: EndedWhen.parse(j['ended_when'] as String?),
      length: RelationshipLength.parse(j['relationship_length'] as String?),
      contact: ContactLevel.parse(j['contact'] as String?),
      hardestTimes: list('hardest_times', HardestTime.parse),
      mood: (j['mood'] as num?)?.toInt(),
      feelings: list('feelings', Feeling.parse),
      attachmentAnswers: [
        for (final a in (j['attachment_answers'] as List<dynamic>? ?? const []))
          (a as num).toInt(),
      ],
      goals: list('goals', Goal.parse),
      checkinHour: (j['checkin_hour'] as num?)?.toInt(),
      quizDone: j['completed_at'] != null,
    );
  }

  /// 'en' | 'tr'.
  final String? language;
  final WhatHappened? whatHappened;

  /// The user's own first name (optional). Used in headlines (R20).
  final String? yourName;

  /// The ex's name (optional, sensitive). Never sent to analytics.
  final String? exName;
  final EndedWhen? endedWhen;
  final RelationshipLength? length;
  final ContactLevel? contact;
  final List<HardestTime> hardestTimes;

  /// 0 = barely holding on … 10 = okay.
  final int? mood;
  final List<Feeling> feelings;
  final List<int> attachmentAnswers;
  final List<Goal> goals;

  /// Check-in hour chosen in the notification pre-prompt (R9).
  final int? checkinHour;

  /// The quiz is finished (Plan ready can be shown).
  final bool quizDone;

  /// The onboarding paywall was passed (bought or closed) → Home.
  final bool completed;

  AttachmentStyle? get attachmentStyle =>
      AttachmentQuiz.score(attachmentAnswers);

  /// The plan's focus = the first chosen goal.
  Goal? get focus => goals.isEmpty ? null : goals.first;

  /// First hardest time (drives check-in time and Plan ready support row).
  HardestTime? get hardest => hardestTimes.isEmpty ? null : hardestTimes.first;

  int get suggestedCheckinHour => checkinHour ?? hardest?.suggestedHour ?? 22;

  String? get name {
    final n = yourName?.trim();
    return (n == null || n.isEmpty) ? null : n;
  }

  Map<String, dynamic> toJson() => {
    'language': language ?? 'en',
    'what_happened': whatHappened?.wire,
    'your_name': name,
    'ex_name': (exName?.trim().isEmpty ?? true) ? null : exName!.trim(),
    'ended_when': endedWhen?.wire,
    'relationship_length': length?.wire,
    'contact': contact?.wire,
    'hardest_times': [for (final h in hardestTimes) h.name],
    'mood': mood,
    'feelings': [for (final f in feelings) f.name],
    'attachment_answers': attachmentAnswers,
    'attachment_style': attachmentStyle?.name,
    'goals': [for (final g in goals) g.name],
    'checkin_hour': checkinHour,
  };

  OnboardingAnswers copyWith({
    String? language,
    WhatHappened? whatHappened,
    String? yourName,
    String? exName,
    EndedWhen? endedWhen,
    RelationshipLength? length,
    ContactLevel? contact,
    List<HardestTime>? hardestTimes,
    int? mood,
    List<Feeling>? feelings,
    List<int>? attachmentAnswers,
    List<Goal>? goals,
    int? checkinHour,
    bool? quizDone,
    bool? completed,
  }) => OnboardingAnswers(
    language: language ?? this.language,
    whatHappened: whatHappened ?? this.whatHappened,
    yourName: yourName ?? this.yourName,
    exName: exName ?? this.exName,
    endedWhen: endedWhen ?? this.endedWhen,
    length: length ?? this.length,
    contact: contact ?? this.contact,
    hardestTimes: hardestTimes ?? this.hardestTimes,
    mood: mood ?? this.mood,
    feelings: feelings ?? this.feelings,
    attachmentAnswers: attachmentAnswers ?? this.attachmentAnswers,
    goals: goals ?? this.goals,
    checkinHour: checkinHour ?? this.checkinHour,
    quizDone: quizDone ?? this.quizDone,
    completed: completed ?? this.completed,
  );
}
