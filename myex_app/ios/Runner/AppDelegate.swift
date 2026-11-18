import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var accessibilityChannel: FlutterMethodChannel?
  private var reduceTransparencyObserver: NSObjectProtocol?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications: show/route notifications (trial reminder,
    // nightly check-in). UNTESTED on device.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAccessibilityChannel(engineBridge.pluginRegistry)
  }

  /// "myex/accessibility": exposes UIAccessibility.isReduceTransparencyEnabled,
  /// which Flutter's MediaQuery does not provide. Read by
  /// lib/core/accessibility/accessibility_flags.dart.
  /// UNTESTED (written on Windows): verify on a device with
  /// Settings › Accessibility › Display & Text Size › Reduce Transparency.
  private func registerAccessibilityChannel(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "MyExAccessibility") else { return }
    let channel = FlutterMethodChannel(
      name: "myex/accessibility",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "reduceTransparency" {
        result(UIAccessibility.isReduceTransparencyEnabled)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    reduceTransparencyObserver = NotificationCenter.default.addObserver(
      forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak channel] _ in
      channel?.invokeMethod(
        "reduceTransparencyChanged",
        arguments: UIAccessibility.isReduceTransparencyEnabled
      )
    }
    accessibilityChannel = channel
  }
}
