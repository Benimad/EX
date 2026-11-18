import '../../../l10n/app_localizations.dart';
import '../domain/onboarding_answers.dart';

/// Localized labels for onboarding enums.
extension OnboardingLabels on AppLocalizations {
  String whatHappenedLabel(WhatHappened v) => switch (v) {
    WhatHappened.theyEnded => whatTheyEnded,
    WhatHappened.iEnded => whatIEnded,
    WhatHappened.mutual => whatMutual,
    WhatHappened.complicated || WhatHappened.onOff => whatComplicated,
  };

  String endedWhenLabel(EndedWhen v) => switch (v) {
    EndedWhen.thisWeek => whenThisWeek,
    EndedWhen.weeks => whenWeeks,
    EndedWhen.months => whenMonths,
    EndedWhen.longer => whenLonger,
  };

  String lengthLabel(RelationshipLength v) => switch (v) {
    RelationshipLength.lt6m => lenLt6m,
    RelationshipLength.m6to12 => len6to12m,
    RelationshipLength.y1to3 => len1to3y,
    RelationshipLength.gt3y => lenGt3y,
  };

  String contactLabel(ContactLevel v) => switch (v) {
    ContactLevel.none => contactNone,
    ContactLevel.sometimes => contactSometimes,
    ContactLevel.mostDays => contactMostDays,
    ContactLevel.shared => contactShared,
  };

  String hardestLabel(HardestTime v) => switch (v) {
    HardestTime.lateNight => hardLateNight,
    HardestTime.mornings => hardMornings,
    HardestTime.weekends => hardWeekends,
    HardestTime.theirPosts => hardPosts,
  };

  String feelingLabel(Feeling v) => switch (v) {
    Feeling.sad => feelSad,
    Feeling.lonely => feelLonely,
    Feeling.anxious => feelAnxious,
    Feeling.angry => feelAngry,
    Feeling.numb => feelNumb,
    Feeling.confused => feelConfused,
    Feeling.relieved => feelRelieved,
  };

  String goalLabel(Goal v) => switch (v) {
    Goal.stopChecking => goalStopChecking,
    Goal.noContact => goalNoContact,
    Goal.calm => goalCalm,
    Goal.understand => goalUnderstand,
    Goal.selfWorth => goalSelfWorth,
  };

  String focusLabel(Goal v) => switch (v) {
    Goal.stopChecking => focusStopChecking,
    Goal.noContact => focusNoContact,
    Goal.calm => focusCalm,
    Goal.understand => focusUnderstand,
    Goal.selfWorth => focusSelfWorth,
  };

  String attachmentLabel(AttachmentStyle v) => switch (v) {
    AttachmentStyle.secure => attachSecure,
    AttachmentStyle.anxious => attachAnxious,
    AttachmentStyle.avoidant => attachAvoidant,
    AttachmentStyle.fearful => attachFearful,
  };

  String trackLabel(ContactLevel? c) =>
      (c?.lowContactTrack ?? false) ? planTrackLowContact : planTrackNoContact;

  List<String> get attachmentQuestions => [attachQ0, attachQ1, attachQ2];
}
