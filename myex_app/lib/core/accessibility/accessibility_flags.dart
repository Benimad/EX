import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// iOS "Reduce Transparency" flag.
///
/// Flutter's MediaQuery does not expose this (MediaQuery has
/// `highContrast`/`disableAnimations`, not reduce transparency), so it comes
/// from a MethodChannel implemented in ios/Runner/AppDelegate.swift.
/// On other platforms (and in tests) it stays `false`.
class ReduceTransparencyNotifier extends Notifier<bool> {
  static const channel = MethodChannel('myex/accessibility');

  @override
  bool build() {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'reduceTransparencyChanged' &&
          call.arguments is bool) {
        state = call.arguments as bool;
      }
    });
    ref.onDispose(() => channel.setMethodCallHandler(null));
    _load();
    return false;
  }

  Future<void> _load() async {
    try {
      final v = await channel.invokeMethod<bool>('reduceTransparency');
      if (ref.mounted && v != null) state = v;
    } on MissingPluginException {
      // Not iOS, or running in tests.
    } on PlatformException {
      // Keep the default.
    }
  }

  /// Test/preview override.
  // ignore: use_setters_to_change_properties
  void debugSet(bool value) => state = value;
}

final reduceTransparencyProvider =
    NotifierProvider<ReduceTransparencyNotifier, bool>(
      ReduceTransparencyNotifier.new,
    );
