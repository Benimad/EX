import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

extension ContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// intl locale string for the current UI locale (e.g. "tr", "en").
  String get localeName => l10n.localeName;

  /// Short date, e.g. "Nov 24" / "24 Kas".
  String shortDate(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year
        ? DateFormat.MMMd(localeName).format(d)
        : DateFormat.yMMMd(localeName).format(d);
  }

  /// Time of day, e.g. "9:00 AM" / "09:00".
  String timeOfDay(DateTime d) => DateFormat.jm(localeName).format(d);
}

/// External links.
abstract final class Links {
  static const appleManageSubscriptions =
      'https://apps.apple.com/account/subscriptions';

  /// Terms / Privacy: in-app Safari (SFSafariViewController on iOS).
  static Future<void> openInApp(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || url.isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  /// App Store subscription management (external app).
  static Future<void> openManageSubscriptions(String? managementUrl) async {
    final uri = Uri.parse(
      (managementUrl == null || managementUrl.isEmpty)
          ? appleManageSubscriptions
          : managementUrl,
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// The app's own page in Settings (iOS "app-settings:"). Android has no URL
  /// for it via url_launcher, so the button is hidden there.
  static bool get canOpenAppSettings =>
      defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> openAppSettings() async {
    await launchUrl(Uri.parse('app-settings:'));
  }

  static Future<void> call(String number) async {
    final digits = number.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: digits));
  }
}
