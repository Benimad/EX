import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/app_overlay.dart';
import 'core/design/design.dart';
import 'core/router/app_router.dart';
import 'features/lifecycle/application/lifecycle_coordinator.dart';
import 'features/onboarding/application/onboarding_controller.dart';
import 'l10n/app_localizations.dart';

class MyExApp extends ConsumerWidget {
  const MyExApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: MyExTheme.light(),
      routerConfig: ref.watch(appRouterProvider),
      locale: ref.watch(appLocaleProvider),
      builder: (context, child) {
        final body = child ?? const SizedBox.shrink();
        final overlay = ref.watch(appOverlayProvider);
        return LifecycleCoordinator(
          child: overlay == null ? body : overlay(context, body),
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

/// Shown when startup (Supabase / anonymous auth) fails, with retry.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MyExTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l = AppLocalizations.of(context);
          return _MessageScaffold(
            title: l.appTitle,
            body: l.startupError,
            action: PrimaryButton(label: l.commonRetry, onPressed: onRetry),
          );
        },
      ),
    );
  }
}

class _MessageScaffold extends StatelessWidget {
  const _MessageScaffold({
    required this.title,
    required this.body,
    this.action,
  });
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: kScreenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: MyExType.title2,
                  textAlign: TextAlign.center,
                ),
                const Gap(MyExSpacing.s2),
                Text(
                  body,
                  style: MyExType.subheadline,
                  textAlign: TextAlign.center,
                ),
                if (action != null) ...[const Gap(MyExSpacing.s6), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
