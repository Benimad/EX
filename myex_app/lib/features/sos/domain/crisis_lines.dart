import '../../../core/config/env.dart';

/// Crisis lines per locale. Values come from --dart-define so they can be
/// corrected without code changes. VERIFY every number with official sources
/// before release (M0).
class CrisisLines {
  const CrisisLines({required this.emergency, this.helpline});

  factory CrisisLines.forLanguage(String languageCode) => languageCode == 'tr'
      ? CrisisLines(
          emergency: Env.emergencyTr,
          helpline: Env.helplineTr.isEmpty ? null : Env.helplineTr,
        )
      : CrisisLines(
          emergency: Env.emergencyUs,
          helpline: Env.helplineUs.isEmpty ? null : Env.helplineUs,
        );

  final String emergency;
  final String? helpline;
}
